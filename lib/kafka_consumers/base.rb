module Consumers
  module Base
    attr_reader :cache

    def start_kafka_stream(name, group_id, topics, loop_count)
      lgk_message = OpenStruct.new(:offset => -1)
      lgk_event   = OpenStruct.new(:delay_in_seconds => -1)

      begin_handling_messages

      $kafka[name].consumer(:group_id => group_id).tap do |c|
        [topics].flatten.each { |topic| c.subscribe(topic) }
      end.each_batch(:loop_count => loop_count, :max_wait_time => 0) do |batch|
        batch.messages.each do |message|
          next unless handle_message_type?(message.value)

          lgk_message = message
          lgk_event   = do_work(message)
        end
      end

      done_handling_messages

      $librato_queue.add("#{name}_event_delay" => lgk_event.delay_in_seconds)
      $librato_queue.add("#{name}_offset" => lgk_message.offset)
    end

    def handle_these_events(event_types)
      @listen_to_these_events = event_types
    end

    def handle_message_type?(message)
      type = $1 if message =~ /^[^[:space:]]*\/([^[:space:]]+)[[:space:]]/
      @listen_to_these_events.include?(type)
    end

    def handle_exception(exp)
      puts "#{self.class.name}: Preventing retries on error: #{exp}"
      unless exp.to_s =~ /No partitions assigned/
        puts(exp.backtrace) if exp.to_s =~ /redis/i
        puts(exp.backtrace) if exp.to_s =~ /not allowed when used memory/i
      end
    end

    def update_cache(interval, &block)
      t = Time.now
      if (@cache_timestamp + interval) < t
        @cache_timestamp = t
        @cache           = yield
      end
    end

    def initialize_cache(&block)
      @cache_timestamp = Time.now
      @cache           = yield
    end

    def begin_handling_messages
    end

    def done_handling_messages
    end
  end
end
