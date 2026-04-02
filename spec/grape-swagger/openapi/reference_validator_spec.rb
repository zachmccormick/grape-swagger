# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GrapeSwagger::OpenAPI::ReferenceValidator do
  describe '.validate' do
    context 'with valid internal references' do
      it 'validates all references exist in schemas' do
        spec = {
          'components' => {
            'schemas' => {
              'User' => {
                'type' => 'object',
                'properties' => {
                  'profile' => { '$ref' => '#/components/schemas/Profile' }
                }
              },
              'Profile' => {
                'type' => 'object',
                'properties' => { 'name' => { 'type' => 'string' } }
              }
            }
          }
        }
        result = described_class.validate(spec)
        expect(result[:valid]).to be true
        expect(result[:errors]).to be_empty
      end

      it 'validates references in paths' do
        spec = {
          'paths' => {
            '/users' => {
              'get' => {
                'responses' => {
                  '200' => {
                    'content' => {
                      'application/json' => {
                        'schema' => { '$ref' => '#/components/schemas/User' }
                      }
                    }
                  }
                }
              }
            }
          },
          'components' => {
            'schemas' => {
              'User' => { 'type' => 'object' }
            }
          }
        }
        result = described_class.validate(spec)
        expect(result[:valid]).to be true
        expect(result[:errors]).to be_empty
      end
    end

    context 'with missing references' do
      it 'detects missing schema reference' do
        spec = {
          'components' => {
            'schemas' => {
              'User' => {
                'type' => 'object',
                'properties' => {
                  'profile' => { '$ref' => '#/components/schemas/Profile' }
                }
              }
            }
          }
        }
        result = described_class.validate(spec)
        expect(result[:valid]).to be false
        expect(result[:errors]).to include(match(/Profile.*not found/i))
      end

      it 'detects multiple missing references' do
        spec = {
          'components' => {
            'schemas' => {
              'User' => {
                'type' => 'object',
                'properties' => {
                  'profile' => { '$ref' => '#/components/schemas/Profile' },
                  'account' => { '$ref' => '#/components/schemas/Account' }
                }
              }
            }
          }
        }
        result = described_class.validate(spec)
        expect(result[:valid]).to be false
        expect(result[:errors].size).to eq(2)
      end
    end

    context 'with circular references' do
      it 'detects simple circular reference' do
        spec = {
          'components' => {
            'schemas' => {
              'Node' => {
                'type' => 'object',
                'properties' => {
                  'next' => { '$ref' => '#/components/schemas/Node' }
                }
              }
            }
          }
        }
        result = described_class.validate(spec, detect_circular: true)
        expect(result[:warnings]).to include(match(/circular reference.*Node/i))
      end

      it 'detects complex circular reference chain' do
        spec = {
          'components' => {
            'schemas' => {
              'A' => {
                'type' => 'object',
                'properties' => {
                  'b' => { '$ref' => '#/components/schemas/B' }
                }
              },
              'B' => {
                'type' => 'object',
                'properties' => {
                  'c' => { '$ref' => '#/components/schemas/C' }
                }
              },
              'C' => {
                'type' => 'object',
                'properties' => {
                  'a' => { '$ref' => '#/components/schemas/A' }
                }
              }
            }
          }
        }
        result = described_class.validate(spec, detect_circular: true)
        expect(result[:warnings]).not_to be_empty
      end

      it 'does not flag self-references as error when allowed' do
        spec = {
          'components' => {
            'schemas' => {
              'Tree' => {
                'type' => 'object',
                'properties' => {
                  'children' => {
                    'type' => 'array',
                    'items' => { '$ref' => '#/components/schemas/Tree' }
                  }
                }
              }
            }
          }
        }
        result = described_class.validate(spec, allow_self_reference: true)
        expect(result[:valid]).to be true
      end
    end

    context 'with deprecated reference styles' do
      it 'warns about Swagger 2.0 style references in OpenAPI 3.1.0 spec' do
        spec = {
          'openapi' => '3.1.0',
          'components' => {
            'schemas' => {
              'User' => {
                'type' => 'object',
                'properties' => {
                  'profile' => { '$ref' => '#/definitions/Profile' }
                }
              },
              'Profile' => { 'type' => 'object' }
            }
          }
        }
        result = described_class.validate(spec)
        expect(result[:warnings]).to include(match(/deprecated.*#\/definitions/i))
      end

      it 'does not warn about correct OpenAPI 3.1.0 references' do
        spec = {
          'openapi' => '3.1.0',
          'components' => {
            'schemas' => {
              'User' => {
                'type' => 'object',
                'properties' => {
                  'profile' => { '$ref' => '#/components/schemas/Profile' }
                }
              },
              'Profile' => { 'type' => 'object' }
            }
          }
        }
        result = described_class.validate(spec)
        expect(result[:warnings]).to be_empty
      end
    end

    context 'with external references' do
      it 'skips validation for external file references' do
        spec = {
          'components' => {
            'schemas' => {
              'User' => {
                'type' => 'object',
                'properties' => {
                  'profile' => { '$ref' => 'external.json#/components/schemas/Profile' }
                }
              }
            }
          }
        }
        result = described_class.validate(spec)
        expect(result[:valid]).to be true
        expect(result[:warnings]).to include(match(/external reference.*external.json/i))
      end

      it 'skips validation for URL references' do
        spec = {
          'components' => {
            'schemas' => {
              'User' => {
                'type' => 'object',
                'properties' => {
                  'profile' => { '$ref' => 'https://example.com/schemas.json#/User' }
                }
              }
            }
          }
        }
        result = described_class.validate(spec)
        expect(result[:valid]).to be true
      end
    end

    context 'with validation options' do
      it 'can disable circular reference detection' do
        spec = {
          'components' => {
            'schemas' => {
              'Node' => {
                'type' => 'object',
                'properties' => {
                  'next' => { '$ref' => '#/components/schemas/Node' }
                }
              }
            }
          }
        }
        result = described_class.validate(spec, detect_circular: false)
        expect(result[:warnings]).to be_empty
      end

      it 'can enable strict validation mode' do
        spec = {
          'components' => {
            'schemas' => {
              'User' => {
                'type' => 'object',
                'properties' => {
                  'profile' => { '$ref' => 'external.json#/components/schemas/Profile' }
                }
              }
            }
          }
        }
        result = described_class.validate(spec, strict: true)
        expect(result[:valid]).to be false
        expect(result[:errors]).to include(match(/external reference.*not allowed/i))
      end

      it 'provides helpful error messages' do
        spec = {
          'components' => {
            'schemas' => {
              'User' => {
                'type' => 'object',
                'properties' => {
                  'profile' => { '$ref' => '#/components/schemas/Profile' }
                }
              }
            }
          }
        }
        result = described_class.validate(spec)
        expect(result[:errors].first).to match(/Profile/)
        expect(result[:errors].first).to match(/User/)
        expect(result[:errors].first).to match(/profile/)
      end
    end

    context 'with complex specs' do
      it 'validates references in request bodies' do
        spec = {
          'paths' => {
            '/users' => {
              'post' => {
                'requestBody' => {
                  'content' => {
                    'application/json' => {
                      'schema' => { '$ref' => '#/components/schemas/User' }
                    }
                  }
                }
              }
            }
          },
          'components' => {
            'schemas' => {
              'User' => { 'type' => 'object' }
            }
          }
        }
        result = described_class.validate(spec)
        expect(result[:valid]).to be true
      end

      it 'validates references in parameters' do
        spec = {
          'paths' => {
            '/users/{id}' => {
              'parameters' => [
                { '$ref' => '#/components/parameters/UserId' }
              ]
            }
          },
          'components' => {
            'parameters' => {
              'UserId' => {
                'name' => 'id',
                'in' => 'path',
                'schema' => { 'type' => 'string' }
              }
            }
          }
        }
        result = described_class.validate(spec)
        expect(result[:valid]).to be true
      end

      it 'validates references in responses' do
        spec = {
          'paths' => {
            '/users' => {
              'get' => {
                'responses' => {
                  '404' => { '$ref' => '#/components/responses/NotFound' }
                }
              }
            }
          },
          'components' => {
            'responses' => {
              'NotFound' => {
                'description' => 'Not found'
              }
            }
          }
        }
        result = described_class.validate(spec)
        expect(result[:valid]).to be true
      end
    end
  end

  describe '.extract_references' do
    it 'extracts all references from a spec' do
      spec = {
        'components' => {
          'schemas' => {
            'User' => {
              'properties' => {
                'profile' => { '$ref' => '#/components/schemas/Profile' },
                'account' => { '$ref' => '#/components/schemas/Account' }
              }
            }
          }
        }
      }
      refs = described_class.extract_references(spec)
      expect(refs).to include('#/components/schemas/Profile')
      expect(refs).to include('#/components/schemas/Account')
    end

    it 'extracts references from nested structures' do
      spec = {
        'components' => {
          'schemas' => {
            'User' => {
              'allOf' => [
                { '$ref' => '#/components/schemas/Base' },
                {
                  'properties' => {
                    'items' => {
                      'type' => 'array',
                      'items' => { '$ref' => '#/components/schemas/Item' }
                    }
                  }
                }
              ]
            }
          }
        }
      }
      refs = described_class.extract_references(spec)
      expect(refs).to include('#/components/schemas/Base')
      expect(refs).to include('#/components/schemas/Item')
    end

    it 'returns unique references only' do
      spec = {
        'components' => {
          'schemas' => {
            'User' => {
              'properties' => {
                'home' => { '$ref' => '#/components/schemas/Address' },
                'work' => { '$ref' => '#/components/schemas/Address' }
              }
            }
          }
        }
      }
      refs = described_class.extract_references(spec)
      expect(refs.count('#/components/schemas/Address')).to eq(1)
    end
  end
end
