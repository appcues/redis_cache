defmodule Api.RedisCache.Mixfile do
  use Mix.Project

  def project do
    [app: :appcues_redis_cache,
     version: "0.1.0",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger],
     mod: {Appcues.RedisCache, [:poison, :poolboy, :redix]}]
  end

  defp deps do
    [
      {:poison, "~> 1.0"},
      {:poolboy, "~> 1.5.1"},
      {:redix, "~> 0.4.0"},
      {:ex_spec, "~> 2.0", only: :test},
    ]
  end
end

