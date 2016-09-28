defmodule Appcues.RedisCache do
  @moduledoc ~S"""
  `Appcues.RedisCache` provides a pool of connections to a Redis instance,
  and implements `get`, `set`, and `get_or_store` in addition to a generic
  `command` interface.

  Example usage:

      # lib/my_app/redis_cache.ex
      defmodule MyApp.RedisCache do
        use Appcues.RedisCache
      end

      # config/config.exs
      config :appcues_redis_cache, MyApp.RedisCache,
        redis_url: "redis://:my_password@my_hostname:6379/my_database", # required
        pool_size: 50,
        pool_max_overflow: 200,
        default_ttl: 5 * 60_000 # 5 minutes

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

      :ok = MyApp.RedisCache.set("my_val_cache_key", "new_value", opts)

      {:ok, _} = MyApp.RedisCache.command(["SET", "x", "y", "PX", "60000"])
  """

  @type json_encodable ::
    nil |
    number |
    String.t |
    %{String.t => json_encodable} |
    [json_encodable]

  defmacro __using__(_args) do
    quote do
      use Supervisor

      @doc false
      def start_link(opts \\ []) do
        Supervisor.start_link(__MODULE__, opts)
      end

      @doc false
      def init(_opts) do
        poolboy_child_spec = Appcues.RedisCache.Utils.poolboy_child_spec(__MODULE__)
        supervise([poolboy_child_spec], strategy: :one_for_one)
      end


      @doc ~S"""
      Gets the specified item from the cache.
      Returns `{:ok, nil}` if not found, `{:ok, value}` if found, or `{:error, e}`.
      """
      @spec get(Appcues.RedisCache.json_encodable, Keyword.t) :: {:ok, Appcues.RedisCache.json_encodable} | {:error, any}
      def get(key, opts \\ []) do
        Appcues.RedisCache.Calls.get(key, opts, __MODULE__)
      end

      @doc ~S"""
      Gets the specified item from the cache.
      Returns `nil` if not found, the value if found, or raises an exception.
      """
      @spec get!(Appcues.RedisCache.json_encodable, Keyword.t) :: Appcues.RedisCache.json_encodable | no_return
      def get!(key, opts \\ []) do
        {:ok, val} = get(key, opts)
        val
      end

      @doc ~S"""
      Sets the value stored under the given key.
      `opts[:ttl]` may be given to specify the time-to-live in milliseconds.
      Returns `:ok` or `{:error, e}`.
      """
      @spec set(Appcues.RedisCache.json_encodable, Appcues.RedisCache.json_encodable, Keyword.t) :: :ok | {:error, any}
      def set(key, value, opts \\ []) do
        Appcues.RedisCache.Calls.set(key, value, opts, __MODULE__)
      end

      @doc ~S"""
      Sets the value stored under the given key.
      `opts[:ttl]` may be given to specify the time-to-live in milliseconds.
      Returns `:ok` or raises exception.
      """
      @spec set(Appcues.RedisCache.json_encodable, Appcues.RedisCache.json_encodable, Keyword.t) :: :ok | no_return
      def set!(key, value, opts \\ []) do
        :ok = set(key, value, opts)
      end


      @doc ~S"""
      Retrieves a value if it exists in the cache.
      Otherwise, executes `fun` and caches the result.
      `opts[:ttl]` may be given to specify the time-to-live in milliseconds.
      Returns `{:ok, value}` or `{:error, e}`.
      """
      @spec get_or_store(Appcues.RedisCache.json_encodable, (() -> Appcues.RedisCache.json_encodable)) :: {:ok,Appcues.RedisCache.json_encodable} | {:error, any}
      def get_or_store(key, fun), do: get_or_store(key, [], fun)

      @spec get_or_store(Appcues.RedisCache.json_encodable, Keyword.t, (() -> Appcues.RedisCache.json_encodable)) :: {:ok, Appcues.RedisCache.json_encodable} | {:error, any}
      def get_or_store(key, opts, fun) do
        Appcues.RedisCache.Calls.get_or_store(key, opts, fun, __MODULE__)
      end


      @doc ~S"""
      Retrieves a value if it exists in the cache.
      Otherwise, executes `fun` and caches the result.
      `opts[:ttl]` may be given to specify the time-to-live in milliseconds.
      Returns value (may be nil) or raises an exception.
      """
      @spec get_or_store!(Appcues.RedisCache.json_encodable, (() -> Appcues.RedisCache.json_encodable)) :: Appcues.RedisCache.json_encodable | no_return
      def get_or_store!(key, fun), do: get_or_store!(key, [], fun)

      @spec get_or_store!(Appcues.RedisCache.json_encodable, Keyword.t, (() -> Appcues.RedisCache.json_encodable)) :: Appcues.RedisCache.json_encodable | no_return
      def get_or_store!(key, opts, fun) do
        {:ok, val} = get_or_store(key, opts, fun)
        val
      end


      @doc ~S"""
      Executes an arbitrary Redis command.
      """
      @spec command([String.t]) :: {:ok, String.t | nil} | {:error, any}
      def command(cmd) do
        Appcues.RedisCache.Calls.command(cmd, __MODULE__)
      end

    end
  end


  use Application

  @doc false
  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    children = []
    opts = [strategy: :one_for_one, name: Appcues.RedisCache.Supervisor]
    Supervisor.start_link(children, opts)
  end

end

