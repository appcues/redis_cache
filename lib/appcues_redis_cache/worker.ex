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
      disabled: opts[:disabled],
      redis_url: opts[:redis_url],
      redis_conn: nil,
    }}
  end

  ## Handle disabled state

  def handle_call(_msg, _from, %{disabled: true}=state) do
    {:reply, {:ok, nil}, state}
  end

  @type call_reply :: {:ok, String.t | nil} :: {:error, any}
  @spec handle_call({:command, [String.t]}, pid, %{}) :: {:reply, call_reply, %{}}
  def handle_call({:command, cmd}, _from, state) do
    state = connect(state)
    cmd = Enum.map(cmd, &Kernel.to_string/1)
    reply = Redix.command(state.redis_conn, cmd)
    {:reply, reply, state}
  end

  @spec connect(state) :: state
  defp connect(%{redis_conn: nil}=state) do
    {:ok, conn} = Redix.start_link(state.redis_url)
    %{state | redis_conn: conn}
  end

  defp connect(state), do: state
end

