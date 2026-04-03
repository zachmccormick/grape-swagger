# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::OpenAPI::DependentSchemaHandler do
  let(:version_3_1_0) { GrapeSwagger::OpenAPI::Version.new('3.1.0') }
  let(:version_2_0) { GrapeSwagger::OpenAPI::Version.new('2.0') }

  describe '.transform' do
    context 'OpenAPI 3.1.0' do
      context 'dependentSchemas with single dependency' do
        it 'converts legacy dependencies hash to dependentSchemas' do
          schema = {
            type: 'object',
            properties: {
              name: { type: 'string' },
              phone: { type: 'string' }
            },
            dependencies: {
              phone: {
                properties: {
                  phone_type: { type: 'string', enum: %w[mobile landline] }
                },
                required: ['phone_type']
              }
            }
          }
          result = described_class.transform(schema, version_3_1_0)

          expect(result[:dependentSchemas]).to eq({
            phone: {
              properties: {
                phone_type: { type: 'string', enum: %w[mobile landline] }
              },
              required: ['phone_type']
            }
          })
          expect(result[:dependencies]).to be_nil
        end

        it 'handles direct dependentSchemas (no conversion needed)' do
          schema = {
            type: 'object',
            properties: {
              credit_card: { type: 'string' }
            },
            dependentSchemas: {
              credit_card: {
                properties: {
                  billing_address: { type: 'string' }
                },
                required: ['billing_address']
              }
            }
          }
          result = described_class.transform(schema, version_3_1_0)

          expect(result[:dependentSchemas]).to eq({
            credit_card: {
              properties: {
                billing_address: { type: 'string' }
              },
              required: ['billing_address']
            }
          })
        end
      end

      context 'dependentSchemas with multiple dependencies' do
        it 'converts multiple dependencies' do
          schema = {
            type: 'object',
            properties: {
              phone: { type: 'string' },
              email: { type: 'string' }
            },
            dependencies: {
              phone: {
                properties: {
                  phone_type: { type: 'string' }
                }
              },
              email: {
                properties: {
                  email_verified: { type: 'boolean' }
                }
              }
            }
          }
          result = described_class.transform(schema, version_3_1_0)

          expect(result[:dependentSchemas][:phone]).to be_present
          expect(result[:dependentSchemas][:email]).to be_present
          expect(result[:dependencies]).to be_nil
        end
      end

      context 'dependentRequired for conditional required' do
        it 'converts array dependencies to dependentRequired' do
          schema = {
            type: 'object',
            properties: {
              name: { type: 'string' },
              email: { type: 'string' },
              phone: { type: 'string' }
            },
            dependencies: {
              email: ['name'],
              phone: %w[name email]
            }
          }
          result = described_class.transform(schema, version_3_1_0)

          expect(result[:dependentRequired]).to eq({
            email: ['name'],
            phone: %w[name email]
          })
          expect(result[:dependencies]).to be_nil
        end

        it 'handles direct dependentRequired (no conversion needed)' do
          schema = {
            type: 'object',
            properties: {
              email: { type: 'string' },
              name: { type: 'string' }
            },
            dependentRequired: {
              email: ['name']
            }
          }
          result = described_class.transform(schema, version_3_1_0)

          expect(result[:dependentRequired]).to eq({
            email: ['name']
          })
        end
      end

      context 'nested dependent schemas' do
        it 'handles nested object dependencies' do
          schema = {
            type: 'object',
            properties: {
              shipping: { type: 'object' }
            },
            dependencies: {
              shipping: {
                properties: {
                  tracking: {
                    type: 'object',
                    properties: {
                      number: { type: 'string' },
                      carrier: { type: 'string' }
                    },
                    dependencies: {
                      number: ['carrier']
                    }
                  }
                }
              }
            }
          }
          result = described_class.transform(schema, version_3_1_0)

          expect(result[:dependentSchemas][:shipping]).to be_present
          nested_tracking = result[:dependentSchemas][:shipping][:properties][:tracking]
          expect(nested_tracking[:dependentRequired]).to eq({
            number: ['carrier']
          })
        end
      end

      context 'mixed array and schema dependencies' do
        it 'splits dependencies into dependentRequired and dependentSchemas' do
          schema = {
            type: 'object',
            properties: {
              email: { type: 'string' },
              name: { type: 'string' },
              credit_card: { type: 'string' }
            },
            dependencies: {
              email: ['name'],
              credit_card: {
                properties: {
                  billing_address: { type: 'string' }
                },
                required: ['billing_address']
              }
            }
          }
          result = described_class.transform(schema, version_3_1_0)

          expect(result[:dependentRequired]).to eq({
            email: ['name']
          })
          expect(result[:dependentSchemas]).to eq({
            credit_card: {
              properties: {
                billing_address: { type: 'string' }
              },
              required: ['billing_address']
            }
          })
          expect(result[:dependencies]).to be_nil
        end
      end

      context 'circular dependency detection' do
        it 'preserves circular dependencies without infinite loop' do
          schema = {
            type: 'object',
            properties: {
              a: { type: 'string' },
              b: { type: 'string' }
            },
            dependencies: {
              a: ['b'],
              b: ['a']
            }
          }
          result = described_class.transform(schema, version_3_1_0)

          expect(result[:dependentRequired]).to eq({
            a: ['b'],
            b: ['a']
          })
        end
      end

      context 'without dependencies' do
        it 'returns schema unchanged if no dependencies' do
          schema = {
            type: 'object',
            properties: {
              name: { type: 'string' }
            }
          }
          result = described_class.transform(schema, version_3_1_0)

          expect(result).to eq(schema)
        end
      end

      context 'edge cases' do
        it 'handles empty dependencies object' do
          schema = {
            type: 'object',
            dependencies: {}
          }
          result = described_class.transform(schema, version_3_1_0)

          expect(result[:dependencies]).to be_nil
          expect(result[:dependentSchemas]).to be_nil
          expect(result[:dependentRequired]).to be_nil
        end

        it 'handles empty schema' do
          schema = {}
          result = described_class.transform(schema, version_3_1_0)

          expect(result).to eq({})
        end
      end
    end

    context 'Swagger 2.0' do
      it 'uses x-dependentSchemas extension for Swagger 2.0' do
        schema = {
          type: 'object',
          properties: {
            phone: { type: 'string' }
          },
          dependencies: {
            phone: {
              properties: {
                phone_type: { type: 'string' }
              }
            }
          }
        }
        result = described_class.transform(schema, version_2_0)

        # For Swagger 2.0, preserve dependencies or use extension
        expect(result[:dependencies]).to be_present
      end

      it 'preserves array dependencies for Swagger 2.0' do
        schema = {
          type: 'object',
          properties: {
            email: { type: 'string' },
            name: { type: 'string' }
          },
          dependencies: {
            email: ['name']
          }
        }
        result = described_class.transform(schema, version_2_0)

        expect(result[:dependencies]).to eq({
          email: ['name']
        })
      end
    end

    context 'immutability' do
      it 'does not mutate the original schema' do
        original_schema = {
          type: 'object',
          dependencies: {
            email: ['name']
          }
        }
        schema = original_schema.dup
        described_class.transform(schema, version_3_1_0)

        expect(original_schema[:dependencies]).to be_present
      end
    end
  end
end
