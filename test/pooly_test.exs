defmodule PoolyTest do
  use ExUnit.Case

  setup_all do
    pool_name = "Pool1Test"

    pool_config = [
      name: pool_name,
      mfa: {SampleWorker, []},
      size: 3,
      max_overflow: 1
    ]

    start_supervised!(%{
      id: Pooly.PoolSupervisor,
      start: {Pooly.PoolSupervisor, :start_link, [pool_config]}
    })

    %{pool_name: pool_name}
  end

  test "status when initialized", %{pool_name: pool_name} do
    assert Pooly.status(pool_name) == {3, 0}
  end

  test "status change one worker is checked out and in", %{
    pool_name: pool_name
  } do
    pid = Pooly.checkout(pool_name)
    assert is_pid(pid)
    assert Pooly.status(pool_name) == {2, 1}
    Pooly.checkin(pool_name, pid)
    assert Pooly.status(pool_name) == {3, 0}
  end

  test "when an overflow happens", %{pool_name: pool_name} do
    1..3 |> Enum.each(fn _ -> Pooly.checkout(pool_name) end)
    assert Pooly.status(pool_name) == {0, 3}
    pid = Pooly.checkout(pool_name)
    assert is_pid(pid)
    assert Pooly.status(pool_name) == {0, 4}
    assert Pooly.checkout(pool_name) == :noproc
    Pooly.checkin(pool_name, pid)
    assert Pooly.status(pool_name) == {0, 3}
    assert Process.alive?(pid) == false
  end
end
