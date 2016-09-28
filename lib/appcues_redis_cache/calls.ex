defmodule Appcues.RedisCache.Calls do
  @moduledoc ~S"""
  Handles `get`, `set`, `get_or_store`, and `command` calls to an
  `Appcues.RedisCache` pool.
  """

  alias Appcues.RedisCache.Utils

  @type key :: String.t | atom
  @type value :: Appcues.RedisCache.json_encodable

  @spec get(key, Keyword.t, atom) :: {:ok, value} | {:error, any}
  def get(key, opts, module) do
    try do
      key_string = to_string(key)
      case command(["GET", key_string], module) do
        {:ok, nil} -> {:ok, nil}
        {:ok, val} -> Poison.decode(val)
        {:error, e} -> {:error, e}
      end
    rescue
      e -> {:error, e}
    end
  end

  @spec set(key, value, Keyword.t, atom) :: :ok | {:error, any}
  def set(key, value, opts, module) do
    try do
      key_string = to_string(key)
      value_string = Poison.encode!(value)
      ttl = opts[:ttl] || Utils.config(module, :default_ttl)
      {:ok, _} = command(["SET", key_string, value_string, "PX", "#{ttl}"], module)
      :ok
    rescue
      e -> {:error, e}
    end
  end

  @spec get_or_store(key, Keyword.t, (() -> value), atom) :: {:ok, value} | {:error, any}
  def get_or_store(key, opts, fun, module) do
    with {:ok, val} <- get(key, opts, module)
    do
      case val do
        nil ->
          new_val = fun.()
          case set(key, new_val, opts, module) do
            :ok -> {:ok, new_val}
            {:error, e} -> {:error, e}
          end
        val ->
          {:ok, val}
      end
    end
  end

  @spec command([String.t], atom) :: {:ok, String.t | nil} :: {:error, any}
  def command(cmd, module) do
    pool_name = Utils.pool_name(module)
    :poolboy.transaction pool_name, fn (worker_pid) ->
      :gen_server.call(worker_pid, {:command, cmd})
    end
  end


end
