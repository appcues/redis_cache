defmodule Appcues.RedisCache.Calls do
  @moduledoc ~S"""
  Handles `get`, `set`, and `get_or_store` calls to an
  `Appcues.RedisCache` pool.
  """

  @spec get_with_pool(Appcues.RedisCache.json_encodable, Keyword.t, atom) :: {:ok, Appcues.RedisCache.json_encodable} | {:error, any}
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

  @spec set_with_pool(Appcues.RedisCache.json_encodable, Appcues.RedisCache.json_encodable, Keyword.t, atom) :: :ok | {:error, any}
  def set_with_pool(key, value, opts, pool_name) do
    with {:ok, key_string} <- Poison.encode(key),
         {:ok, value_string} <- Poison.encode(value)
    do
      :poolboy.transaction pool_name, fn (worker_pid) ->
        :gen_server.call(worker_pid, {:set, key_string, value_string, opts})
      end
    end
  end

  @spec get_or_store_with_pool(Appcues.RedisCache.json_encodable, Keyword.t, (() -> Appcues.RedisCache.json_encodable), atom) :: {:ok, Appcues.RedisCache.json_encodable} | {:error, any}
  def get_or_store_with_pool(key, opts, fun, pool_name) do
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
