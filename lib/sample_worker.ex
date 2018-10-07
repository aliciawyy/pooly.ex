defmodule SampleWorker do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], [])
  end

  @impl true
  def init(_) do
    {:ok, %{}}
  end

  def stop(pid) do
    GenServer.call(pid, :stop)
  end

  @impl true
  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end
end
