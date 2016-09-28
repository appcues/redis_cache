defmodule Appcues.RedisCache.Utils do
  @moduledoc false

  @doc ~S"""
  Returns the `:appcues_redis_cache` config for the given module,
  or `[]` if it doesn't exist.
  """
  @spec config(atom) :: Keyword.t
  def config(module) do
    Application.get_env(:appcues_redis_cache, module) || []
  end

  @doc ~S"""
  Returns the requested `:appcues_redis_cache` config for the given
  module.
  """
  @spec config(atom, atom) :: any
  def config(module, key) do
    config(module)[key]
  end


  @doc ~S"""
  Returns the pool name for the given module.
  """
  @spec pool_name(atom) :: atom
  def pool_name(module), do: Module.concat(module, Pool)


  @doc ~S"""
  Returns a `:poolboy.child_spec/3` for the given module.
  """
  def poolboy_child_spec(module) do
    pool_name = pool_name(module)

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

