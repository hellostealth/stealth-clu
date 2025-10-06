# Stealth CLU

Built-in NLP for Stealth bots via Microsoft's Conversational Language Understanding (CLU)
This integration implements the Microsoft Conversational Language Understanding (CLU) service. It utilizes the built-in NLP features of Stealth 2.0.0.beta.

⚠️ If you are still using Stealth 1.x, you will first need to upgrade to Stealth 2.0.0.beta before you can use this integration.


## Configuration

For instructions on creating your first [Azure CLU Project](https://docs.azure.cn/en-us/ai-services/language-service/conversational-language-understanding/how-to/create-project?tabs=language-studio), and on configuring your CLU project, please refer to the [Analyze Conversation API documentation](https://learn.microsoft.com/en-us/rest/api/language/analyze-conversations/analyze-conversations?view=rest-language-2023-04-01&utm_source=chatgpt.com&tabs=HTTP).

Once your account is set up, add these configuration settings to your `services.yml` file:
```yaml
default: &default
  nlp_integration: clu
  clu:
    subscription_key: <your-clu-subscription-key>
    project_name: <your-clu-project>
    deployment_name: <your-clu-deployment-name>
    endpoint: <your-clu-endpoint>

production:
  <<: *default
development:
  <<: *default
test:
  <<: *default
```

Use the appropriate `deployment_name` to manage your different environment endpoints (e.g., development, staging, production).

That's it! Stealth will now automatically use CLU for intent detection and entity extraction automatically via `handle_message` and `get_match` methods.


## ⚠️ Migration from `stealth-luis` to `stealth-clu`

Microsoft annonced that LUIS will be fully retired on October 1, 2025, and the LUIS portal will no longer be available starting October 31, 2025. It's recommended to migrate your LUIS applications to CLU to benefit from continued product support and multilingual capabilities, here are the [instructions](https://learn.microsoft.com/en-us/azure/ai-services/language-service/conversational-language-understanding/how-to/migrate-from-luis?tabs=luis-portal).

For now using `stealth-clu` for your bot:
- Switch your `Gemfile` to use `stealth-clu`, instead of `stealth-luis` and adjust configuration for your CLU project/endpoint in your `services.yml` file.
- Entity names remain mostly the same. Some entities are now handled differently in CLU. For example, `Calendar.Duration` from LUIS is now included under `datetimeV2` with subtype `duration`.


## Intents

We recommend you name your intents using snake case (`snake_case`). This is because this integration will automatically convert your intent names to Ruby symbols.

So for example, if you have a `handle_message` defined like this:

```ruby
handle_message(
  'Maybe' => proc { step_to state: :say_maybe },
  :yes => proc { step_to state: :say_yes },
  :no => proc { step_to state: :say_no }
)
```

If your user responds with a variation of the string `maybe`, then they will be taken to the state `say_maybe`.

Otherwise, the intent named `yes` and the intent named `no` will attempt to be matched. So if you had named your intent `YES` for example, you'd have to use `:YES` here which doesn't match Ruby syntax conventions.


## Entities

The entity types listed below are named using their corresponding Stealth type. The equivalent type used by Microsoft CLU is also listed. For each code sample, the sample query is first provided followed by the array of entities extracted from the queries (for the given type).

It's possible, and even likely, that a query matches more than one entity type. For example, a `currency` type will also match a `number` type.


### number

CLU prebuilt entity: `number`

```ruby
"I think it was something like 63 or maybe 764"

[
  63,
  764
]
"It was almost 15k"

[
  15000
]
```
For more info about these values, please reference the [number entity](https://learn.microsoft.com/en-us/azure/ai-services/language-service/named-entity-recognition/concepts/entity-resolutions#number)
 CLU documentation.


### currency

CLU prebuilt entity: `money`

```ruby
"send me $87 or 48 cents"

[
  { 'number' => 87, 'units' => 'Dollar' },
  { 'number' => 48, 'units': 'Cent' }
]
```

For more info about these values, please reference the [currency entity](https://learn.microsoft.com/en-us/azure/ai-services/language-service/named-entity-recognition/concepts/entity-resolutions#currency) CLU documentation.


### email

CLU prebuilt entity: `email`

```ruby
"you can contact me at john@email.none"

[
  "john@email.none"
]
```

For more info about these values, please reference the [email entity](https://learn.microsoft.com/en-us/azure/ai-services/language-service/conversational-language-understanding/prebuilt-component-reference) CLU documentation.


### phone

CLU prebuilt entity: `phonenumber`
Note: CLU does not parse nor attempts to clean up phone number.

```ruby
"You can reach me at 313-555-1212"

[
  "313-555-1212"
]
```

For more info about these values, please reference the [phonenumber entity](https://learn.microsoft.com/en-us/azure/ai-services/language-service/conversational-language-understanding/prebuilt-component-reference) CLU documentation.


### percentage

CLU prebuilt entity: `percentage`

```ruby
"The stock is up 8.9% today"

[
  8.9
]
```

For more info about these values, please reference the percentage entity CLU documentation.


### age
CLU prebuilt entity: `age`

```ruby
"81 years old"

[
  { 'number' => 81, 'units' => 'Year' }
]
```

For more info about these values, please reference the [age entity](https://learn.microsoft.com/en-us/azure/ai-services/language-service/named-entity-recognition/concepts/entity-resolutions#age) CLU documentation.


### url

CLU prebuilt entity: `url`

```ruby
"please visit google.com or https://google.com"

[
  "google.com",
  "https://google.com"
]
```

For more info about these values, please reference the [url entity](https://learn.microsoft.com/en-us/azure/ai-services/language-service/conversational-language-understanding/prebuilt-component-reference) CLU documentation.


### ordinal

CLU prebuilt entity: `ordinalV2`

```ruby
"they finished 2nd and 5th"

[
  { 'offset' => 2, 'relativeTo' => 'start' },
  { 'offset' => 5, 'relativeTo' => 'start' }
]
"she finished last"

[
  { 'offset' => 0, 'relativeTo' => 'end' }
]
```

For more info about these values, please reference the [ordinalV2 entity](https://learn.microsoft.com/en-us/azure/ai-services/language-service/named-entity-recognition/concepts/entity-resolutions#ordinal)) CLU documentation.


### geo

CLU prebuilt entity: `geographyV2`

```ruby
"She moved to paris, france"

[
  { 'value' => 'paris', 'type' => 'city' },
  { 'value' => 'france', 'type' => 'countryRegion' }
]
```

For more info about these values, please reference the [geographyV2 entity](https://learn.microsoft.com/en-us/azure/ai-services/language-service/conversational-language-understanding/prebuilt-component-reference) CLU documentation.


### dimension

CLU prebuilt entity: `dimension`

```ruby
"it's about 4 inches wide"

[
  { "number": 4, "units": "Inch" }
]
```

For more info about these values, please reference the [dimension entity](https://learn.microsoft.com/en-us/azure/ai-services/language-service/named-entity-recognition/concepts/entity-resolutions#dimensions) CLU documentation.


### temp

CLU prebuilt entity: `temperature`

```ruby
"it feels like 98 degrees"

[
  { 'number' => 98, 'units' => 'Degree' }
]
```

For more info about these values, please reference the [temperature entity](https://learn.microsoft.com/en-us/azure/ai-services/language-service/named-entity-recognition/concepts/entity-resolutions#temperature) CLU documentation.


### datetime

CLU prebuilt entity: `datetimeV2`

This one is the most complicated one to work with. The values are nested pretty deeply. This integration exposes the values at such a high level because there is a chance that LUIS will return results for more than one date type. For example, below we have just one result of type date, but CLU could return more than one object of subtype daterange, time, timerange, etc. See the docs for more info about these subtypes.
"tomorrow at 3pm"

```ruby
[
  {
    "category" => "datetimeV2",
    "text" => "tomorrow at 3pm",
    "offset" => 9,
    "length" => 15,
    "confidenceScore" => 1,
    "resolutions" => [
      {
        "resolutionKind" => "DateTimeResolution",
        "dateTimeSubKind" => "DateTime",
        "timex" => "2025-06-17T15",
        "value" => "2025-06-17 15:00:00"
      }
    ],
    "extraInformation" => [
      {
        "extraInformationKind" => "EntitySubtype",
        "value" => "datetime.datetime"
      }
    ]
  }
]
```

For more info about these values, please reference the [datetimeV2 entity](https://learn.microsoft.com/en-us/azure/ai-services/language-service/named-entity-recognition/concepts/entity-resolutions#datetime) CLU documentation.


### name

CLU prebuilt entity: `personName`

```ruby
"Little Cindy-Lou Who who was not more than two"

[
  "Little Cindy-Lou"
]
```

For more info about these values, please reference the [personName entity](https://learn.microsoft.com/en-us/azure/ai-services/language-service/conversational-language-understanding/prebuilt-component-reference) CLU documentation.

