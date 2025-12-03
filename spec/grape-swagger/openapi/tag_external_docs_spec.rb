# frozen_string_literal: true

require 'spec_helper'

describe 'Tag externalDocs (OpenAPI 3.1.0)' do
  # ============================================
  # externalDocs with camelCase key
  # ============================================
  describe 'with camelCase externalDocs' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Get pets', tags: ['pets']
        get '/pets' do
          []
        end

        desc 'Get users', tags: ['users']
        get '/users' do
          []
        end

        add_swagger_documentation(
          openapi_version: '3.1.0',
          tags: [
            {
              name: 'pets',
              description: 'Pet operations',
              externalDocs: {
                url: 'https://example.com/pet-docs',
                description: 'More info about pets'
              }
            }
          ]
        )
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes externalDocs in custom tag' do
      pets_tag = subject['tags'].find { |t| t['name'] == 'pets' }
      expect(pets_tag['externalDocs']).to be_a(Hash)
      expect(pets_tag['externalDocs']['url']).to eq('https://example.com/pet-docs')
      expect(pets_tag['externalDocs']['description']).to eq('More info about pets')
    end

    it 'auto-generated tags do not have externalDocs' do
      users_tag = subject['tags'].find { |t| t['name'] == 'users' }
      expect(users_tag).not_to have_key('externalDocs')
    end
  end

  # ============================================
  # externalDocs with snake_case key
  # ============================================
  describe 'with snake_case external_docs' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Get orders', tags: ['orders']
        get '/orders' do
          []
        end

        add_swagger_documentation(
          openapi_version: '3.1.0',
          tags: [
            {
              name: 'orders',
              description: 'Order management',
              external_docs: {
                url: 'https://docs.example.com/orders',
                description: 'Complete order documentation'
              }
            }
          ]
        )
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'converts snake_case external_docs to camelCase externalDocs' do
      orders_tag = subject['tags'].find { |t| t['name'] == 'orders' }
      expect(orders_tag['externalDocs']).to be_a(Hash)
      expect(orders_tag['externalDocs']['url']).to eq('https://docs.example.com/orders')
      expect(orders_tag['externalDocs']['description']).to eq('Complete order documentation')
    end
  end

  # ============================================
  # externalDocs with url only
  # ============================================
  describe 'with url only' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Get items', tags: ['items']
        get '/items' do
          []
        end

        add_swagger_documentation(
          openapi_version: '3.1.0',
          tags: [
            {
              name: 'items',
              description: 'Item operations',
              externalDocs: {
                url: 'https://wiki.example.com/items'
              }
            }
          ]
        )
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes externalDocs with url only' do
      items_tag = subject['tags'].find { |t| t['name'] == 'items' }
      expect(items_tag['externalDocs']['url']).to eq('https://wiki.example.com/items')
      expect(items_tag['externalDocs']).not_to have_key('description')
    end
  end

  # ============================================
  # Multiple tags with externalDocs
  # ============================================
  describe 'multiple tags with externalDocs' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Get products', tags: ['products']
        get '/products' do
          []
        end

        desc 'Get categories', tags: ['categories']
        get '/categories' do
          []
        end

        add_swagger_documentation(
          openapi_version: '3.1.0',
          tags: [
            {
              name: 'products',
              description: 'Product catalog',
              externalDocs: {
                url: 'https://docs.example.com/products',
                description: 'Product documentation'
              }
            },
            {
              name: 'categories',
              description: 'Category management',
              externalDocs: {
                url: 'https://docs.example.com/categories'
              }
            }
          ]
        )
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes externalDocs in all specified tags' do
      products_tag = subject['tags'].find { |t| t['name'] == 'products' }
      categories_tag = subject['tags'].find { |t| t['name'] == 'categories' }

      expect(products_tag['externalDocs']['url']).to eq('https://docs.example.com/products')
      expect(categories_tag['externalDocs']['url']).to eq('https://docs.example.com/categories')
    end
  end

  # ============================================
  # Swagger 2.0 compatibility
  # ============================================
  describe 'Swagger 2.0' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Get items', tags: ['items']
        get '/items' do
          []
        end

        add_swagger_documentation(
          tags: [
            {
              name: 'items',
              description: 'Item operations',
              externalDocs: {
                url: 'https://docs.example.com/items',
                description: 'Item docs'
              }
            }
          ]
        )
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes externalDocs in Swagger 2.0 as well' do
      items_tag = subject['tags'].find { |t| t['name'] == 'items' }
      expect(items_tag['externalDocs']['url']).to eq('https://docs.example.com/items')
    end
  end
end
