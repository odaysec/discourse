# frozen_string_literal: true

module Sidekiq
  def self.redis_pool
    @redis ||= RedisConnection.create
    Thread.current[:sidekiq_via_pool] || @redis
  end

  def self.old_pool
    @old_pool ||= RedisConnection.create(Discourse.sidekiq_redis_config(old: true))
  end
end
