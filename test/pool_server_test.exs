defmodule Pooly.PoolServerTest do
  use ExUnit.Case, async: true

  setup_all do
    pool_config = [name: "PoolTest1", mfa: {SampleWorker, []}, size: 3]
    {:ok, pool_sup} = Pooly.PoolSupervisor.start_link(pool_config)
    %{pool_config: pool_config, pool_sup: pool_sup}
  end

  test "status when initialized", %{pool_config: pool_config} do
    server_name = Pooly.PoolServer.name(pool_config[:name])
    assert GenServer.call(server_name, :status) == {3, 0}
  end
end
