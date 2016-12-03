defmodule KVX.Bucket do
  @moduledoc """
  Defines a Bucket.

  A bucket maps to an underlying data store, controlled by the
  adapter. For example, `KVX` ships with a `KVX.Bucket.Shards`
  adapter that stores data into a `shards` distributed memory
  storage – [shards](https://github.com/cabol/shards).

  For example, the bucket:

      defmodule MyModule do
        use use KVX.Bucket
      end

  Could be configured with:

      config :kvx,
        adapter: KVX.Bucket.Shards,
        ttl: 10

  Most of the configuration that goes into the `config` is specific
  to the adapter, so check `KVX.Bucket.Shards` documentation for more
  information. However, some configuration is shared across
  all adapters, they are:

    * `:ttl` - The time in seconds to wait until the `key` expires.
      Value `:infinity` will wait indefinitely (default: 3600)

  Check adapters documentation for more information.
  """

  use Behaviour

  @type bucket :: atom
  @type key    :: term
  @type value  :: term
  @type ttl    :: integer | :infinity

  @doc false
  defmacro __using__(_opts) do
    quote do
      @behaviour KVX.Bucket

      @adapter (Application.get_env(:kvx, :adapter, KVX.Bucket.Shards))
      @default_ttl (Application.get_env(:kvx, :ttl, :infinity))

      def __adapter__ do
        @adapter
      end

      def __ttl__ do
        @default_ttl
      end

      def new(bucket, opts \\ []) do
        @adapter.new(bucket, opts)
      end

      def add(bucket, key, value, ttl \\ @default_ttl) do
        @adapter.add(bucket, key, value, ttl)
      end

      def set(bucket, key, value, ttl \\ @default_ttl) do
        @adapter.set(bucket, key, value, ttl)
      end

      def mset(bucket, kv_pairs, ttl \\ @default_ttl) when is_list(kv_pairs) do
        @adapter.mset(bucket, kv_pairs, ttl)
      end

      def get(bucket, key) do
        @adapter.get(bucket, key)
      end

      def mget(bucket, keys) when is_list(keys) do
        @adapter.mget(bucket, keys)
      end

      def find_all(bucket, query \\ nil) do
        @adapter.find_all(bucket, query)
      end

      def delete(bucket, key) do
        @adapter.delete(bucket, key)
      end

      def delete(bucket) do
        @adapter.delete(bucket)
      end

      def flush(bucket) do
        @adapter.flush(bucket)
      end
    end
  end

  ## Setup Commands

  @doc """
  Creates a new bucket if it doesn't exist. If the bucket already exist,
  nothing happens – it works as an idempotent operation.

  ## Example

      MyBucket.new(:mybucket)
  """
  defcallback new(bucket, [term]) :: bucket

  ## Storage Commands

  @doc """
  Store this data, only if it does not already exist. If an item already
  exists and an add fails with a `KVX.ConflictError` exception.

  If `bucket` doesn't exist, it will raise an argument error.

  ## Example

      MyBucket.add(:mybucket, "hello", "world")
  """
  defcallback add(bucket, key, value, ttl) :: bucket | KVX.ConflictError

  @doc """
  Most common command. Store this data, possibly overwriting any existing data.

  If `bucket` doesn't exist, it will raise an argument error.

  ## Example

      MyBucket.set(:mybucket, "hello", "world")
  """
  defcallback set(bucket, key, value, ttl) :: bucket

  @doc """
  Store this bulk data, possibly overwriting any existing data.

  If `bucket` doesn't exist, it will raise an argument error.

  ## Example

      MyBucket.mset(:mybucket, [{"a": 1}, {"b", "2"}])
  """
  defcallback mset(bucket, [{key, value}], ttl) :: bucket

  ## Retrieval Commands

  @doc """
  Get the value of `key`. If the key does not exist the special value `nil`
  is returned.

  If `bucket` doesn't exist, it will raise an argument error.

  ## Example

      MyBucket.get(:mybucket, "hello")
  """
  defcallback get(bucket, key) :: value | nil

  @doc """
  Returns the values of all specified keys. For every key that does not hold
  a string value or does not exist, the special value `nil` is returned.
  Because of this, the operation never fails.

  If `bucket` doesn't exist, it will raise an argument error.

  ## Example

      MyBucket.mget(:mybucket, ["hello", "world"])
  """
  defcallback mget(bucket, [key]) :: [value | nil]

  @doc """
  Returns all objects/tuples `{key, value}` that matches with the specified
  `query`. The `query` type/spec depends on each adapter implementation –
  `:ets.match_spec` in case of `KVX.Bucket.Shards`.

  If `bucket` doesn't exist, it will raise an argument error.

  ## Example

      MyBucket.find_all(bucket, Ex2ms.fun do object -> object end)
  """
  defcallback find_all(bucket, query :: term) :: [{key, value}]

  ## Cleanup functions

  @doc """
  Removes an item from the bucket, if it exists.

  If `bucket` doesn't exist, it will raise an argument error.

  ## Example

      MyBucket.delete(:mybucket, "hello")
  """
  defcallback delete(bucket, key) :: bucket

  @doc """
  Deletes an entire bucket, if it exists.

  If `bucket` doesn't exist, it will raise an argument error.

  ## Example

      MyBucket.delete(:mybucket)
  """
  defcallback delete(bucket) :: bucket

  @doc """
  Invalidate all existing cache items.

  If `bucket` doesn't exist, it will raise an argument error.

  ## Example

      MyBucket.flush(:mybucket)
  """
  defcallback flush(bucket) :: bucket
end
