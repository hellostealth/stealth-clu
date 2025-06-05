# frozen_string_literal: true

module Stealth
  module Nlp
    module Clu
      class Result < Stealth::Nlp::Result

        ENTITY_MAP = {
          'money' => :currency, 'number' => :number, 'email' => :email,
          'percentage' => :percentage, 'Calendar.Duration' => :duration,
          'geographyV2' => :geo, 'age' => :age, 'phonenumber' => :phone,
          'ordinalV2' => :ordinal, 'url' => :url, 'dimension' => :dimension,
          'temperature' => :temp, 'keyPhrase' => :key_phrase, 'name' => :name,
          'datetimeV2' => :datetime
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

            # List entities
            list_key = entity["extraInformation"]&.find { |info| info["extraInformationKind"] == "ListKey" }&.dig("key")
            # Standard entities
            resolution_values = entity["resolutions"]&.map { |res| res["value"] }&.compact
            # Fallback to raw user input that matched the entity
            text_value = entity["text"]

            # Choose final value array in priority: ListKey > Resolutions > Text
            values =
              if list_key
                [list_key]
              elsif resolution_values&.any?
                resolution_values
              else
                [text_value]
              end

            _entities[mapped_category.to_sym] ||= []
            _entities[mapped_category.to_sym].concat(values)
          end

          _entities
        end

        # def sentiment_score
        #   parsed_result&.dig('prediction', 'sentiment', 'score')
        # end

        # def sentiment
        #   parsed_result&.dig('prediction', 'sentiment', 'label')&.to_sym
        # end

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
