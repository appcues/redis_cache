defmodule Appcues.RedisCacheTest do
  use ExSpec, async: true
  doctest Appcues.RedisCache

  context "Appcues.RedisCache" do
    context "set/get" do
      it "handles valid input" do
        assert(:ok = Appcues.RedisCache.set(:key1, "value1"))
        assert({:ok, "value1"} = Appcues.RedisCache.get(:key1))
      end

      it "rejects non-JSON input" do
        assert({:error, _} = Appcues.RedisCache.set({1, 2, 3}, "x"))
        assert({:error, _} = Appcues.RedisCache.set("x", {1, 2, 3}))
        assert({:error, _} = Appcues.RedisCache.get({1, 2, 3}))
      end
    end

    context "get_or_store" do
      it "handles cache hits" do
        assert(:ok = Appcues.RedisCache.set(:lol, 1))
        assert({:ok, 1} = Appcues.RedisCache.get_or_store(:lol, fn -> raise "whoops" end))
        assert({:ok, 1} = Appcues.RedisCache.get(:lol))
      end

      it "handles cache misses" do
        assert({:ok, nil} = Appcues.RedisCache.get(:omg))
        assert({:ok, 1} = Appcues.RedisCache.get_or_store(:omg, fn -> 1 end))
        assert({:ok, 1} = Appcues.RedisCache.get(:omg))
      end
    end
  end
end

