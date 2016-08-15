defmodule KV.Registry do
  use GenServer

  def start_link(name) do
    GenServer.start_link(__MODULE__, name, name: name)
  end

  def lookup(server, name) when is_atom(server) do
    case :ets.lookup(server, name) do
      [{^name, pid}] -> {:ok, pid}
      [] -> :error
    end
  end

  def create(server, name) do
    GenServer.call(server, {:create, name})
  end

  def stop(server) do
    GenServer.stop(server)
  end

  ## Server Callbacks

  def init(table) do
    names = :ets.new(table, [:named_table, read_concurrency: true])
    refs = Map.new # Hold the monitor->name mapping
    {:ok, {names, refs}}
  end

  def handle_call({:lookup, name}, _from, {names, _} = state) do
    {:reply, Map.fetch(names, name), state}
  end

  @doc """
  Handle creation call by creating or ensuring a KV.Bucket exists for the given
  name
  """
  def handle_call({:create, name}, _from, {names, refs}) do
    case lookup(names, name) do
      {:ok, pid} -> {:reply, {:present, pid}, {names, refs}}
      :error ->
        {:ok, pid} = KV.Bucket.Supervisor.start_bucket()
        ref = Process.monitor(pid)
        refs = Map.put(refs, ref, name)
        :ets.insert(names, {name, pid})
        {:reply, {:created, pid}, {names, refs}}
    end
  end

  @doc """
  Handle :DOWN event by deleting the process ref and name
  """
  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    {name, refs} = Map.pop(refs, ref)
    :ets.delete(names, name)
    {:noreply, {names, refs}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
