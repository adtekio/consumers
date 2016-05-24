module Consumers
  class Clickstore
    include Sidekiq::Worker

    sidekiq_options :queue => :clickstore_consumer

    def initialize
      @listen_to_these_events = ["click"]
    end

    def perform
      click_consumer = $kafka_clicks.consumer(:group_id => "clicks")

      click_consumer.subscribe("clicks")
      click_consumer.each_message(:loop_count => 15) do |message|
        puts "MESSAGE OFFSET: #{message.offset}"
        event = Consumers::Kafka::ClickEvent.new(message.value)
        next unless @listen_to_these_events.include?(event.call)
        Click.create(event.to_hash)
      end
    rescue
      puts "Preventing retries on error"
      puts $!
      nil
    end
  end
end