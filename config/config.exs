# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# KVX config
config :kvx,
  adapter: KVX.Bucket.Shards

# Import environment specific config.
import_config "#{Mix.env}.exs"
