defmodule Pooly.WorkerSupervisor do
  use DynamicSupervisor

  def name(pool_name), do: :"#{pool_name}WorkerSupervisor"

  def start_link(pool_name) do
    DynamicSupervisor.start_link(__MODULE__, [], name: name(pool_name))
  end

  @doc """

  ## Restart Strategy

  A restart strategy indicate how a Supervisor restarts a child
  when it goes wrong. There are four kinds of restart strategies:

  :one_for_one If one process dies, only that process is restarted.
               None of other processes is affected.
  :one_for_all If any process dies, all the processes in the supervision
               tree die along with it. After that, all of them are restarted.
  :rest_for_one The *rest* of the processes are the processes that *started*
                after the process. They will die with the process then
                restarted together.
  :simple_one_for_one For this strategy, every child process spawned from
                      the Supervisor is the same kind of process. (deprecated)

  ## Other options

  max_restarts, max_seconds: max number of restarts the Supervisor can try
  withing the maximum seconds
  """
  @impl true
  def init(_) do
    DynamicSupervisor.init(
      strategy: :one_for_one,
      max_restarts: 5,
      max_seconds: 5
    )
  end
end
