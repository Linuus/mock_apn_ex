defmodule SendMessage do
  :ssl.start()
  {:ok, socket} = :ssl.connect('localhost', 2195, [packet: 0, active: true, mode: :binary])

  payload = %{aps: %{alert: "Test"}} |> Poison.encode!
  token_bin =
    "fff3aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaAbC"
    |> Base.decode16!(case: :mixed)

  frame = <<
  1                  :: 8,
  32                 :: 16,
  token_bin          :: binary,
  2                  :: 8,
  byte_size(payload) :: 16,
  payload            :: binary,
  3                  :: 8,
  4                  :: 16,
  123123             :: 32,    # msg id
  4                  :: 8,
  4                  :: 16,
  1231231233         :: 32,    # Expiry
  5                  :: 8,
  1                  :: 16,
  10                 :: 8      # Priority
  >>

  packet = <<
  2                 ::  8,
  byte_size(frame)  ::  32,
  frame             ::  binary
  >>

  :ssl.send(socket, packet)
  receive do
    {:ssl, _socket, <<8 :: 8, 8 :: 8, msg_id :: binary>>} ->
      IO.inspect(msg_id)
    other -> IO.inspect(other)
  end

  receive do
    {:ssl_closed, _socket} ->
      IO.puts "Socket closed"
  end
end
