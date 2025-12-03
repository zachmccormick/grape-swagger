# frozen_string_literal: true

module V1
  # Demonstrates OpenAPI 3.1.0 request body and response features
  class RequestResponseDemoAPI < Grape::API
    format :json
    prefix :api
    version 'v1', using: :path

    resource :requests do
      # ============================================
      # Request Body with Description
      # ============================================
      desc 'Demonstrates request body with description',
           summary: 'Create resource with documented request body',
           detail: <<~DESC,
             This endpoint demonstrates the `description` field in Request Body Object.
             The request body description provides context about:
             - What the body should contain
             - Required vs optional fields
             - Validation rules
           DESC
           consumes: ['application/json'],
           success: { code: 201, message: 'Resource created' },
           failure: [{ code: 400, message: 'Invalid request body' }],
           tags: ['requests']
      params do
        requires :resource, type: Hash, documentation: {
          desc: 'Resource object to create. All fields are validated server-side.',
          param_type: 'body'
        } do
          requires :name, type: String, desc: 'Resource name (3-100 characters)'
          requires :type, type: String, values: %w[basic premium enterprise], desc: 'Resource tier'
          optional :metadata, type: Hash, desc: 'Additional key-value metadata'
          optional :tags, type: Array[String], desc: 'Tags for categorization'
        end
      end
      post 'with-description' do
        {
          id: rand(1000..9999),
          name: params[:resource][:name],
          type: params[:resource][:type],
          metadata: params[:resource][:metadata] || {},
          tags: params[:resource][:tags] || [],
          created_at: Time.now
        }
      end

      # ============================================
      # Encoding Object - Full Demo
      # ============================================
      desc 'Demonstrates full Encoding Object fields',
           summary: 'Upload with encoding options',
           detail: <<~DESC,
             This endpoint demonstrates ALL Encoding Object fields:

             - **contentType**: MIME type for the field
             - **headers**: Custom headers for the field (e.g., Content-Disposition)
             - **style**: How the value is serialized (form, spaceDelimited, etc.)
             - **explode**: Whether arrays/objects are exploded
             - **allowReserved**: Allow reserved characters in values
           DESC
           consumes: ['multipart/form-data'],
           success: { code: 201, message: 'Upload successful' },
           failure: [{ code: 413, message: 'File too large' }],
           tags: ['requests']
      params do
        requires :document, type: File, documentation: {
          desc: 'Document file (PDF, DOC, DOCX)',
          encoding: {
            contentType: 'application/pdf, application/msword, application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            headers: {
              'X-Custom-Header' => {
                description: 'Custom header for the document part',
                schema: { type: 'string' }
              }
            }
          }
        }
        optional :categories, type: Array[String], documentation: {
          desc: 'Categories for the document',
          encoding: {
            style: 'form',
            explode: true
          }
        }
        optional :path_reference, type: String, documentation: {
          desc: 'Path reference that may contain reserved characters',
          encoding: {
            allowReserved: true
          }
        }
      end
      post 'with-encoding' do
        {
          document_id: "doc_#{SecureRandom.hex(8)}",
          filename: params[:document][:filename],
          size: params[:document][:tempfile].size,
          categories: params[:categories] || [],
          path_reference: params[:path_reference],
          uploaded_at: Time.now
        }
      end

      # ============================================
      # Reusable Request Body Reference Demo
      # ============================================
      desc 'Demonstrates using a reusable request body via $ref',
           summary: 'Bulk update using reusable request body',
           detail: <<~DESC,
             This endpoint references a reusable request body defined in components:

             ```yaml
             requestBody:
               $ref: '#/components/requestBodies/BulkUpdateBody'
             ```

             Benefits:
             - Consistent request body schema across multiple endpoints
             - Single place to update documentation
             - Reduced spec file size
           DESC
           consumes: ['application/json'],
           request_body: { '$ref' => API.request_body_ref(:BulkUpdateBody) },
           success: { code: 200, message: 'Bulk update completed' },
           failure: [
             { code: 400, message: 'Invalid request body' },
             { code: 413, message: 'Too many items in bulk update' }
           ],
           tags: ['requests']
      params do
        requires :ids, type: Array[Integer], documentation: { desc: 'IDs of items to update' }
        requires :updates, type: Hash, documentation: { desc: 'Fields to update' }
      end
      put 'bulk-update' do
        {
          updated_count: params[:ids].length,
          ids: params[:ids],
          updates_applied: params[:updates],
          completed_at: Time.now
        }
      end
    end

    resource :responses do
      # ============================================
      # Response Headers with serialization fields
      # ============================================
      desc 'Demonstrates response headers with OpenAPI 3.1.0 serialization',
           summary: 'Get data with rich response headers',
           detail: <<~DESC,
             This endpoint demonstrates various OpenAPI 3.1.0 Header Object features:
             - `style` and `explode` for array serialization
             - `examples` for multiple header value examples
             - `allowReserved` for path-like values
           DESC
           success: {
             code: 200,
             message: 'Data with headers',
             headers: {
               'X-Rate-Limit-Remaining' => {
                 description: 'Number of requests remaining in the current rate limit window',
                 type: 'integer',
                 examples: {
                   high: { summary: 'Plenty of requests left', value: 950 },
                   low: { summary: 'Running low', value: 10 },
                   depleted: { summary: 'Rate limit reached', value: 0 }
                 }
               },
               'X-Request-Tags' => {
                 description: 'Tags associated with this request (array)',
                 type: 'array',
                 items: { type: 'string' },
                 explode: false
               },
               'X-Resource-Path' => {
                 description: 'Path to the resource (may contain reserved characters)',
                 type: 'string',
                 allowReserved: true
               }
             }
           },
           failure: [{ code: 429, message: 'Rate limit exceeded' }],
           tags: ['responses']
      params do
        requires :id, type: Integer, desc: 'Resource ID'
      end
      get 'with-headers/:id' do
        {
          id: params[:id],
          data: { key: 'value' },
          path: "/resources/#{params[:id]}/details"
        }
      end

      # ============================================
      # Response with examples
      # ============================================
      desc 'Demonstrates response with multiple examples',
           summary: 'Get resource with example responses',
           detail: 'This endpoint shows how to document multiple response examples.',
           success: {
             code: 200,
             message: 'Resource retrieved',
             examples: {
               simple: {
                 summary: 'Simple resource',
                 value: { id: 1, name: 'Simple', status: 'active' }
               },
               complex: {
                 summary: 'Complex resource with metadata',
                 value: {
                   id: 42,
                   name: 'Complex Resource',
                   status: 'active',
                   metadata: { created_by: 'admin', priority: 'high' },
                   tags: %w[important featured]
                 }
               }
             }
           },
           failure: [
             {
               code: 404,
               message: 'Resource not found',
               examples: {
                 not_found: {
                   summary: 'Standard not found error',
                   value: { error: 'not_found', message: 'Resource with given ID does not exist' }
                 }
               }
             }
           ],
           tags: ['responses']
      params do
        requires :id, type: Integer, desc: 'Resource ID'
      end
      get 'with-examples/:id' do
        { id: params[:id], name: 'Sample Resource', status: 'active' }
      end

      # ============================================
      # Media Type specific responses
      # ============================================
      desc 'Demonstrates content-type specific responses',
           summary: 'Get data in multiple formats',
           detail: 'This endpoint can return JSON or XML based on Accept header.',
           produces: ['application/json', 'application/xml'],
           success: { code: 200, message: 'Data in requested format' },
           tags: ['responses']
      params do
        requires :id, type: Integer, desc: 'Record ID'
      end
      get 'multi-format/:id' do
        data = { id: params[:id], name: 'Record', value: 42 }

        if request.accept.include?('application/xml')
          content_type 'application/xml'
          data.to_xml(root: 'record')
        else
          data
        end
      end
    end
  end
end
