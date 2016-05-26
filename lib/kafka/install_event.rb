require_relative 'event'
require 'digest/md5'
require 'digest/sha1'

module Consumers
  module Kafka
    class InstallEvent < Consumers::Kafka::Event
      def initialize(payload)
        super(payload)
      end

      def idfa_md5
        @idfa_md5_cache ||=
          adid.present? ? Digest::MD5.hexdigest(adid.to_s) : nil
      end

      def idfa_sha1
        @idfa_sha1_cache ||=
          adid.present? ? Digest::SHA1.hexdigest(adid.to_s) : nil
      end

      def fingerprint
        "#{ip.to_s}.#{platform.to_s}"
      end

      def lookup_keys
        @lookup_keys ||= [adid, idfa_sha1, idfa_md5,
                          fingerprint].reject do |key|
          key.blank?
        end.map do |key|
          Digest::MD5.hexdigest("#{key}".downcase)
        end
      end
    end
  end
end
