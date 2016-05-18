require 'kafka'

logger = Logger.new($stderr)

kafka_att = Kafka.new(:seed_brokers => ["#{ENV['KAFKA_HOST']}:9092"],
                      :logger => logger,
                      :client_id => "attribution")
kafka_postback = Kafka.new(:seed_brokers => ["#{ENV['KAFKA_HOST']}:9092"],
                           :logger => logger,
                           :client_id => "postback")

$kafka_postback_consumer = kafka_postback.consumer(:group_id => "postback")
$kafka_attribution_consumer = kafka_att.consumer(:group_id => "attribution")
