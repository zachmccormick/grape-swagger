# frozen_string_literal: true

module V1
  class FilesAPI < Grape::API
    format :json
    prefix :api
    version 'v1', using: :path

    resource :files do
      desc 'List uploaded files',
           is_array: true,
           success: { model: Entities::FileMetadata },
           failure: [{ code: 401, message: 'Unauthorized' }],
           tags: ['files']
      params do
        optional :content_type, type: String, desc: 'Filter by MIME type'
        optional :limit, type: Integer, default: 20
      end
      get do
        files = [
          {
            id: 1, filename: 'document.pdf', content_type: 'application/pdf',
            size_bytes: 102_400, download_url: '/api/v1/files/1/download',
            uploaded_at: Time.now
          },
          {
            id: 2, filename: 'image.png', content_type: 'image/png',
            size_bytes: 51_200, download_url: '/api/v1/files/2/download',
            uploaded_at: Time.now
          }
        ]
        present files, with: Entities::FileMetadata
      end

      desc 'Get file metadata',
           success: { model: Entities::FileMetadata },
           failure: [
             { code: 404, message: 'File not found' },
             { code: 401, message: 'Unauthorized' }
           ],
           tags: ['files']
      params do
        requires :id, type: Integer, desc: 'File ID'
      end
      get ':id' do
        file = {
          id: params[:id], filename: 'document.pdf', content_type: 'application/pdf',
          size_bytes: 102_400, download_url: "/api/v1/files/#{params[:id]}/download",
          uploaded_at: Time.now
        }
        present file, with: Entities::FileMetadata
      end

      desc 'Download file with content',
           success: { model: Entities::FileUpload },
           failure: [
             { code: 404, message: 'File not found' },
             { code: 401, message: 'Unauthorized' }
           ],
           notes: 'Returns file content as base64-encoded binary data',
           tags: ['files']
      params do
        requires :id, type: Integer, desc: 'File ID'
      end
      get ':id/download' do
        file = {
          id: params[:id],
          filename: 'document.pdf',
          content_type: 'application/pdf',
          size_bytes: 102_400,
          content: 'JVBERi0xLjQKJcOk...', # Base64 encoded content
          checksum: 'sha256:abc123def456...',
          uploaded_at: Time.now
        }
        present file, with: Entities::FileUpload
      end

      desc 'Upload a file',
           success: { model: Entities::FileMetadata, message: 'File uploaded successfully' },
           failure: [
             { code: 400, message: 'Invalid file' },
             { code: 413, message: 'File too large' },
             { code: 415, message: 'Unsupported file type' }
           ],
           consumes: ['multipart/form-data'],
           tags: ['files']
      params do
        requires :file, type: File, desc: 'File to upload'
        optional :description, type: String, desc: 'File description (nullable)', allow_blank: true
      end
      post do
        file = {
          id: rand(1000..9999),
          filename: 'uploaded_file.pdf',
          content_type: 'application/pdf',
          size_bytes: 102_400,
          download_url: '/api/v1/files/123/download',
          uploaded_at: Time.now
        }
        present file, with: Entities::FileMetadata
      end

      desc 'Upload file as base64',
           success: { model: Entities::FileMetadata },
           failure: [
             { code: 400, message: 'Invalid base64 data' },
             { code: 413, message: 'File too large' }
           ],
           notes: 'Alternative upload method using base64-encoded content',
           tags: ['files']
      params do
        requires :filename, type: String, desc: 'Original filename'
        requires :content_type, type: String, desc: 'MIME type'
        requires :content, type: String, desc: 'Base64-encoded file content'
        optional :checksum, type: String, desc: 'Expected SHA256 checksum for verification'
      end
      post 'base64' do
        file = {
          id: rand(1000..9999),
          filename: params[:filename],
          content_type: params[:content_type],
          size_bytes: params[:content].length * 3 / 4, # Approx decoded size
          download_url: '/api/v1/files/123/download',
          uploaded_at: Time.now
        }
        present file, with: Entities::FileMetadata
      end

      desc 'Delete a file',
           failure: [
             { code: 404, message: 'File not found' },
             { code: 401, message: 'Unauthorized' }
           ],
           tags: ['files']
      params do
        requires :id, type: Integer, desc: 'File ID'
      end
      delete ':id' do
        status 204
        body false
      end
    end
  end
end
