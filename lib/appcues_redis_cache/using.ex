defmodule Appcues.RedisCache.Using do
  defmacro __using__(_args) do
    quote do
      use Application

      @pool_name Module.concat(__MODULE__, Pool)

      @doc false
      def start(type, args) do
        Appcues.RedisCache.start_with_module_and_pool(type, args, __MODULE__, @pool_name)
      end

      @doc ~S"""
      Gets the specified item from the cache.
      Returns `{:ok, nil}` if not found, `{:ok, value}` if found, or `{:error, e}`.
      """
      @spec get(Appcues.RedisCache.json_encodable, Keyword.t) :: {:ok, Appcues.RedisCache.json_encodable} | {:error, any}
      def get(key, opts \\ []) do
        Appcues.RedisCache.get_with_pool(key, opts, @pool_name)
      end

      @doc ~S"""
      Sets the value stored under the given key.
      `opts[:ttl]` may be given to specify the time-to-live in milliseconds.
      Returns `:ok` or `{:error, e}`.
      """
      @spec set(Appcues.RedisCache.json_encodable, Appcues.RedisCache.json_encodable, Keyword.t) :: :ok | {:error, any}
      def set(key, value, opts \\ []) do
        Appcues.RedisCache.set_with_pool(key, value, opts, @pool_name)
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
        Appcues.RedisCache.get_or_store_with_pool(key, opts, fun, @pool_name)
      end

    end
  end
end

