# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::OpenAPI::ConditionalSchemaBuilder do
  let(:version_3_1_0) { GrapeSwagger::OpenAPI::Version.new('3.1.0') }
  let(:version_2_0) { GrapeSwagger::OpenAPI::Version.new('2.0') }

  describe '.build' do
    context 'OpenAPI 3.1.0' do
      context 'simple if/then schema' do
        it 'builds basic conditional schema' do
          schema = {
            type: 'object',
            properties: {
              payment_type: { type: 'string' }
            },
            if: {
              properties: {
                payment_type: { const: 'credit_card' }
              }
            },
            then: {
              properties: {
                card_number: { type: 'string' }
              },
              required: ['card_number']
            }
          }
          result = described_class.build(schema, version_3_1_0)

          expect(result[:type]).to eq('object')
          expect(result[:if]).to eq({
            properties: {
              payment_type: { const: 'credit_card' }
            }
          })
          expect(result[:then]).to eq({
            properties: {
              card_number: { type: 'string' }
            },
            required: ['card_number']
          })
          expect(result[:else]).to be_nil
        end

        it 'preserves properties alongside conditionals' do
          schema = {
            type: 'object',
            properties: {
              name: { type: 'string' },
              payment_type: { type: 'string' }
            },
            if: {
              properties: {
                payment_type: { const: 'card' }
              }
            },
            then: {
              properties: {
                card_number: { type: 'string' }
              }
            }
          }
          result = described_class.build(schema, version_3_1_0)

          expect(result[:properties]).to eq({
            name: { type: 'string' },
            payment_type: { type: 'string' }
          })
          expect(result[:if]).to be_present
          expect(result[:then]).to be_present
        end
      end

      context 'if/then/else schema' do
        it 'builds complete conditional with else branch' do
          schema = {
            type: 'object',
            properties: {
              payment_type: { type: 'string', enum: ['credit_card', 'bank_transfer'] }
            },
            if: {
              properties: {
                payment_type: { const: 'credit_card' }
              }
            },
            then: {
              properties: {
                card_number: { type: 'string' }
              },
              required: ['card_number']
            },
            else: {
              properties: {
                bank_account: { type: 'string' }
              },
              required: ['bank_account']
            }
          }
          result = described_class.build(schema, version_3_1_0)

          expect(result[:if]).to be_present
          expect(result[:then]).to be_present
          expect(result[:else]).to eq({
            properties: {
              bank_account: { type: 'string' }
            },
            required: ['bank_account']
          })
        end
      end

      context 'nested conditional schemas' do
        it 'handles nested conditionals in then branch' do
          schema = {
            type: 'object',
            properties: {
              type: { type: 'string' }
            },
            if: {
              properties: {
                type: { const: 'premium' }
              }
            },
            then: {
              properties: {
                tier: { type: 'string' }
              },
              if: {
                properties: {
                  tier: { const: 'gold' }
                }
              },
              then: {
                properties: {
                  bonus: { type: 'integer' }
                }
              }
            }
          }
          result = described_class.build(schema, version_3_1_0)

          expect(result[:then][:if]).to be_present
          expect(result[:then][:then]).to be_present
        end
      end

      context 'conditional based on enum value' do
        it 'uses const for single enum value in condition' do
          schema = {
            type: 'object',
            properties: {
              status: { type: 'string', enum: ['active', 'inactive', 'pending'] }
            },
            if: {
              properties: {
                status: { const: 'active' }
              }
            },
            then: {
              properties: {
                active_since: { type: 'string', format: 'date-time' }
              }
            }
          }
          result = described_class.build(schema, version_3_1_0)

          expect(result[:if][:properties][:status][:const]).to eq('active')
          expect(result[:then][:properties][:active_since]).to be_present
        end
      end

      context 'conditional with required properties' do
        it 'modifies required array in then/else' do
          schema = {
            type: 'object',
            properties: {
              has_address: { type: 'boolean' }
            },
            if: {
              properties: {
                has_address: { const: true }
              }
            },
            then: {
              properties: {
                street: { type: 'string' },
                city: { type: 'string' }
              },
              required: ['street', 'city']
            },
            else: {
              required: []
            }
          }
          result = described_class.build(schema, version_3_1_0)

          expect(result[:then][:required]).to eq(['street', 'city'])
          expect(result[:else][:required]).to eq([])
        end
      end

      context 'multiple conditions (allOf with ifs)' do
        it 'handles multiple separate conditionals via allOf' do
          schema = {
            allOf: [
              {
                if: {
                  properties: {
                    type: { const: 'A' }
                  }
                },
                then: {
                  properties: {
                    prop_a: { type: 'string' }
                  }
                }
              },
              {
                if: {
                  properties: {
                    type: { const: 'B' }
                  }
                },
                then: {
                  properties: {
                    prop_b: { type: 'integer' }
                  }
                }
              }
            ]
          }
          result = described_class.build(schema, version_3_1_0)

          expect(result[:allOf]).to be_an(Array)
          expect(result[:allOf][0][:if]).to be_present
          expect(result[:allOf][0][:then]).to be_present
          expect(result[:allOf][1][:if]).to be_present
          expect(result[:allOf][1][:then]).to be_present
        end
      end

      context 'without conditionals' do
        it 'returns schema unchanged if no conditional keywords present' do
          schema = {
            type: 'object',
            properties: {
              name: { type: 'string' }
            }
          }
          result = described_class.build(schema, version_3_1_0)

          expect(result).to eq(schema)
        end
      end

      context 'edge cases' do
        it 'handles only if without then or else' do
          schema = {
            type: 'object',
            if: {
              properties: {
                type: { const: 'special' }
              }
            }
          }
          result = described_class.build(schema, version_3_1_0)

          expect(result[:if]).to be_present
          expect(result[:then]).to be_nil
          expect(result[:else]).to be_nil
        end

        it 'handles empty schema' do
          schema = {}
          result = described_class.build(schema, version_3_1_0)

          expect(result).to eq({})
        end
      end
    end

    context 'Swagger 2.0' do
      it 'ignores conditionals for Swagger 2.0 (not supported)' do
        schema = {
          type: 'object',
          properties: {
            payment_type: { type: 'string' }
          },
          if: {
            properties: {
              payment_type: { const: 'credit_card' }
            }
          },
          then: {
            properties: {
              card_number: { type: 'string' }
            }
          }
        }
        result = described_class.build(schema, version_2_0)

        # For Swagger 2.0, conditionals should be stripped or moved to extensions
        expect(result[:if]).to be_nil
        expect(result[:then]).to be_nil
        expect(result[:type]).to eq('object')
        expect(result[:properties][:payment_type]).to eq({ type: 'string' })
      end

      it 'preserves all non-conditional properties for Swagger 2.0' do
        schema = {
          type: 'object',
          properties: {
            name: { type: 'string' },
            age: { type: 'integer' }
          },
          required: ['name'],
          if: {
            properties: {
              age: { minimum: 18 }
            }
          },
          then: {
            properties: {
              can_vote: { type: 'boolean' }
            }
          }
        }
        result = described_class.build(schema, version_2_0)

        expect(result[:type]).to eq('object')
        expect(result[:properties][:name]).to eq({ type: 'string' })
        expect(result[:properties][:age]).to eq({ type: 'integer' })
        expect(result[:required]).to eq(['name'])
        expect(result[:if]).to be_nil
        expect(result[:then]).to be_nil
      end
    end

    context 'immutability' do
      it 'does not mutate the original schema' do
        original_schema = {
          type: 'object',
          if: {
            properties: {
              type: { const: 'special' }
            }
          },
          then: {
            properties: {
              special_field: { type: 'string' }
            }
          }
        }
        schema = original_schema.dup
        described_class.build(schema, version_3_1_0)

        expect(original_schema[:type]).to eq('object')
        expect(original_schema[:if]).to be_present
      end
    end
  end
end
