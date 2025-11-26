# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::OpenAPI::LazyComponentBuilder do
  let(:version) { GrapeSwagger::OpenAPI::Version.new('3.1.0') }
  let(:builder) { described_class.new(version) }

  describe '#register' do
    it 'registers a component with a builder block' do
      builder.register('User') { { type: 'object', properties: { name: { type: 'string' } } } }

      expect(builder.pending_count).to eq(1)
    end

    it 'allows multiple registrations' do
      builder.register('User') { { type: 'object' } }
      builder.register('Post') { { type: 'object' } }
      builder.register('Comment') { { type: 'object' } }

      expect(builder.pending_count).to eq(3)
    end

    it 'does not call the block during registration' do
      call_count = 0
      builder.register('User') { call_count += 1; { type: 'object' } }

      expect(call_count).to eq(0)
    end
  end

  describe '#resolve' do
    it 'resolves and returns the component' do
      builder.register('User') { { type: 'object', properties: { name: { type: 'string' } } } }

      result = builder.resolve('User')

      expect(result).to eq({ type: 'object', properties: { name: { type: 'string' } } })
    end

    it 'returns nil for unregistered components' do
      result = builder.resolve('NotRegistered')

      expect(result).to be_nil
    end

    it 'caches resolved components' do
      call_count = 0
      builder.register('User') { call_count += 1; { type: 'object' } }

      builder.resolve('User')
      builder.resolve('User')

      expect(call_count).to eq(1)
    end

    it 'moves component from pending to resolved' do
      builder.register('User') { { type: 'object' } }
      expect(builder.pending_count).to eq(1)

      builder.resolve('User')

      expect(builder.pending_count).to eq(0)
      expect(builder.resolved_count).to eq(1)
    end

    it 'handles dependencies between components' do
      builder.register('Post') do
        user = builder.resolve('User')
        { type: 'object', properties: { author: { '$ref' => '#/components/schemas/User' } } }
      end
      builder.register('User') { { type: 'object', properties: { name: { type: 'string' } } } }

      post = builder.resolve('Post')

      expect(post[:properties][:author]).to eq({ '$ref' => '#/components/schemas/User' })
    end
  end

  describe '#resolve_all' do
    it 'resolves all pending components' do
      builder.register('User') { { type: 'object' } }
      builder.register('Post') { { type: 'object' } }

      builder.resolve_all

      expect(builder.pending_count).to eq(0)
      expect(builder.resolved_count).to eq(2)
    end

    it 'returns all resolved components' do
      builder.register('User') { { type: 'object', properties: { name: { type: 'string' } } } }
      builder.register('Post') { { type: 'object', properties: { title: { type: 'string' } } } }

      result = builder.resolve_all

      expect(result.keys).to contain_exactly('User', 'Post')
      expect(result['User']).to eq({ type: 'object', properties: { name: { type: 'string' } } })
    end
  end

  describe '#resolved_components' do
    it 'returns only resolved components' do
      builder.register('User') { { type: 'object' } }
      builder.register('Post') { { type: 'object' } }

      builder.resolve('User')

      resolved = builder.resolved_components

      expect(resolved.keys).to eq(['User'])
    end

    it 'returns a copy to prevent external modification' do
      builder.register('User') { { type: 'object' } }
      builder.resolve('User')

      resolved = builder.resolved_components
      resolved['Malicious'] = { type: 'hack' }

      expect(builder.resolved_components.keys).not_to include('Malicious')
    end
  end

  describe '#pending_count' do
    it 'returns number of unresolved components' do
      expect(builder.pending_count).to eq(0)

      builder.register('User') { { type: 'object' } }
      expect(builder.pending_count).to eq(1)

      builder.register('Post') { { type: 'object' } }
      expect(builder.pending_count).to eq(2)

      builder.resolve('User')
      expect(builder.pending_count).to eq(1)
    end
  end

  describe '#resolved_count' do
    it 'returns number of resolved components' do
      expect(builder.resolved_count).to eq(0)

      builder.register('User') { { type: 'object' } }
      builder.register('Post') { { type: 'object' } }

      expect(builder.resolved_count).to eq(0)

      builder.resolve('User')
      expect(builder.resolved_count).to eq(1)

      builder.resolve('Post')
      expect(builder.resolved_count).to eq(2)
    end
  end

  describe 'circular reference handling' do
    it 'handles circular references gracefully' do
      builder.register('User') do
        { type: 'object', properties: { friends: { items: { '$ref' => '#/components/schemas/User' } } } }
      end

      result = builder.resolve('User')

      expect(result[:properties][:friends][:items]).to eq({ '$ref' => '#/components/schemas/User' })
    end
  end

  describe 'memory efficiency' do
    it 'does not store both pending and resolved for same component' do
      builder.register('User') { { type: 'object' } }

      builder.resolve('User')

      # Internal check - pending should be cleared after resolve
      expect(builder.pending_count).to eq(0)
      expect(builder.resolved_count).to eq(1)
    end
  end
end
