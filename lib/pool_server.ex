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

  def start_link(sup, pool_config) do
    opts = [name: name(pool_config[:name])]

    GenServer.start_link(__MODULE__, [sup, pool_config], opts)
  end

  # sup is the pid to the top-level supervisor
  @impl true
  def init([sup, pool_config]) when is_pid(sup) do
    Process.flag(:trap_exit, true)
    monitors = :ets.new(:monitors, [:private])
    init(pool_config, %State{sup: sup, monitors: monitors})
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
    # start the worker supervisor process via the top level Supervisor
    {:ok, worker_sup} = Supervisor.start_child(sup, supervisor_spec(pool_name))
    workers = prepopulate(size, worker_sup, mfa)
    {:noreply, %{state | worker_sup: worker_sup, workers: workers}}
  end

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

  def handle_info(
        {:EXIT, pid, _reason},
        state = %State{monitors: monitors, workers: workers, worker_sup: worker_sup, mfa: mfa}
      ) do
    case :ets.lookup(monitors, pid) do
      [{pid, ref}] ->
        true = Process.demonitor(ref)
        true = :ets.delete(monitors, pid)
        new_state = %{state | workers: [new_worker(worker_sup, mfa) | workers]}
        {:noreply, new_state}

      [[]] ->
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

  defp prepopulate(size, sup, mfa) do
    1..size |> Enum.map(fn _ -> new_worker(sup, mfa) end)
  end

  defp new_worker(sup, mfa) do
    {:ok, worker} = DynamicSupervisor.start_child(sup, mfa)
    worker
  end

  def checkout, do: GenServer.call(__MODULE__, :checkout)
  def status, do: GenServer.call(__MODULE__, :status)
  def checkin(worker_pid), do: GenServer.cast(__MODULE__, {:checkin, worker_pid})

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
