# frozen_string_literal: true

module V1
  # Legacy API endpoints - demonstrates deprecation
  class LegacyAPI < Grape::API
    format :json
    prefix :api
    version 'v1', using: :path

    resource :legacy do
      desc 'Get items (deprecated)',
           summary: 'Legacy item listing - use /pets instead',
           detail: <<~DESC,
             **DEPRECATED**: This endpoint is deprecated and will be removed in v2.0.

             Please migrate to:
             - `GET /api/v1/pets` for pet listings
             - `GET /api/v1/orders` for order listings

             This endpoint will be sunset on 2025-06-01.
           DESC
           deprecated: true,
           is_array: true,
           success: {
             code: 200,
             examples: {
               'application/json' => [
                 { id: 1, name: 'Item 1', type: 'legacy' }
               ]
             }
           },
           tags: ['legacy']
      params do
        optional :limit, type: Integer, default: 10, desc: 'Number of items to return'
      end
      get 'items' do
        [
          { id: 1, name: 'Item 1', type: 'legacy', _deprecated_notice: 'Use /pets endpoint' },
          { id: 2, name: 'Item 2', type: 'legacy', _deprecated_notice: 'Use /pets endpoint' }
        ]
      end

      desc 'Get item by ID (deprecated)',
           summary: 'Legacy single item - use /pets/:id instead',
           deprecated: true,
           success: {
             code: 200,
             examples: {
               'application/json' => { id: 1, name: 'Item 1', type: 'legacy' }
             }
           },
           failure: [
             { code: 404, message: 'Item not found' }
           ],
           tags: ['legacy']
      params do
        requires :id, type: Integer, desc: 'Item ID'
      end
      get 'items/:id' do
        { id: params[:id], name: "Item #{params[:id]}", type: 'legacy' }
      end

      desc 'Search items (deprecated)',
           summary: 'Legacy search - use specific resource endpoints',
           detail: 'Use /pets, /users, or /orders with query parameters instead.',
           deprecated: true,
           is_array: true,
           success: { code: 200 },
           tags: ['legacy']
      params do
        requires :q, type: String, desc: 'Search query'
        optional :type, type: String, values: %w[pets users orders], desc: 'Resource type to search'
      end
      get 'search' do
        [{ id: 1, name: 'Search result', query: params[:q] }]
      end

      desc 'Batch update (deprecated)',
           summary: 'Legacy batch update - use individual PATCH endpoints',
           deprecated: true,
           success: { code: 200 },
           failure: [
             { code: 400, message: 'Invalid batch format' }
           ],
           tags: ['legacy']
      params do
        requires :updates, type: Array, desc: 'Array of updates' do
          requires :id, type: Integer
          requires :data, type: Hash
        end
      end
      patch 'batch' do
        { updated: params[:updates].length, status: 'completed' }
      end
    end
  end
end
