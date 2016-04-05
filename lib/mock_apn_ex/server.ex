defmodule MockApnEx.Server do
  use GenServer

  @statuses %{
    0   => "No errors encountered",
    1   => "Processing",
    2   => "Missing device token",
    3   => "Missing topic",
    4   => "Missing payload",
    5   => "Invalid token size",
    6   => "Invalid topic size",
    7   => "Invalid payload size",
    8   => "Invalid token",
    10  => "Shutdown",
    255 => "None (unknown)"
  }

  def start_link(listen_socket) do
    GenServer.start_link(__MODULE__, listen_socket, [])
  end

  def init(listen_socket) do
    GenServer.cast(self(), :accept)
    {:ok, %{socket: listen_socket, buffer: ""}}
  end

  def handle_cast(:accept, %{socket: listen_socket} = state) do
    :ssl.setopts(listen_socket, [active: :once])
    {:ok, socket} = :ssl.transport_accept(listen_socket)
    :ok = :ssl.ssl_accept(socket)
    MockApnEx.AcceptorSupervisor.start_socket()
    {:noreply, %{state | socket: socket}}
  end

  def handle_cast(:respond, %{socket: socket, buffer: buffer} = state) do
    case buffer do
      <<
      1 :: 8, token_size :: 16, token :: binary-size(token_size),
      2 :: 8, payload_size :: 16, _payload :: binary-size(payload_size),
      3 :: 8, 4 :: 16, msg_id :: binary-4,
      rest :: binary
      >> ->
        token = token |> Base.encode16(case: :lower)
        status_keys = Enum.map(@statuses, fn({key, _}) -> Integer.to_string(key) end)

        case captures = Regex.named_captures(~r/fff(?<status>[#{status_keys}]+)/, token) do
          %{"status" => status} ->
            status = String.to_integer(status)
            :ssl.send(socket, <<status :: 8, 8 :: 8, msg_id :: binary>>)
            :ssl.close(socket)
            {:noreply, %{state | buffer: rest}}
          _ ->
            {:noreply, %{state | buffer: rest}}
        end
      _ ->
        {:noreply, state}
    end
  end

  def handle_info({:ssl, socket, data}, %{buffer: buffer} = state) do
    :ssl.setopts(socket, [active: :once])
    GenServer.cast(self(), :respond)
    case data do
      <<2 :: 8, frame_size :: 32, frame :: binary-size(frame_size)>> ->
        {:noreply, %{state | buffer: <<buffer :: binary, frame :: binary>>}}
    end
  end
end
