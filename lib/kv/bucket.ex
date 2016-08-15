defmodule KV.Bucket do
  @doc """
  Start a new bucket
  """
  def start_link do
    Agent.start_link(fn -> %{} end)
  end

  @doc """
  Retrieve the given key from the bucket
  """
  def get(bucket, key) do
    Agent.get(bucket, &Map.get(&1, key))
  end

  @doc """
  Retrieve the given value at the given key in the bucket
  """
  def put(bucket, key, value) do
    Agent.update(bucket, &Map.put(&1, key, value))
  end

  @doc """
  Remove the given key from the bucket
  """
  def delete(bucket, key) do
    Agent.get_and_update(bucket, &Map.pop(&1, key))
  end
end
