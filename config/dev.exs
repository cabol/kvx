use Mix.Config

# KVX config
config :kvx,
  adapter: KVX.Bucket.ExShards,
  ttl: 300
