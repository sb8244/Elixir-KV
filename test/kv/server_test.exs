defmodule KV.ServerTest do
  use ExUnit.Case

  @moduletag :capture_log
  setup do
    Application.stop(:kv)
    :ok = Application.start(:kv)
  end

  # Create a socket for each test to make use of
  setup do
    opts = [:binary, packet: :line, active: false]
    {:ok, socket} = :gen_tcp.connect('localhost', 5050, opts)
    {:ok, socket: socket}
  end

  test "server integration behavior", %{socket: socket} do
    assert send_and_recv(socket, "INVALID\r\n") == "UNKNOWN COMMAND\r\n"
    assert send_and_recv(socket, "GET test key\r\n") == "BUCKET DOES NOT EXIST\r\n"
    assert send_and_recv(socket, "CREATE shopping\r\n") == "OK\r\n"
    assert send_and_recv(socket, "PUT shopping milk 1\r\n") == "OK\r\n"
    assert send_and_recv(socket, "GET shopping milk\r\n") == "1\r\n"
    assert send_and_recv(socket, "DELETE shopping milk\r\n") == "OK\r\n"
    assert send_and_recv(socket, "GET shopping milk\r\n") == "\r\n"
  end

  defp send_and_recv(socket, command) do
    :ok = :gen_tcp.send(socket, command)
    {:ok, data} = :gen_tcp.recv(socket, 0, 1000)
    data
  end
end
