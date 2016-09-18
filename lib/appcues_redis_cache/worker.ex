defmodule Appcues.RedisCache.Worker do
  use GenServer

  @type state :: %{}

  @spec start_link(Keyword.t) :: :ok
  def start_link(opts) do
    :gen_server.start_link(__MODULE__, opts, [])
  end

  @spec init(Keyword.t) :: {:ok, state}
  def init(opts) do
    {:ok, %{
      default_ttl: opts[:default_ttl],
      redis_url: opts[:redis_url],
      redis_conn: nil,
    }}
  end

  @type set_call :: {:set, String.t, String.t, Keyword.t}
  @type set_reply :: :ok | {:error, any}
  @spec handle_call(set_call, pid, state) :: {:reply, set_reply, state}
  def handle_call({:set, key_string, value_string, opts}, _from, state) do
    state = connect(state)
    opts = opts || []
    ttl = opts[:ttl] || state.default_ttl
    command = ["SET", key_string, value_string, "PX", "#{ttl}"]
    set_reply = case Redix.command(state.redis_conn, command) do
      {:ok, _} -> :ok
      {:error, e} -> {:error, e}
    end
    {:reply, set_reply, state}
  end

  @type get_call :: {:get, String.t, Keyword.t}
  @type get_reply :: {:ok, String.t | nil} | {:error, any}
  @spec handle_call(get_call, pid, state) :: {:reply, get_reply, state}
  def handle_call({:get, key_string, _opts}, _from, state) do
    #opts = opts || []
    state = connect(state)
    command = ["GET", key_string]
    {:reply, Redix.command(state.redis_conn, command), state}
  end

  @spec connect(state) :: state
  defp connect(%{redis_conn: nil}=state) do
    {:ok, conn} = Redix.start_link(state.redis_url)
    %{state | redis_conn: conn}
  end

  defp connect(state), do: state
end

