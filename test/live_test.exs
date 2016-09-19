defmodule Appcues.TestRedisCache do
  use Appcues.RedisCache
end

defmodule Appcues.TestRedisCache2 do
  use Appcues.RedisCache
end

defmodule Appcues.RedisCache.LiveTests do
  use ExSpec, async: true
  doctest Appcues.RedisCache

  @moduletag :redis

  setup_all do
    Appcues.TestRedisCache.start_link
    Appcues.TestRedisCache2.start_link
    :ok
  end

  context "set/get" do
    it "handles valid input" do
      assert(:ok = Appcues.TestRedisCache.set!(:key1, "value1"))
      assert({:ok, "value1"} = Appcues.TestRedisCache.get(:key1))
      assert("value1" = Appcues.TestRedisCache.get!(:key1))
    end

    it "rejects non-JSON input" do
      assert({:error, _} = Appcues.TestRedisCache.set({1, 2, 3}, "x"))
      assert({:error, _} = Appcues.TestRedisCache.set("x", {1, 2, 3}))
      assert({:error, _} = Appcues.TestRedisCache.get({1, 2, 3}))
    end
  end

  context "get_or_store" do
    it "handles cache hits" do
      assert(:ok = Appcues.TestRedisCache.set(:lol, 1))
      assert({:ok, 1} = Appcues.TestRedisCache.get_or_store(:lol, fn -> raise "whoops" end))
      assert({:ok, 1} = Appcues.TestRedisCache.get(:lol))
    end

    it "handles cache misses" do
      assert({:ok, nil} = Appcues.TestRedisCache.get(:omg))
      assert(1 = Appcues.TestRedisCache.get_or_store!(:omg, fn -> 1 end))
      assert({:ok, 1} = Appcues.TestRedisCache.get(:omg))
    end
  end

  context "multiple caches, multiple modules" do
    it "keeps caches separate" do
      assert({:ok, nil} = Appcues.TestRedisCache.get(:separate))
      assert({:ok, nil} = Appcues.TestRedisCache2.get(:separate))

      assert(:ok = Appcues.TestRedisCache.set(:separate, 33))
      assert({:ok, 33} = Appcues.TestRedisCache.get(:separate))
      assert({:ok, nil} = Appcues.TestRedisCache2.get(:separate))

      assert(:ok = Appcues.TestRedisCache2.set(:separate, 44))
      assert({:ok, 33} = Appcues.TestRedisCache.get(:separate))
      assert({:ok, 44} = Appcues.TestRedisCache2.get(:separate))
    end
  end
end

