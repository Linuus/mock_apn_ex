defmodule MockApnEx.AcceptorSupervisor do
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    port = Application.get_env(:mock_apn_ex, :port) || 2195

    :ssl.start()

    {:ok, listen_socket} = :ssl.listen(port, ssl_opts())
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

  defp ssl_opts do
    Application.get_all_env(:mock_apn_ex)
    |> Keyword.take([:certfile, :keyfile, :password])
    |> Keyword.put(:mode, :binary)
    |> Keyword.put(:active, :false)
    |> Keyword.put(:packet, 0)
    |> Keyword.put(:reuseaddr, true)
  end
end
