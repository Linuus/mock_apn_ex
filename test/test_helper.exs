ExUnit.start()

defmodule PushClient do
  def push(socket, token, msg_id \\ 123123)
  def push(socket, token, msg_id) do
    push(socket, token, msg_id, %{aps: %{alert: "Test"}})
  end
  def push(socket, token, msg_id, payload) do
    payload =  Poison.encode!(payload)
    token_bin = Base.decode16!(token, case: :mixed)

    frame = <<
    1                  :: 8,
    32                 :: 16,
    token_bin          :: binary,
    2                  :: 8,
    byte_size(payload) :: 16,
    payload            :: binary,
    3                  :: 8,
    4                  :: 16,
    msg_id             :: 32,
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
  end
end
