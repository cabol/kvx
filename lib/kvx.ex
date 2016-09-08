defmodule KVX do
  @moduledoc """
  This is a simple/basic in-memory Key/Value Store written in
  [**Elixir**](http://elixir-lang.org/) and using
  [**Shards**](https://github.com/cabol/shards)
  as default adapter.

  Again, **KVX** is a simple library, most of the work
  is done by **Shards**, and its typical use case might
  be as a **Cache**.

  ## Adapters

  **KVX** was designed to be flexible and support multiple
  backends. We currently ship with one backend:

    * `KVX.Bucket.Shards` - uses [Shards](https://github.com/cabol/shards),
      to implement the `KVX.Bucket` interface.

  **KVX** adapters config might looks like:

      config :kvx,
        adapter: KVX.Bucket.Shards,
        ttl: 43200,
        shards_mod: :shards,
        buckets: [
          mybucket1: [
            n_shards: 4
          ],
          mybucket2: [
            n_shards: 8
          ]
        ]

  In case of Shards adapter, run-time options when calling `new/2`
  function, are the same as `shards:new/2`. E.g.:

      MyModule.new(:mybucket, [n_shards: 4])

  ## Example

  Check the example [**HERE**](https://github.com/cabol/kvx#example).
  """
end
