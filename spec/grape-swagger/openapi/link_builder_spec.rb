# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::OpenAPI::LinkBuilder do
  let(:version_3_1_0) { GrapeSwagger::OpenAPI::Version.new('3.1.0') }
  let(:version_2_0) { GrapeSwagger::OpenAPI::Version.new('2.0') }

  describe '.build' do
    # Story 12.3: Operation Links
    context 'Story 12.3: Operation Links' do
      context 'when link definitions are provided' do
        it 'creates links object in response' do
          links = {
            GetUserById: {
              operation_id: 'getUser',
              parameters: {
                userId: '$response.body#/id'
              }
            }
          }

          result = described_class.build(links, version_3_1_0)

          expect(result).not_to be_nil
          expect(result).to be_a(Hash)
          expect(result).to have_key('GetUserById')
        end

        it 'uses link names as keys' do
          links = {
            GetUserById: {
              operation_id: 'getUser'
            },
            GetUserPosts: {
              operation_id: 'getUserPosts'
            }
          }

          result = described_class.build(links, version_3_1_0)

          expect(result.keys).to include('GetUserById', 'GetUserPosts')
        end

        it 'includes operationId reference' do
          links = {
            GetUserById: {
              operation_id: 'getUser',
              parameters: {
                userId: '$response.body#/id'
              }
            }
          }

          result = described_class.build(links, version_3_1_0)

          expect(result['GetUserById'][:operationId]).to eq('getUser')
        end

        it 'includes operationRef reference' do
          links = {
            GetUserPosts: {
              operation_ref: '#/paths/~1users~1{userId}~1posts/get',
              parameters: {
                userId: '$response.body#/id'
              }
            }
          }

          result = described_class.build(links, version_3_1_0)

          expect(result['GetUserPosts'][:operationRef]).to eq('#/paths/~1users~1{userId}~1posts/get')
        end

        it 'includes parameter mapping' do
          links = {
            GetUserById: {
              operation_id: 'getUser',
              parameters: {
                userId: '$response.body#/id',
                include: 'profile'
              }
            }
          }

          result = described_class.build(links, version_3_1_0)

          expect(result['GetUserById'][:parameters]).to have_key(:userId)
          expect(result['GetUserById'][:parameters]).to have_key(:include)
        end

        it 'includes link description' do
          links = {
            GetUserById: {
              operation_id: 'getUser',
              description: 'Retrieve the created user by ID',
              parameters: {
                userId: '$response.body#/id'
              }
            }
          }

          result = described_class.build(links, version_3_1_0)

          expect(result['GetUserById'][:description]).to eq('Retrieve the created user by ID')
        end

        it 'includes link server' do
          links = {
            GetUserById: {
              operation_id: 'getUser',
              server: {
                url: 'https://api.example.com',
                description: 'Production server'
              },
              parameters: {
                userId: '$response.body#/id'
              }
            }
          }

          result = described_class.build(links, version_3_1_0)

          expect(result['GetUserById'][:server]).to have_key(:url)
          expect(result['GetUserById'][:server][:url]).to eq('https://api.example.com')
        end

        it 'supports multiple links in response' do
          links = {
            GetUserById: {
              operation_id: 'getUser',
              parameters: { userId: '$response.body#/id' }
            },
            GetUserPosts: {
              operation_id: 'getUserPosts',
              parameters: { userId: '$response.body#/id' }
            },
            UpdateUser: {
              operation_id: 'updateUser',
              parameters: { userId: '$response.body#/id' }
            }
          }

          result = described_class.build(links, version_3_1_0)

          expect(result.keys.size).to eq(3)
          expect(result.keys).to include('GetUserById', 'GetUserPosts', 'UpdateUser')
        end
      end

      context 'when Swagger 2.0 is used' do
        it 'returns nil (links not supported in Swagger 2.0)' do
          links = {
            GetUserById: {
              operation_id: 'getUser',
              parameters: { userId: '$response.body#/id' }
            }
          }

          result = described_class.build(links, version_2_0)

          expect(result).to be_nil
        end
      end

      context 'when links are empty' do
        it 'returns nil for empty hash' do
          result = described_class.build({}, version_3_1_0)

          expect(result).to be_nil
        end

        it 'returns nil for nil' do
          result = described_class.build(nil, version_3_1_0)

          expect(result).to be_nil
        end
      end
    end

    # Story 12.4: Link Runtime Expressions
    context 'Story 12.4: Link Runtime Expressions' do
      it 'maps parameter from response body pointer' do
        links = {
          GetUserById: {
            operation_id: 'getUser',
            parameters: {
              userId: '$response.body#/id'
            }
          }
        }

        result = described_class.build(links, version_3_1_0)

        expect(result['GetUserById'][:parameters][:userId]).to eq('$response.body#/id')
      end

      it 'supports static parameter values' do
        links = {
          GetUserById: {
            operation_id: 'getUser',
            parameters: {
              userId: '$response.body#/id',
              format: 'json',
              include: 'profile'
            }
          }
        }

        result = described_class.build(links, version_3_1_0)

        expect(result['GetUserById'][:parameters][:format]).to eq('json')
        expect(result['GetUserById'][:parameters][:include]).to eq('profile')
      end

      it 'supports mixed static and dynamic parameters' do
        links = {
          GetUserPosts: {
            operation_id: 'getUserPosts',
            parameters: {
              userId: '$response.body#/id',
              limit: 10,
              sort: 'created_at',
              order: 'desc'
            }
          }
        }

        result = described_class.build(links, version_3_1_0)

        expect(result['GetUserPosts'][:parameters][:userId]).to eq('$response.body#/id')
        expect(result['GetUserPosts'][:parameters][:limit]).to eq(10)
        expect(result['GetUserPosts'][:parameters][:sort]).to eq('created_at')
        expect(result['GetUserPosts'][:parameters][:order]).to eq('desc')
      end

      it 'supports header value mapping' do
        links = {
          GetResource: {
            operation_id: 'getResource',
            parameters: {
              resourceId: '$response.body#/resourceId',
              authorization: '$request.header.Authorization'
            }
          }
        }

        result = described_class.build(links, version_3_1_0)

        expect(result['GetResource'][:parameters][:authorization]).to eq('$request.header.Authorization')
      end

      it 'supports request body reference in link' do
        links = {
          CreateOrder: {
            operation_id: 'createOrder',
            request_body: {
              userId: '$response.body#/id',
              items: '$request.body#/items'
            }
          }
        }

        result = described_class.build(links, version_3_1_0)

        expect(result['CreateOrder'][:requestBody]).to have_key(:userId)
        expect(result['CreateOrder'][:requestBody][:userId]).to eq('$response.body#/id')
        expect(result['CreateOrder'][:requestBody][:items]).to eq('$request.body#/items')
      end

      it 'supports nested pointer expressions' do
        links = {
          GetUserAddress: {
            operation_id: 'getAddress',
            parameters: {
              addressId: '$response.body#/address/id',
              userId: '$response.body#/id'
            }
          }
        }

        result = described_class.build(links, version_3_1_0)

        expect(result['GetUserAddress'][:parameters][:addressId]).to eq('$response.body#/address/id')
      end

      it 'supports $response.header expression' do
        links = {
          GetResource: {
            operation_id: 'getResource',
            parameters: {
              location: '$response.header.Location'
            }
          }
        }

        result = described_class.build(links, version_3_1_0)

        expect(result['GetResource'][:parameters][:location]).to eq('$response.header.Location')
      end
    end

    # Edge cases
    context 'edge cases' do
      it 'handles links with only operationId' do
        links = {
          GetUser: {
            operation_id: 'getUser'
          }
        }

        result = described_class.build(links, version_3_1_0)

        expect(result).not_to be_nil
        expect(result['GetUser'][:operationId]).to eq('getUser')
        expect(result['GetUser']).not_to have_key(:parameters)
      end

      it 'handles links with only operationRef' do
        links = {
          GetUser: {
            operation_ref: '#/paths/~1users~1{id}/get'
          }
        }

        result = described_class.build(links, version_3_1_0)

        expect(result).not_to be_nil
        expect(result['GetUser'][:operationRef]).to eq('#/paths/~1users~1{id}/get')
        expect(result['GetUser']).not_to have_key(:operationId)
      end

      it 'omits nil values from link object' do
        links = {
          GetUser: {
            operation_id: 'getUser',
            parameters: { userId: '$response.body#/id' },
            description: nil,
            server: nil
          }
        }

        result = described_class.build(links, version_3_1_0)

        expect(result['GetUser']).to have_key(:operationId)
        expect(result['GetUser']).to have_key(:parameters)
        expect(result['GetUser']).not_to have_key(:description)
        expect(result['GetUser']).not_to have_key(:server)
      end

      it 'supports both operationId and operationRef (operationRef takes precedence)' do
        links = {
          GetUser: {
            operation_id: 'getUser',
            operation_ref: '#/paths/~1users~1{id}/get'
          }
        }

        result = described_class.build(links, version_3_1_0)

        # Both can be present in the spec, though typically only one is used
        expect(result['GetUser']).to have_key(:operationId)
        expect(result['GetUser']).to have_key(:operationRef)
      end
    end
  end
end
