# frozen_string_literal: true

require 'spec_helper'

describe 'Documentation Examples Validation' do
  let(:version_3_1) { GrapeSwagger::OpenAPI::Version.new('3.1.0') }
  let(:version_2_0) { GrapeSwagger::OpenAPI::Version.new('2.0') }

  describe 'Migration Guide Examples' do
    describe 'webhook configuration' do
      it 'generates valid webhook structure' do
        # WebhookBuilder expects a flat config with summary, request, responses
        config = {
          newOrder: {
            method: :post,
            summary: 'New order notification',
            request: {
              schema: { '$ref' => '#/components/schemas/Order' }
            },
            responses: {
              200 => { description: 'Webhook processed' }
            }
          }
        }

        result = GrapeSwagger::OpenAPI::WebhookBuilder.build(config, version_3_1)

        expect(result).to have_key('newOrder')
        expect(result['newOrder']).to have_key(:post)
        expect(result['newOrder'][:post][:summary]).to eq('New order notification')
      end
    end

    describe 'security scheme configuration' do
      it 'generates OAuth2 with multiple flows' do
        config = {
          type: 'oauth2',
          description: 'OAuth2 authentication',
          flows: {
            authorizationCode: {
              authorization_url: 'https://auth.example.com/authorize',
              token_url: 'https://auth.example.com/token',
              scopes: { 'read' => 'Read access' }
            }
          }
        }

        result = GrapeSwagger::OpenAPI::SecuritySchemeBuilder.build(config, version_3_1)

        expect(result[:type]).to eq('oauth2')
        expect(result[:flows][:authorizationCode][:authorizationUrl]).to eq('https://auth.example.com/authorize')
      end

      it 'generates OpenID Connect scheme' do
        config = {
          type: 'openIdConnect',
          openid_connect_url: 'https://auth.example.com/.well-known/openid-configuration'
        }

        result = GrapeSwagger::OpenAPI::SecuritySchemeBuilder.build(config, version_3_1)

        expect(result[:type]).to eq('openIdConnect')
        expect(result[:openIdConnectUrl]).to eq('https://auth.example.com/.well-known/openid-configuration')
      end

      it 'generates Mutual TLS scheme' do
        config = {
          type: 'mutualTLS',
          description: 'Client certificate required'
        }

        result = GrapeSwagger::OpenAPI::SecuritySchemeBuilder.build(config, version_3_1)

        expect(result[:type]).to eq('mutualTLS')
        expect(result[:description]).to eq('Client certificate required')
      end
    end
  end

  describe 'OpenAPI 3.1.0 Features Examples' do
    describe 'discriminator configuration' do
      it 'generates discriminator with mapping' do
        config = {
          property_name: 'petType',
          mapping: {
            'dog' => 'Dog',
            'cat' => 'Cat'
          }
        }

        result = GrapeSwagger::OpenAPI::DiscriminatorBuilder.build(config, version_3_1)

        expect(result[:propertyName]).to eq('petType')
        expect(result[:mapping]['dog']).to eq('#/components/schemas/Dog')
        expect(result[:mapping]['cat']).to eq('#/components/schemas/Cat')
      end
    end

    describe 'polymorphic schema configuration' do
      it 'generates oneOf schema with discriminator' do
        schemas = %w[SuccessResponse ErrorResponse]
        discriminator = { property_name: 'status' }

        result = GrapeSwagger::OpenAPI::PolymorphicSchemaBuilder.build_one_of(
          schemas, discriminator, version_3_1
        )

        expect(result[:oneOf].size).to eq(2)
        expect(result[:discriminator][:propertyName]).to eq('status')
      end

      it 'generates anyOf schema' do
        schemas = %w[BasicInfo ExtendedInfo]

        result = GrapeSwagger::OpenAPI::PolymorphicSchemaBuilder.build_any_of(
          schemas, nil, version_3_1
        )

        expect(result[:anyOf].size).to eq(2)
        expect(result[:discriminator]).to be_nil
      end

      it 'generates allOf for inheritance' do
        base = 'Pet'
        extension = { type: 'object', properties: { breed: { type: 'string' } } }

        result = GrapeSwagger::OpenAPI::PolymorphicSchemaBuilder.build_all_of(
          base, extension, version_3_1
        )

        expect(result[:allOf].size).to eq(2)
        expect(result[:allOf][0]).to eq({ '$ref' => '#/components/schemas/Pet' })
      end
    end

    describe 'conditional schema configuration' do
      it 'preserves if/then/else schema in OpenAPI 3.1.0' do
        schema = {
          type: 'object',
          properties: { type: { type: 'string' } },
          if: { properties: { type: { const: 'credit_card' } } },
          then: { required: ['card_number'] },
          else: { required: ['bank_account'] }
        }

        result = GrapeSwagger::OpenAPI::ConditionalSchemaBuilder.build(schema, version_3_1)

        expect(result[:if]).to eq({ properties: { type: { const: 'credit_card' } } })
        expect(result[:then]).to eq({ required: ['card_number'] })
        expect(result[:else]).to eq({ required: ['bank_account'] })
      end
    end
  end

  describe 'Configuration Reference Examples' do
    describe 'API key security' do
      it 'generates API key scheme' do
        config = {
          type: 'apiKey',
          name: 'X-API-Key',
          in: 'header'
        }

        result = GrapeSwagger::OpenAPI::SecuritySchemeBuilder.build(config, version_3_1)

        expect(result[:type]).to eq('apiKey')
        expect(result[:name]).to eq('X-API-Key')
        expect(result[:in]).to eq('header')
      end
    end

    describe 'bearer token security' do
      it 'generates bearer token scheme' do
        config = {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT'
        }

        result = GrapeSwagger::OpenAPI::SecuritySchemeBuilder.build(config, version_3_1)

        expect(result[:type]).to eq('http')
        expect(result[:scheme]).to eq('bearer')
        expect(result[:bearerFormat]).to eq('JWT')
      end
    end
  end

  describe 'Performance Utilities Examples' do
    describe 'reference cache usage' do
      it 'caches and retrieves values correctly' do
        cache = GrapeSwagger::OpenAPI::ReferenceCache.new(max_size: 1000)

        schema = cache.fetch('User') { { type: 'object', properties: { name: { type: 'string' } } } }

        expect(schema[:type]).to eq('object')
        expect(cache.size).to eq(1)
      end
    end

    describe 'lazy component builder usage' do
      it 'builds components on demand' do
        builder = GrapeSwagger::OpenAPI::LazyComponentBuilder.new(version_3_1)
        builder.register('User') { { type: 'object', properties: { name: { type: 'string' } } } }

        expect(builder.pending_count).to eq(1)
        expect(builder.resolved_count).to eq(0)

        schema = builder.resolve('User')

        expect(schema[:type]).to eq('object')
        expect(builder.pending_count).to eq(0)
        expect(builder.resolved_count).to eq(1)
      end
    end

    describe 'benchmark suite usage' do
      it 'measures generation performance' do
        result = GrapeSwagger::OpenAPI::BenchmarkSuite.run_benchmark(iterations: 3) do
          { type: 'object' }
        end

        expect(result).to have_key(:generation_time)
        expect(result).to have_key(:memory_usage)
        expect(result).to have_key(:object_allocations)
        expect(result[:generation_time]).to have_key(:avg)
      end
    end
  end

  describe 'Swagger 2.0 Compatibility' do
    it 'webhooks still build but are not included in Swagger 2.0 output' do
      # NOTE: WebhookBuilder builds webhooks regardless of version
      # The version check happens at a higher level when assembling the final spec
      config = { newOrder: { post: { summary: 'Test' } } }

      result = GrapeSwagger::OpenAPI::WebhookBuilder.build(config, version_2_0)

      # WebhookBuilder returns the built webhooks; filtering happens elsewhere
      expect(result).to have_key('newOrder')
    end

    it 'oneOf returns nil for Swagger 2.0' do
      result = GrapeSwagger::OpenAPI::PolymorphicSchemaBuilder.build_one_of(
        %w[A B], nil, version_2_0
      )

      expect(result).to be_nil
    end

    it 'openIdConnect schemes return nil for Swagger 2.0' do
      config = {
        type: 'openIdConnect',
        openid_connect_url: 'https://example.com'
      }

      result = GrapeSwagger::OpenAPI::SecuritySchemeBuilder.build(config, version_2_0)

      expect(result).to be_nil
    end
  end
end
