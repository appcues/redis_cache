defmodule Appcues.RedisCache do
  @moduledoc ~S"""
  Example usage:

      # config/config.exs
      config :appcues_redis_cache, MyApp.RedisCache,
        redis_url: "redis://:my_password@my_hostname:6379/my_database", # required
        pool_size: 50,
        pool_max_overflow: 200,
        default_ttl: 5 * 60_000 # 5 minutes

      # lib/my_app/redis_cache.ex
      defmodule MyApp.RedisCache do
        use Appcues.RedisCache
      end

      # lib/my_app.ex
      defmodule MyApp do
        use Application

        def start(_type, _args) do
          # ...
          children = [
            worker(MyApp.RedisCache, []),
            # ...
          ]
          opts = [strategy: :one_for_one, name: Api.Supervisor]
          Supervisor.start_link(children, opts)
        end
      end


      # Usage example
      opts = [ttl: 60_000] # one minute

      {:ok, my_val} = MyApp.RedisCache.get_or_store "my_val_cache_key", opts, fn ->
        compute_val()
      end

      {:ok, my_val} = MyApp.RedisCache.get("my_val_cache_key")

      :ok = MyApp.RedisCache.put("my_val_cache_key", opts)
  """

  defmacro __using__(_args) do
    quote do
      use Appcues.RedisCache.Using
    end
  end

  use Appcues.RedisCache.Using


  defp config(module) do
    Application.get_env(:appcues_redis_cache, module) || []
  end

  defp config(module, key) do
    config(module)[key]
  end

  @doc false
  def start_with_module_and_pool(_type, _args, module, pool_name) do
    import Supervisor.Spec, warn: false

    poolboy_config = [
      name: {:local, pool_name},
      worker_module: Appcues.RedisCache.Worker,
      size: config(module, :pool_size) || 20,
      max_overflow: config(module, :pool_max_overflow) || 50,
    ]

    worker_config = [
      pool_name: pool_name,
      default_ttl: config(module, :default_ttl) || 60_000,
      redis_url: config(module, :redis_url) ||
        raise "missing `:redis_url` config.  Add it with `config :appcues_redis_cache, #{module}, redis_url: \"redis://:my_password@my_hostname:6379/my_database\"`"
    ]

    children = [
       :poolboy.child_spec(pool_name, poolboy_config, worker_config)
    ]

    opts = [strategy: :one_for_one, name: Api.RedisCache.Supervisor]
    Supervisor.start_link(children, opts)
  end


  @type json_encodable ::
    nil |
    number |
    String.t |
    %{String.t => json_encodable} |
    [json_encodable]

  @doc false
  @spec get_with_pool(json_encodable, Keyword.t, atom) ::
    {:ok, json_encodable} | {:error, any}
  def get_with_pool(key, opts, pool_name) do
    with {:ok, key_string} <- Poison.encode(key)
    do
      :poolboy.transaction pool_name, fn (worker_pid) ->
        case :gen_server.call(worker_pid, {:get, key_string, opts}) do
          {:ok, nil} ->
            {:ok, nil}
          {:ok, value_string} ->
            Poison.decode(value_string)
          {:error, e} ->
            {:error, e}
        end
      end
    end
  end

  @doc false
  @spec set_with_pool(json_encodable, json_encodable, Keyword.t, atom) ::
    :ok | {:error, any}
  def set_with_pool(key, value, opts, pool_name) do
    with {:ok, key_string} <- Poison.encode(key),
         {:ok, value_string} <- Poison.encode(value)
    do
      :poolboy.transaction pool_name, fn (worker_pid) ->
        :gen_server.call(worker_pid, {:set, key_string, value_string, opts})
      end
    end
  end

  @spec get_or_store_with_pool(json_encodable, (() -> json_encodable), Keyword.t, atom) ::
    {:ok, json_encodable} | {:error, any}
  def get_or_store_with_pool(key, fun, opts, pool_name) do
    with {:ok, val} <- get_with_pool(key, opts, pool_name)
    do
      case val do
        nil ->
          new_val = fun.()
          case set_with_pool(key, new_val, opts, pool_name) do
            :ok -> {:ok, new_val}
            {:error, e} -> {:error, e}
          end
        val ->
          {:ok, val}
      end
    end
  end

end

