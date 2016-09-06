use Mix.Config

# KVX config
config :kvx,
  adapter: KVX.Bucket.Shards,
  ttl: 300
