# frozen_string_literal: true

module Stealth
  module Nlp
    module Clu
      class Client < Stealth::Nlp::Client

        def initialize(subscription_key: nil, project_name: nil, deployment_name: nil, endpoint: nil, datetime_ref: nil)
          begin
            @subscription_key = subscription_key || Stealth.config.clu.subscription_key
            @project_name = project_name || Stealth.config.clu.project_name
            @deployment_name = deployment_name || Stealth.config.clu.deployment_name
            @endpoint = endpoint || Stealth.config.clu.endpoint
            @datetime_ref = datetime_ref || Stealth.config.clu.datetime_reference
          rescue NoMethodError
            raise(
              Stealth::Errors::ConfigurationError,
              'A `clu` configuration key must be specified directly or in `services.yml`'
            )
          end
        end

        def endpoint
          "https://#{@endpoint}/language/:analyze-conversations?api-version=2023-04-01"
        end

        def client
          @client ||= begin
            headers = {
              'Content-Type' => 'application/json',
              'Ocp-Apim-Subscription-Key' => @subscription_key
            }
            HTTP.timeout(connect: 15, read: 60).headers(headers)
          end
        end

        def understand(query:)
          body = MultiJson.dump({
            'kind' => 'Conversation',
            'analysisInput' => {
              'conversationItem' => {
                'participantId' => '1',
                'id' => '1',
                'modality' => 'text',
                'language' => 'en',
                'text' => query
              }
            },
            'parameters' => {
              'projectName' => @project_name,
              'deploymentName' => @deployment_name,
              'stringIndexType' => 'TextElement_V8',
              'verbose' => true
            }
          })

          Stealth::Logger.l(
            topic: :nlp,
            message: 'Performing NLP lookup via Microsoft CLU'
          )

          result = client.post(endpoint, body: body)
          Result.new(result: result)
        end

      end
    end
  end
end

ENTITY_TYPES = %i(number currency email percentage phone age
                        url ordinal geo dimension temp datetime duration)
