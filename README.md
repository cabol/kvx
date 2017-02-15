# KVX

This is a simple/basic in-memory Key/Value Store written in [**Elixir**](http://elixir-lang.org/)
and using [**ExShards**](https://github.com/cabol/ex_shards) as default adapter.

Again, **KVX** is a simple library, most of the work is done by **ExShards**, and
its typical use case might be as a **Cache**.

## Usage

Add `kvx` to your Mix dependencies:

```elixir
defp deps do
  [{:kvx, "~> 0.1"}]
end
```

In an existing or new module:

```elixir
defmodule MyTestMod do
  use KVX.Bucket
end
```

## Getting Started!

Let's try it out, compile your project and start an interactive console:

```
$ mix deps.get
$ mix compile
$ iex -S mix
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
  adapter: KVX.Bucket.ExShards,
  ttl: 1
```

Now, in case of the adapter `KVX.Bucket.ExShards`, it has some extra options
like `module`. E.g.:

```elixir
config :kvx,
  adapter: KVX.Bucket.ExShards,
  ttl: 1,
  module: ExShards.Local
```

Besides, you can define bucket options in the config:

```elixir
config :kvx,
  adapter: KVX.Bucket.ExShards,
  ttl: 43200,
  module: ExShards,
  buckets: [
    mybucket1: [
      n_shards: 4
    ],
    mybucket2: [
      n_shards: 8
    ]
  ]
```

In case of **ExShards** adapter, run-time options when calling `new/2` function, are
the same as `ExShards.new/2`. E.g.:

```elixir
MyModule.new(:mybucket, [n_shards: 4])
```

 > **NOTE:** For more information check [KVX.Bucket.ExShards](./lib/kvx/adapters/ex_shards/bucket_shards.ex).

## Running Tests

```
$ mix test
```

### Coverage

```
$ mix coveralls
```

 > **NOTE:** For more coverage options check [**excoveralls**](https://github.com/parroty/excoveralls).

## Example

As we mentioned before, one of the most typical use case might be
use **KVX** as a **Cache**. Now, let's suppose you're working with
[**Ecto**](https://github.com/elixir-ecto/ecto), and you want to be
able to cache data when you call `Ecto.Repo.get/3`, and on other hand,
be able to handle eviction, remove/update cached data when they
change or mutate – typically when you call `Ecto.Repo.insert/2`,
`Ecto.Repo.update/2`, etc.

To do so, let's implement our own `CacheableRepo` to encapsulate
data access and caching logic. First let's create our bucket and
the `Ecto.Repo` in two separated modules:

```elixir
defmodule MyApp.Bucket do
 use KVX.Bucket
end

defmodule MyApp.Repo do
 use Ecto.Repo, otp_app: :myapp
end
```

Now, let's code our `CacheableRepo`, re-implementing some `Ecto.Repo`
functions but adding caching. It is as simple as this:

```elixir
defmodule MyApp.CacheableRepo do
  alias MyApp.Repo
  alias MyApp.Bucket

  require Logger

  def get(queryable, id, opts \\ []) do
    get(&Repo.get/3, queryable, id, opts)
  end

  def get!(queryable, id, opts \\ []) do
    get(&Repo.get!/3, queryable, id, opts)
  end

  def get_by(queryable, clauses, opts \\ []) do
    get(&Repo.get_by/3, queryable, clauses, opts)
  end

  def get_by!(queryable, clauses, opts \\ []) do
    get(&Repo.get_by!/3, queryable, clauses, opts)
  end

  defp get(fun, queryable, key, opts) do
    b = bucket(queryable)
    case Bucket.get(b, key) do
      nil ->
        value = fun.(queryable, key, opts)
        if value != nil do
          Logger.debug "CACHING <get>: #{inspect key} => #{inspect value}"
          Bucket.set(b, key, value)
        end
        value
      value ->
        Logger.debug "CACHED <get>: #{inspect key} => #{inspect value}"
        value
    end
  end

  def insert(struct, opts \\ []) do
    case Repo.insert(struct, opts) do
      {:ok, schema} = rs ->
        schema
        |> bucket
        |> Bucket.delete(schema.id)
        rs
      error ->
        error
    end
  end

  def insert!(struct, opts \\ []) do
    rs = Repo.insert!(struct, opts)
    rs
    |> bucket
    |> Bucket.delete(rs.id)
    rs
  end

  def update(struct, opts \\ []) do
    case Repo.update(struct, opts) do
      {:ok, schema} = rs ->
        schema
        |> bucket
        |> Bucket.set(schema.id, schema)
        rs
      error ->
        error
    end
  end

  def update!(struct, opts \\ []) do
    rs = Repo.update!(struct, opts)
    rs
    |> bucket
    |> Bucket.set(rs.id, rs)
    rs
  end

  def delete(struct, opts \\ []) do
    case Repo.delete(struct, opts) do
      {:ok, schema} = rs ->
        schema
        |> bucket
        |> Bucket.delete(schema.id)
        rs
      error ->
        error
    end
  end

  def delete!(struct, opts \\ []) do
    rs = Repo.delete!(struct, opts)
    rs
    |> bucket
    |> Bucket.delete(rs.id)
    rs
  end

  # function to resolve what bucket depending on the given schema
  defp bucket(%{__struct__: struct}), do: Bucket.new(struct)
  defp bucket(struct) when is_atom(struct), do: Bucket.new(struct)
  defp bucket(_), do: Bucket.new(:default)
end
```

Now that we have our `CacheableRepo`, it can be used instead of `Ecto.Repo`
(since it is a wrapper on top of it, but it adds caching) for data you
consider can be cached, for example, you can use it from your
**Phoenix Controllers** – in case you're using [Phoenix](http://www.phoenixframework.org/).

## Copyright and License

Copyright (c) 2016 Carlos Andres Bolaños R.A.

**KVX** source code is licensed under the [**MIT License**](LICENSE.md).
