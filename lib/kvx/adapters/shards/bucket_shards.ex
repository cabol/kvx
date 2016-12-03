defmodule KVX.Bucket.Shards do
  @moduledoc """
  Shards adapter. This is the default adapter supported by `KVX`.
  Shards adapter only works with `set` and `ordered_set` table types.

  Shards extra config options:

    * `:shards_mod` - internal Shards module to use. By default, `:shards`
       module is used, which is a wrapper on top of `:shards_local` and
       `:shards_dist`.
    * `:buckets` - this can be used to set bucket options in config,
      so it can be loaded when the bucket is created. See example below.

  Run-time options when calling `new/2` function, are the same as
  `shards:new/2`. For example:

      MyModule.new(:mybucket, [n_shards: 4])

  ## Example:

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

  For more information about `shards`:

    * [GitHub](https://github.com/cabol/shards)
    * [Blog Post](http://cabol.github.io/posts/2016/04/14/sharding-support-for-ets.html)
  """

  @behaviour KVX.Bucket

  @shards (Application.get_env(:kvx, :shards_mod, :shards))
  @default_ttl (Application.get_env(:kvx, :ttl, :infinity))

  require Ex2ms

  ## Setup Commands

  def new(bucket, opts \\ []) when is_atom(bucket) do
    case Process.whereis(bucket) do
      nil -> new_bucket(bucket, opts)
      _   -> bucket
    end
  end

  defp new_bucket(bucket, opts) do
    opts = maybe_get_bucket_opts(bucket, opts)
    @shards.new(bucket, opts)
  end

  defp maybe_get_bucket_opts(bucket, []) do
    :kvx
    |> Application.get_env(:buckets, [])
    |> Keyword.get(bucket, [])
  end
  defp maybe_get_bucket_opts(_, opts), do: opts

  ## Storage Commands

  def add(bucket, key, value, ttl \\ @default_ttl) do
    case get(bucket, key) do
      nil -> set(bucket, key, value, ttl)
      _   -> raise KVX.ConflictError, key: key, value: value
    end
  end

  def set(bucket, key, value, ttl \\ @default_ttl) do
    true = @shards.insert(bucket, {key, value, seconds_since_epoch(ttl)})
    bucket
  end

  def mset(bucket, entries, ttl \\ @default_ttl) when is_list(entries) do
    entries |> Enum.each(fn({key, value}) ->
      ^bucket = set(bucket, key, value, ttl)
    end)
    bucket
  end

  ## Retrieval Commands

  def get(bucket, key) do
    case @shards.lookup(bucket, key) do
      [{^key, value, ttl}] ->
        if ttl > seconds_since_epoch(0) do
          value
        else
          true = @shards.delete(bucket, key)
          nil
        end
      _ ->
        nil
    end
  end

  def mget(bucket, keys) when is_list(keys) do
    for key <- keys do
      get(bucket, key)
    end
  end

  def find_all(bucket, query \\ nil) do
    do_find_all(bucket, query)
  end

  defp do_find_all(bucket, nil) do
    do_find_all(bucket, Ex2ms.fun do object -> object end)
  end
  defp do_find_all(bucket, query) do
    bucket
    |> @shards.select(query)
    |> Enum.reduce([], fn({k, v, ttl}, acc) ->
      case ttl > seconds_since_epoch(0) do
        true ->
          [{k, v} | acc]
        _ ->
          true = @shards.delete(bucket, k)
          acc
      end
    end)
  end

  ## Cleanup functions

  def delete(bucket, key) do
    true = @shards.delete(bucket, key)
    bucket
  end

  def delete(bucket) do
    true = @shards.delete(bucket)
    bucket
  end

  def flush(bucket) do
    true = @shards.delete_all_objects(bucket)
    bucket
  end

  ## Extended functions

  def __shards_mod__, do: @shards

  def __default_ttl__, do: @default_ttl

  ## Private functions

  defp seconds_since_epoch(diff) when is_integer(diff) do
    {mega, secs, _} = :os.timestamp()
    mega * 1000000 + secs + diff
  end
  defp seconds_since_epoch(:infinity), do: :infinity
  defp seconds_since_epoch(diff), do: raise ArgumentError, "ttl #{inspect diff} is invalid."
end
