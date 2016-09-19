# Appcues.RedisCache

A wrapper around Redis that provides `get`, `set`, and `get_or_store`.

See [lib/appcues_redis_cache.ex] for usage information.

## Testing

Testing without Redis running locally:

    mix test

Testing with Redis running locally at `redis://localhost:6379`:

    mix test --include=redis

