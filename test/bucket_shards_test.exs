defmodule KVX.Bucket.ShardsTest do
  use ExUnit.Case
  use KVX.Bucket

  doctest KVX

  require Ex2ms

  test "default config" do
    assert KVX.Bucket.Shards === __adapter__
    assert 1 === __ttl__
  end

  test "new bucket" do
    rs = :set
    |> new
    |> new
    assert :set === rs
  end

  test "invalid bucket error" do
    assert_raise ArgumentError, fn ->
      set(:invalid, :k1, 1)
    end

    assert_raise ArgumentError, fn ->
      get(:invalid, :k1)
    end
  end

  test "flush bucket" do
    :temp
    |> new
    |> flush!
    |> mset([k1: 1, k2: 2, k3: 3, k4: 4, k1: 1])

    assert [k1: 1, k2: 2, k3: 3, k4: 4] === find_all(:temp) |> Enum.sort

    rs = :temp
    |> flush!
    |> find_all
    |> Enum.sort

    assert [] === rs
  end

  test "storage and retrieval commands test" do
    :set
    |> new([n_shards: 4])
    |> flush!
    |> mset([k1: 1, k2: 2, k3: 3, k4: 4, k1: 1])

    assert 1 === get(:set, :k1)
    assert [1, 2] === mget(:set, [:k1, :k2])
    assert nil === get(:set, :k11)

    assert_raise KVX.ConflictError, fn ->
      add(:set, :k1, 11)
    end
    add(:set, :kx, 123)
    assert 123 === get(:set, :kx)

    assert [k1: 1, k2: 2, k3: 3, k4: 4, kx: 123] === find_all(:set) |> Enum.sort

    ms1 = Ex2ms.fun do {_, v, _} = obj when rem(v, 2) == 0 -> obj end
    assert [k2: 2, k4: 4] === find_all(:set, ms1) |> Enum.sort

    nil = :set
    |> delete(:k1)
    |> get(:k1)
  end

  test "ttl test" do
    :ttl_test
    |> new
    |> flush!
    |> mset([k1: 1, k2: 2, k3: 3], 2)
    |> set(:k4, 4, 3)
    |> set(:k5, 5, :infinity)

    assert [k1: 1, k2: 2, k3: 3, k4: 4, k5: 5] === find_all(:ttl_test) |> Enum.sort

    :timer.sleep(2100)
    assert [k4: 4, k5: 5] === find_all(:ttl_test) |> Enum.sort

    :timer.sleep(1000)
    assert nil === get(:ttl_test, :k4)
    assert [k5: 5] === find_all(:ttl_test) |> Enum.sort
    assert 5 === get(:ttl_test, :k5)
  end
end
