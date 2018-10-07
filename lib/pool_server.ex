defmodule Pooly.PoolServer do
  use GenServer

  defmodule State do
    defstruct sup: nil,
              size: nil,
              mfa: nil,
              worker_sup: nil,
              workers: nil,
              monitors: nil,
              name: nil
  end

  def name(pool_name), do: :"#{pool_name}Server"

  def start_link(pool_sup, pool_config) do
    GenServer.start_link(__MODULE__, [pool_sup, pool_config], name: name(pool_config[:name]))
  end

  @impl true
  def init([pool_sup, pool_config]) when is_pid(pool_sup) do
    Process.flag(:trap_exit, true)
    monitors = :ets.new(:monitors, [:private])
    init(pool_config, %State{sup: pool_sup, monitors: monitors})
  end

  def init([name: pool_name, mfa: mfa, size: size], state) do
    state = %{state | mfa: mfa, size: size, name: pool_name}
    send(self(), :start_worker_supervisor)
    {:ok, state}
  end

  @impl true
  def handle_info(
        :start_worker_supervisor,
        state = %State{sup: sup, size: size, mfa: mfa, name: pool_name}
      ) do
    # start the worker supervisor process via the top level supervisor
    {:ok, worker_sup} = Supervisor.start_child(sup, supervisor_spec(pool_name))
    workers = prepopulate(size, worker_sup, mfa)
    {:noreply, %{state | worker_sup: worker_sup, workers: workers}}
  end

  @doc """
  If the consumer process is down.

  As the consumer process is monitored by the server process, it sends back a
  message like

  {:DOWN, #Reference<0.4158834611.87031811.80203>, :process, #PID<0.260.0>,
  :killed}

  when it exits.

  """
  def handle_info({:DOWN, ref, _, _, _}, state = %State{monitors: monitors, workers: workers}) do
    case :ets.match(monitors, {:"$1", ref}) do
      [[pid]] ->
        :ets.delete(monitors, pid)
        new_state = %{state | workers: [pid | workers]}
        {:noreply, new_state}

      [[]] ->
        {:noreply, state}
    end
  end

  @doc """
  If a worker process exits, we add a new worker back
  """
  def handle_info(
        {:EXIT, pid, _reason},
        state = %State{
          monitors: monitors,
          workers: workers,
          worker_sup: worker_sup,
          mfa: worker_spec
        }
      ) do
    case :ets.lookup(monitors, pid) do
      [{pid, ref}] ->
        true = Process.demonitor(ref)
        true = :ets.delete(monitors, pid)
        # Bug. A worker is already added back with the Supervisor's restart strategy
        new_state = %{state | workers: [new_worker(worker_sup, worker_spec) | workers]}
        {:noreply, new_state}

      [] ->
        # Bug: the restarted process is not linked
        {:noreply, state}
    end
  end

  defp supervisor_spec(pool_name) do
    %{
      id: Pooly.WorkerSupervisor.name(pool_name),
      start: {Pooly.WorkerSupervisor, :start_link, [pool_name]},
      restart: :temporary,
      type: :supervisor
    }
  end

  defp prepopulate(size, sup, worker_spec) do
    1..size |> Enum.map(fn _ -> new_worker(sup, worker_spec) end)
  end

  defp new_worker(sup, worker_spec) do
    {:ok, worker} = DynamicSupervisor.start_child(sup, worker_spec)
    Process.link(worker)
    worker
  end

  @impl true
  def handle_call(:checkout, {from_pid, _ref}, %{workers: workers, monitors: monitors} = state) do
    case workers do
      [worker | rest] ->
        ref = Process.monitor(from_pid)
        true = :ets.insert(monitors, {worker, ref})
        {:reply, worker, %{state | workers: rest}}

      [] ->
        {:reply, :noproc, state}
    end
  end

  def handle_call(:status, {_from_pid, _ref}, %{workers: workers, monitors: monitors} = state) do
    {:reply, {length(workers), :ets.info(monitors, :size)}, state}
  end

  @impl true
  def handle_cast({:checkin, worker_pid}, %{workers: workers, monitors: monitors} = state) do
    case :ets.lookup(monitors, worker_pid) do
      [{pid, ref}] ->
        true = Process.demonitor(ref)
        true = :ets.delete(monitors, pid)
        {:noreply, %{state | workers: [pid | workers]}}

      [] ->
        {:noreply, state}
    end
  end
end
