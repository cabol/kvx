defmodule KVX.Mixfile do
  use Mix.Project

  def project do
    [app: :kvx,
     version: "0.1.3",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: ["coveralls": :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test],
     package: package(),
     description: """
     Simple Elixir in-memory Key/Value Store using `cabol/ex_shards`.
     """]
  end

  def application do
    [applications: [:logger, :shards]]
  end

  defp deps do
    [{:ex_shards, "~> 0.2"},
     {:ex2ms, "~> 1.4"},
     {:ex_doc, ">= 0.0.0", only: :dev},
     {:excoveralls, "~> 0.5.6", only: :test}]
  end

  defp package do
    [name: :kvx,
     maintainers: ["Carlos A Bolanos"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/cabol/kvx"}]
  end
end
