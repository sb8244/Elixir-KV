defmodule KV.Server.Command do
  def parse(line) do
    case String.split(line) do
      ["CREATE", bucket] -> {:ok, {:create, bucket}}
      ["DELETE", bucket, key] -> {:ok, {:delete, bucket, key}}
      ["PUT", bucket, key, value] -> {:ok, {:put, bucket, key, value}}
      ["GET", bucket, key] -> {:ok, {:get, bucket, key}}
      _ -> {:error, :unknown_command}
    end
  end

  def run(registry, {:create, bucket_name}) do
    KV.Registry.create(registry, bucket_name)
    {:ok, "OK\r\n"}
  end

  def run(registry, {:delete, bucket_name, key}) do
    lookup registry, bucket_name, fn pid ->
      KV.Bucket.delete(pid, key)
      {:ok, "OK\r\n"}
    end
  end

  def run(registry, {:get, bucket_name, key}) do
    lookup registry, bucket_name, fn pid ->
      {:ok, "#{KV.Bucket.get(pid, key)}\r\n"}
    end
  end

  def run(registry, {:put, bucket_name, key, value}) do
    lookup registry, bucket_name, fn pid ->
      {KV.Bucket.put(pid, key, value), "OK\r\n"}
    end
  end

  def lookup(registry, bucket_name, callback) do
    case KV.Registry.lookup(registry, bucket_name) do
      {:ok, pid} -> callback.(pid)
      :error -> {:error, :not_found}
    end
  end
end
