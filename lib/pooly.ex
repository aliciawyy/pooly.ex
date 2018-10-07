defmodule Pooly do
  @moduledoc """
  Documentation for Pooly.
  """
  use Application

  def start(_type, _args) do
    worker_spec = {SampleWorker, []}

    pools_config = [
      [name: "Pool1", mfa: worker_spec, size: 2, max_overflow: 2],
      [name: "Pool2", mfa: worker_spec, size: 3, max_overflow: 2],
      [name: "Pool3", mfa: worker_spec, size: 4, max_overflow: 2]
    ]

    start_pools(pools_config)
  end

  @doc """
  Call the Top-level supervisor to start one or multiple pools
  """
  def start_pools(pools_config) do
    Pooly.Supervisor.start_link(pools_config)
  end

  @doc """
  Request and getting a worker from the pool

  :noproc is returned when no more worker available
  """
  def checkout(pool_name) do
    Pooly.Server.checkout(pool_name)
  end

  @doc """
  Once the consumer process is done with the worker, the process must
  return it to the pool with checkin
  """
  def checkin(pool_name, worker_pid) do
    Pooly.Server.checkin(pool_name, worker_pid)
  end

  @doc """
  {Number of free workers, number of busy workers}
  """
  def status(pool_name) do
    Pooly.Server.status(pool_name)
  end
end
