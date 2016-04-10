defmodule MockApnExTest do
  use ExUnit.Case

  setup do
    :ssl.start()

    {:ok, socket} = :ssl.connect('localhost', 2195, [packet: 0, active: true, mode: :binary])

    {:ok, %{socket: socket}}
  end

  test "it returns nothing on good token", %{socket: socket} do
    token = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaAbC"
    PushClient.push(socket, token, 123456)

    refute_receive {:ssl, ^socket, _}
    refute_receive {:ssl_closed, ^socket}
  end

  test "it returns error code 3 and closes socket", %{socket: socket} do
    token = "fff3aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaAbC"
    PushClient.push(socket, token, 123456)

    assert_receive {:ssl, ^socket, <<8::8, 3::8, 123456::integer-32>>}
    assert_receive {:ssl_closed, ^socket}
  end

  test "it returns error code 10", %{socket: socket} do
    token = "fff10aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaAbC"
    PushClient.push(socket, token, 123456)

    assert_receive {:ssl, ^socket, <<8::8, 10::8, 123456::integer-32>>}
    assert_receive {:ssl_closed, ^socket}
  end

  test "it returns error code 255", %{socket: socket} do
    token = "fff255aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaAbC"
    PushClient.push(socket, token, 123456)

    assert_receive {:ssl, ^socket, <<8::8, 255::8, 123456::integer-32>>}
    assert_receive {:ssl_closed, ^socket}
  end

  test "it returns error when bad token sent after good", %{socket: socket} do
    token = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaAbC"
    PushClient.push(socket, token, 123456)

    token = "fff5aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaAbC"
    PushClient.push(socket, token, 123345)

    assert_receive {:ssl, ^socket, <<8::8, 5::8, 123345::integer-32>>}
    assert_receive {:ssl_closed, ^socket}
  end

  test "it returns error when good token sent after bad", %{socket: socket} do
    token = "fff5aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaAbC"
    PushClient.push(socket, token, 123345)

    token = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaAbC"
    PushClient.push(socket, token, 123456)

    assert_receive {:ssl, ^socket, <<8::8, 5::8, 123345::integer-32>>}
    assert_receive {:ssl_closed, ^socket}
  end
end
