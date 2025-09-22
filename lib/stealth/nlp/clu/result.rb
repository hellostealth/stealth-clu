# frozen_string_literal: true

module Stealth
  module Nlp
    module Clu
      class Result < Stealth::Nlp::Result

        # https://learn.microsoft.com/en-us/azure/ai-services/language-service/conversational-language-understanding/prebuilt-component-reference
        ENTITY_MAP = {
          'money' => :currency, 'number' => :number, 'email' => :email,
          'percentage' => :percentage, 'geographyV2' => :geo, 'age' => :age,
          'phonenumber' => :phone, 'ordinalV2' => :ordinal, 'url' => :url,
          'dimension' => :dimension, 'temperature' => :temp, 'keyPhrase' => :key_phrase,
          'personName' => :name, 'datetimeV2' => :datetime
        }

        def initialize(result:)
          @result = result
          if result.status.success?
            Stealth::Logger.l(
              topic: :nlp,
              message: 'NLP lookup successful'
            )
            parsed_result
          else
            Stealth::Logger.l(
              topic: :nlp,
              message: "NLP lookup FAILED: (#{result.status.code}) #{result.body.to_s}"
            )
          end

        end

        # https://learn.microsoft.com/en-gb/azure/ai-services/language-service/conversational-language-understanding/how-to/call-api?tabs=REST-APIs#test-the-model
        # Sample JSON result:
        # {
        #   "kind": "ConversationResult",
        #   "result": {
        #     "query": "Text1",
        #     "prediction": {
        #       "topIntent": "intent1",
        #       "projectKind": "Conversation",
        #       "intents": [
        #         {
        #           "category": "intent1",
        #           "confidenceScore": 1
        #         },
        #         {
        #           "category": "intent2",
        #           "confidenceScore": 0
        #         },
        #         {
        #           "category": "intent3",
        #           "confidenceScore": 0
        #         }
        #       ],
        #       "entities": [
        #         {
        #           "category": "entity1",
        #           "text": "text1",
        #           "offset": 29,
        #           "length": 12,
        #           "confidenceScore": 1
        #         }
        #       ]
        #     }
        #   }
        # }

        def parsed_result
          @parsed_result ||= MultiJson.load(result.body.to_s)
        end

        def intent
          top_intent&.to_sym
        end

        def intent_score
          parsed_result&.
              dig('result', 'prediction', 'intents')&.
              find { |intent| intent['category'] == top_intent }&.
              dig('confidenceScore')
        end

        def raw_entities
          parsed_result&.dig('result', 'prediction', 'entities')
        end

        # https://learn.microsoft.com/en-us/azure/ai-services/language-service/named-entity-recognition/concepts/entity-resolutions
        def entities
          return {} if raw_entities.blank?

          _entities = {}

          raw_entities.each do |entity|
            category = entity["category"]
            mapped_category = ENTITY_MAP[category] || category

            values = case mapped_category.to_sym
                    when :number, :percentage
                      entity["resolutions"]&.map { |res| res["value"] }
                    when :phone, :email, :url, :key_phrase, :name
                      [entity["text"]]
                    when :currency, :age, :dimension, :temp
                      entity["resolutions"]&.map do |res|
                        { "number" => res["value"], "units" => res["unit"] }
                      end
                    when :ordinal
                      entity["resolutions"]&.map do |res|
                        { "offset" => res["offset"].to_i, "relativeTo" => res["relativeTo"] }
                      end
                    when :geo
                      [{ "value" => entity["text"], "type" => "location" }]
                    when :datetime
                      [entity]
                    else
                      # Fallback: return text if no resolution
                      resolution_values = entity["resolutions"]&.map { |res| res["value"] }
                      resolution_values.presence || [entity["text"]]
                    end

            next if values.blank?
            _entities[mapped_category.to_sym] ||= []
            _entities[mapped_category.to_sym].concat(values)
          end

          _entities
        end

        private

        def top_intent
          @top_intent ||= begin
            matched_intent = parsed_result&.dig('result', 'prediction', 'topIntent')
            _intent_score = parsed_result&.
              dig('result', 'prediction', 'intents')&.
              find { |intent| intent['category'] == matched_intent }&.
              dig('confidenceScore')

            if Stealth.config.clu.intent_threshold.is_a?(Numeric)
              if _intent_score > Stealth.config.clu.intent_threshold
                matched_intent
              else
                Stealth::Logger.l(
                  topic: :nlp,
                  message: "Ignoring intent match. Does not meet threshold (#{Stealth.config.clu.intent_threshold})"
                )
                'None' # can't be nil or this doesn't get memoized
              end
            else
              matched_intent
            end
          end
        end

      end
    end
  end
end
