# KVX

This is a simple/basic [Elixir](http://elixir-lang.org/) in-memory Key/Value Store
using [Shards](https://github.com/cabol/shards) – which is the default adapter.

## Usage

Add `kvx` to your Mix dependencies:

```elixir
defp deps do
  [{:kvx, "~> 0.1.0"}]
end
```

In an existing or new module:

```elixir
defmodule MyTestMod do
  use KVX.Bucket
end
```

Now let's play with `kvx`:

```elixir
> MyTestMod.new(:mybucket)
:mybucket

> MyTestMod.set(:mybucket, :k1, 1)
:mybucket

> MyTestMod.mset(:mybucket, k2: 2, k3: "3")
:mybucket

> MyTestMod.get(:mybucket, :k1)
1

> MyTestMod.mget(:mybucket, [:k2, :k3])
[2, "3"]

> MyTestMod.find_all(:mybucket)
[k3: "3", k2: 2, k1: 1]

> MyTestMod.delete(:mybucket, :k1)
:mybucket

> MyTestMod.get(:mybucket, :k1)
nil

> MyTestMod.flush!(:mybucket)
:mybucket

> MyTestMod.find_all(:mybucket)
[]
```

## Configuration

Most of the configuration that goes into the `config` is specific to the adapter.
But there are some common/shared options such as: `:adapter` and `:ttl`. E.g.:

```elixir
config :kvx,
  adapter: KVX.Bucket.Shards,
  ttl: 1
```

Now, in case of Shards adapter `KVX.Bucket.Shards`, it has some extra options
like `:shards_mod`. E.g.:

```elixir
config :kvx,
  adapter: KVX.Bucket.Shards,
  ttl: 1,
  shards_mod: :shards
```

In case of Shards adapter, run-time options when calling `new/2` function, are
the same as `shards:new/2`. E.g.:

```elixir
MyModule.new(:mybucket, [n_shards: 4])
```

 > **NOTE:** For more information check [KVX.Bucket.Shards](./lib/kvx/adapters/shards/bucket_shards.ex).
