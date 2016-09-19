defmodule Appcues.RedisCache.Utils do
  defp config(module) do
    Application.get_env(:appcues_redis_cache, module) || []
  end

  defp config(module, key) do
    config(module)[key]
  end

  @doc ~S"""
  Returns a `:poolboy.child_spec/3` for the given module and pool name.
  """
  def poolboy_child_spec(module, pool_name) do
    poolboy_config = [
      name: {:local, pool_name},
      worker_module: Appcues.RedisCache.Worker,
      size: config(module, :pool_size) || 20,
      max_overflow: config(module, :pool_max_overflow) || 50,
    ]

    worker_config = [
      pool_name: pool_name,
      disabled: config(module, :disabled) || false,
      default_ttl: config(module, :default_ttl) || 60_000,
      redis_url: config(module, :redis_url) ||
        raise "missing `:redis_url` config.  Add it with `config :appcues_redis_cache, #{module}, redis_url: \"redis://:my_password@my_hostname:6379/my_database\"`"
    ]

    :poolboy.child_spec(pool_name, poolboy_config, worker_config)
  end
end

