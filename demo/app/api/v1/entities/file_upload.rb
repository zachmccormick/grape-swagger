# frozen_string_literal: true

module V1
  module Entities
    # File upload entity demonstrating binary data
    class FileUpload < BaseEntity
      expose :id, documentation: { type: Integer, desc: 'File ID' }
      expose :filename, documentation: { type: String, desc: 'Original filename' }
      expose :content_type, documentation: { type: String, desc: 'MIME type' }
      expose :size_bytes, documentation: { type: Integer, desc: 'File size in bytes' }
      expose :content, documentation: {
        type: String,
        desc: 'File content (base64 encoded)',
        format: 'binary'
      }
      expose :checksum, documentation: {
        type: String,
        desc: 'SHA256 checksum',
        format: 'byte'
      }
      expose :uploaded_at, format_with: :iso_timestamp, documentation: { type: DateTime }
    end

    # File metadata (without content)
    class FileMetadata < BaseEntity
      expose :id, documentation: { type: Integer }
      expose :filename, documentation: { type: String }
      expose :content_type, documentation: { type: String }
      expose :size_bytes, documentation: { type: Integer }
      expose :download_url, documentation: { type: String, format: 'uri' }
      expose :uploaded_at, format_with: :iso_timestamp, documentation: { type: DateTime }
    end
  end
end
