defmodule KV.Server.CommandTest do
  use ExUnit.Case, async: true

  describe "KV.Server.CommandTest.parse/1" do
    test "parses `CREATE bucket` command" do
      assert KV.Server.Command.parse("CREATE name") == {:ok, {:create, "name"}}
    end

    test "parses `PUT bucket key value`" do
      assert KV.Server.Command.parse("PUT bucket key value") == {:ok, {:put, "bucket", "key", "value"}}
    end

    test "parses `GET bucket key`" do
      assert KV.Server.Command.parse("GET bucket key") == {:ok, {:get, "bucket", "key"}}
    end

    test "parses `DELETE bucket key`" do
      assert KV.Server.Command.parse("DELETE bucket key") == {:ok, {:delete, "bucket", "key"}}
    end

    test "parses invalid commands" do
      assert KV.Server.Command.parse("DELETE bucket key value") == {:error, :unknown_command}
      assert KV.Server.Command.parse("GETP bucket") == {:error, :unknown_command}
    end
  end

  describe "KV.Server.Command.run/2" do
    setup context do
      {:ok, _registry} = KV.Registry.start_link(context.test)
      {:ok, registry: context.test}
    end

    test "executes `{:create, name}`", %{registry: registry} do
      assert KV.Server.Command.run(registry, {:create, "Test"}) == {:ok, "OK\r\n"}
      {:ok, _bucket} = KV.Registry.lookup(registry, "Test")
    end

    test "executes `{:get, name, key}`", %{registry: registry} do
      {:created, bucket} = KV.Registry.create(registry, "Test")
      KV.Bucket.put(bucket, "key", "value")
      assert KV.Server.Command.run(registry, {:get, "Test", "key"}) == {:ok, "value\r\n"}
    end

    test "executes `{:delete, name, key}`", %{registry: registry} do
      {:created, bucket} = KV.Registry.create(registry, "Test")
      KV.Bucket.put(bucket, "key", "value")
      assert KV.Server.Command.run(registry, {:delete, "Test", "key"}) == {:ok, "OK\r\n"}
      assert KV.Bucket.get(bucket, "key") == nil
    end

    test "executes `{:put, name, key, value}`", %{registry: registry} do
      {:created, bucket} = KV.Registry.create(registry, "Test")
      assert KV.Server.Command.run(registry, {:put, "Test", "key", 1}) == {:ok, "OK\r\n"}
      assert KV.Bucket.get(bucket, "key") == 1
    end

    test ":get with a not created bucket is {:error, :not_found}", %{registry: registry} do
      assert {:error, :not_found} = KV.Server.Command.run(registry, {:get, "Test", "key"})
    end

    test ":delete with a not created bucket is {:error, :not_found}", %{registry: registry} do
      assert {:error, :not_found} = KV.Server.Command.run(registry, {:delete, "Test", "key"})
    end

    test ":put with a not created bucket is {:error, :not_found}", %{registry: registry} do
      assert {:error, :not_found} = KV.Server.Command.run(registry, {:put, "Test", "key", "value"})
    end
  end
end
