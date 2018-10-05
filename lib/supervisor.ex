defmodule Pooly.Supervisor do
  @moduledoc """
  Top-level supervisor
  """

  use Supervisor

  def start_link(pools_config) do
    Supervisor.start_link(__MODULE__, pools_config, name: __MODULE__)
  end

  def init(pools_config) do
    children = [
      %{
        id: Pooly.PoolsSupervisor,
        start: {Pooly.PoolsSupervisor, :start_link, []},
        type: :supervisor
      },
      %{
        id: Pooly.Server,
        start: {Pooly.Server, :start_link, [pools_config]},
        # default type
        type: :worker
      }
    ]

    opts = [strategy: :one_for_all]

    Supervisor.init(children, opts)
  end
end
