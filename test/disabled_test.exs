defmodule Appcues.DisabledRedisCache do
  use Appcues.RedisCache
end

defmodule Appcues.RedisCache.DisabledTests do
  use ExSpec, async: true

  setup_all do
    Appcues.DisabledRedisCache.start(:x, :y)
    :ok
  end

  it "shunts set/get calls" do
    assert(:ok = Appcues.DisabledRedisCache.set("123", 456))
    assert({:ok, nil} = Appcues.DisabledRedisCache.get("123"))
  end

  it "shunts get_or_store calls" do
    assert(:ok = Appcues.DisabledRedisCache.set("456", 123))
    assert({:ok, nil} = Appcues.DisabledRedisCache.get("456"))
    assert({:ok, 22} = Appcues.DisabledRedisCache.get_or_store("456", fn -> 22 end))
  end
end

