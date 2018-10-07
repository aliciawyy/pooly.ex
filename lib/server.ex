defmodule Pooly.Server do
  use GenServer

  def start_link(pools_config) do
    GenServer.start_link(__MODULE__, pools_config, name: __MODULE__)
  end

  @impl true
  def init(pools_config) do
    pools_config
    |> Enum.each(fn pool_config -> send(self(), {:start_pool, pool_config}) end)

    {:ok, pools_config}
  end

  @impl true
  def handle_info({:start_pool, pool_config}, state) do
    {:ok, _} =
      Supervisor.start_child(Pooly.PoolsSupervisor, child_spec(pool_config))

    {:noreply, state}
  end

  defp child_spec(pool_config) do
    %{
      id: Pooly.PoolSupervisor.name(pool_config[:name]),
      start: {Pooly.PoolSupervisor, :start_link, [pool_config]},
      type: :supervisor
    }
  end

  def checkout(pool_name) do
    GenServer.call(Pooly.PoolServer.name(pool_name), :checkout)
  end

  def checkin(pool_name, worker) do
    GenServer.cast(Pooly.PoolServer.name(pool_name), {:checkin, worker})
  end

  def status(pool_name) do
    GenServer.call(Pooly.PoolServer.name(pool_name), :status)
  end
end
