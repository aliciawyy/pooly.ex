defmodule PoolyTest do
  use ExUnit.Case

  setup_all do
    pool_config = [name: "Pool1Test", mfa: {SampleWorker, []}, size: 3]

    start_supervised!(%{
      id: Pooly.PoolSupervisor,
      start: {Pooly.PoolSupervisor, :start_link, [pool_config]}
    })

    :ok
  end

  test "status when initialized" do
    assert Pooly.status("Pool1Test") == {3, 0}
  end

  test "status change one worker is checked out and in" do
    pool_name = "Pool1Test"
    pid = Pooly.checkout(pool_name)
    assert is_pid(pid)
    assert Pooly.status(pool_name) == {2, 1}
    Pooly.checkin(pool_name, pid)
    assert Pooly.status(pool_name) == {3, 0}
  end
end
