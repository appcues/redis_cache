# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

if Mix.env == :dev do
  config :appcues_redis_cache, Appcues.RedisCache,
    redis_url: "redis://localhost:6379/"
end

if Mix.env == :test do
  config :appcues_redis_cache, Appcues.RedisCache,
    redis_url: "redis://localhost:6379/",
    default_ttl: 1_000
end

