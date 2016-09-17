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

      """
      def get(key, opts \\ []) do
        Appcues.RedisCache.get_with_pool(key, opts, @pool_name)
      end

      @doc ~S"""

      """
      def set(key, value, opts \\ []) do
        Appcues.RedisCache.set_with_pool(key, value, opts, @pool_name)
      end

      @doc ~S"""
      Retrieves a value if it exists in the cache.  Otherwise, executes `fun` and
      caches the result.  Returns `{:ok, value}` or `{:error, e}`.
      """
      def get_or_store(key, fun, opts \\ []) do
        Appcues.RedisCache.get_or_store_with_pool(key, fun, opts, @pool_name)
      end

    end
  end
end

