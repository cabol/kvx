use Mix.Config

# KVX config
config :kvx,
  adapter: KVX.Bucket.Shards,
  ttl: 1,
  buckets: [
    mybucket: [
      n_shards: 2
    ]
  ]
