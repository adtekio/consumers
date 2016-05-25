require 'redis'
require 'redis/connection/hiredis'

require 'connection_pool'

### Local redis for url queues and sidekiq
redis_conn = proc {
  Redis.new(:url => ENV['REDISTOGO_URL'], :driver => :hiredis)
}
$redis_pool =
  ConnectionPool.new(:size => (ENV['REDIS_POOL_SIZE'] || '5').to_i, &redis_conn)

### Click redis for storing stats and clicks for matching.
redis_click_conn = proc {
  Redis.new(:url => ENV['CLICK_REDIS_URL'], :driver => :hiredis)
}
$redis_click_pool =
  ConnectionPool.new(:size => (ENV['REDIS_POOL_SIZE'] || '5').to_i,
                     &redis_click_conn)
