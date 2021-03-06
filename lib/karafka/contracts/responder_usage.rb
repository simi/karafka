# frozen_string_literal: true

module Karafka
  module Contracts
    # Validator to check responder topic usage
    class ResponderUsageTopic < Dry::Validation::Contract
      config.messages.load_paths << File.join(Karafka.gem_root, 'config', 'errors.yml')

      params do
        required(:name).filled(:str?, format?: Karafka::Contracts::TOPIC_REGEXP)
        required(:required).filled(:bool?)
        required(:usage_count).filled(:int?, gteq?: 0)
        required(:registered).filled(eql?: true)
        required(:async).filled(:bool?)
        required(:serializer).filled
      end

      rule(:required, :usage_count) do
        key(:name).failure(:required_usage_count) if values[:required] && values[:usage_count] < 1
      end
    end

    # Validator to check that everything in a responder flow matches responder rules
    class ResponderUsage < Dry::Validation::Contract
      include Dry::Core::Constants

      # Contract for verifying the topic usage details
      TOPIC_CONTRACT = ResponderUsageTopic.new.freeze

      private_constant :TOPIC_CONTRACT

      params do
        required(:used_topics)
        required(:registered_topics)
      end

      rule(:used_topics) do
        (value || EMPTY_ARRAY).each do |used_topic|
          TOPIC_CONTRACT.call(used_topic).errors.each do |error|
            key([:used_topics, used_topic, error.path[0]]).failure(error.text)
          end
        end
      end

      rule(:registered_topics) do
        (value || EMPTY_ARRAY).each do |used_topic|
          TOPIC_CONTRACT.call(used_topic).errors.each do |error|
            key([:registered_topics, used_topic, error.path[0]]).failure(error.text)
          end
        end
      end
    end
  end
end
