defmodule KVX.Bucket.ShardsTest do
  use ExUnit.Case
  use KVX.Bucket

  doctest KVX

  @bucket __MODULE__

  require Ex2ms

  setup do
    @bucket = @bucket
    |> new([n_shards: 4])
    |> flush

    on_exit fn ->
      assert_raise ArgumentError, fn ->
        @bucket
        |> delete
        |> find_all
      end
    end
    :ok
  end

  test "default config" do
    assert KVX.Bucket.Shards === __adapter__
    assert 1 === __ttl__
  end

  test "invalid bucket error" do
    assert_raise ArgumentError, fn ->
      set(:invalid, :k1, 1)
    end

    assert_raise ArgumentError, fn ->
      get(:invalid, :k1)
    end

    assert_raise ArgumentError, fn ->
      delete(:invalid, :k1)
    end
  end

  test "flush bucket" do
    @bucket
    |> new
    |> flush
    |> mset([k1: 1, k2: 2, k3: 3, k4: 4, k1: 1])

    assert [k1: 1, k2: 2, k3: 3, k4: 4] === find_all(@bucket) |> Enum.sort

    rs = @bucket
    |> flush
    |> find_all
    |> Enum.sort

    assert [] === rs
  end

  test "storage and retrieval commands test" do
    @bucket
    |> mset([k1: 1, k2: 2, k3: 3, k4: 4, k1: 1])

    assert 1 === get(@bucket, :k1)
    assert [1, 2] === mget(@bucket, [:k1, :k2])
    assert nil === get(@bucket, :k11)

    assert_raise KVX.ConflictError, fn ->
      add(@bucket, :k1, 11)
    end
    add(@bucket, :kx, 123)
    assert 123 === get(@bucket, :kx)

    assert [k1: 1, k2: 2, k3: 3, k4: 4, kx: 123] === find_all(@bucket) |> Enum.sort

    ms1 = Ex2ms.fun do {_, v, _} = obj when rem(v, 2) == 0 -> obj end
    assert [k2: 2, k4: 4] === find_all(@bucket, ms1) |> Enum.sort

    nil = @bucket
    |> delete(:k1)
    |> get(:k1)
  end

  test "ttl test" do
    @bucket
    |> mset([k1: 1, k2: 2, k3: 3], 2)
    |> set(:k4, 4, 3)
    |> set(:k5, 5, :infinity)

    assert [k1: 1, k2: 2, k3: 3, k4: 4, k5: 5] === find_all(@bucket) |> Enum.sort

    :timer.sleep(2000)
    assert [k4: 4, k5: 5] === find_all(@bucket) |> Enum.sort

    :timer.sleep(1000)
    assert nil === get(@bucket, :k4)
    assert [k5: 5] === find_all(@bucket) |> Enum.sort
    assert 5 === get(@bucket, :k5)
  end

  test "cleanup commands test" do
    @bucket
    |> mset([k1: 1, k2: 2, k3: 3])

    assert [k1: 1, k2: 2, k3: 3] === find_all(@bucket) |> Enum.sort

    nil = @bucket
    |> delete(:k1)
    |> get(:k1)

    assert [k2: 2, k3: 3] === find_all(@bucket) |> Enum.sort
  end

  test "load bucket opts from config test" do
    assert :mybucket === new(:mybucket)
    assert 2 === :shards_state.n_shards(:mybucket)
    assert :shards === KVX.Bucket.Shards.__shards_mod__
  end
end
