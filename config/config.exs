# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

if Mix.env == :test do
  config :appcues_redis_cache, Appcues.TestRedisCache,
    redis_url: "redis://localhost:6379/",
    default_ttl: 1_000

  config :appcues_redis_cache, Appcues.TestRedisCache2,
    redis_url: "redis://localhost:6379/2",
    default_ttl: 1_000

  config :appcues_redis_cache, Appcues.DisabledRedisCache,
    redis_url: "redis://asdfasdf:22222/",
    disabled: true
end

