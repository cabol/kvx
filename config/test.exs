use Mix.Config

# KVX config
config :kvx,
  ttl: 1,
  buckets: [
    mybucket: [
      n_shards: 2
    ]
  ]
