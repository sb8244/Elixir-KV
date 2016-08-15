require Logger

defmodule KV.Server do
  def accept(port) do
    opts = [:binary, packet: :line, active: false, reuseaddr: true]
    {:ok, socket} = :gen_tcp.listen(port, opts)
    Logger.info "Accepting KV.Server connections on #{port}"
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(KV.Server.TaskSupervisor, fn -> serve(client) end)
    :ok = :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket)
  end

  defp serve(socket) do
    msg = case read_line(socket) do
      {:ok, line} ->
        case KV.Server.Command.parse(line) do
          {:ok, command} -> KV.Server.Command.run(KV.Registry, command)
          {:error, _} = err -> err
        end
      {:error, _} = err -> err
    end

    write_line(socket, msg)
    serve(socket)
  end

  defp read_line(socket) do
    :gen_tcp.recv(socket, 0)
  end

  defp write_line(_socket, {:error, :closed}) do
    exit(:shutdown)
  end

  defp write_line(socket, {:error, :unknown_command}) do
    :gen_tcp.send(socket, "UNKNOWN COMMAND\r\n")
  end

  defp write_line(socket, {:error, :not_found}) do
    :gen_tcp.send(socket, "BUCKET DOES NOT EXIST\r\n")
  end

  defp write_line(socket, {:error, error}) do
    :gen_tcp.send(socket, "ERROR\r\n")
    exit(error)
  end

  defp write_line(socket, {:ok, text}) do
    :gen_tcp.send(socket, "#{text}")
  end
end
