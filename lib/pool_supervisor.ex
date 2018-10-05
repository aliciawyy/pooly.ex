defmodule Pooly.PoolSupervisor do
  use Supervisor

  def start_link(pool_config) do
    opts = [name: name(pool_config[:name])]

    Supervisor.start_link(__MODULE__, pool_config, opts)
  end

  def name(pool_name), do: :"#{pool_name}Supervisor"

  @impl true
  def init(pool_config) do
    children = [
      %{
        id: Pooly.PoolServer.name(pool_config[:name]),
        start: {Pooly.PoolServer, :start_link, [self(), pool_config]}
      }
    ]

    opts = [strategy: :one_for_all]

    Supervisor.init(children, opts)
  end
end
