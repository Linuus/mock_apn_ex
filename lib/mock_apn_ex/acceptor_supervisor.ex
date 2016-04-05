defmodule MockApnEx.AcceptorSupervisor do
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    # {ok, Port} = application:get_env(port),

    :ssl.start()

    {:ok, listen_socket} = :ssl.listen(5555, [certfile: "priv/certs/cert.pem", keyfile: "priv/certs/key.pem", password: 'asdf', mode: :binary, active: :false, packet: 0])
    spawn_link(fn -> empty_listeners() end)

    children = [
      worker(MockApnEx.Server, [listen_socket], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  def start_socket do
    Supervisor.start_child(__MODULE__, [])
  end

  defp empty_listeners do
    for _ <- (1..20), do: start_socket()
  end
end
