# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::RequestParamParserRegistry do
  let(:registry) { described_class.new }

  # Define test parser classes for the tests
  let(:custom_parser_class) { Class.new }
  let(:another_parser_class) { Class.new }

  describe '#initialize' do
    it 'initializes with default parsers' do
      parsers = registry.to_a
      expect(parsers).to eq(described_class::DEFAULT_PARSERS)
    end

    it 'creates an independent copy of default parsers' do
      registry1 = described_class.new
      registry2 = described_class.new

      registry1.register(custom_parser_class)

      expect(registry1.to_a).to include(custom_parser_class)
      expect(registry2.to_a).not_to include(custom_parser_class)
    end
  end

  describe '#register' do
    it 'adds a parser at the end' do
      registry.register(custom_parser_class)

      expect(registry.to_a.last).to eq(custom_parser_class)
    end

    it 'removes duplicate before adding' do
      registry.register(custom_parser_class)
      registry.register(custom_parser_class)

      expect(registry.to_a.count(custom_parser_class)).to eq(1)
    end

    it 'moves existing parser to the end when re-registered' do
      registry.register(custom_parser_class)
      registry.register(another_parser_class)
      registry.register(custom_parser_class)

      parsers = registry.to_a
      expect(parsers.last).to eq(custom_parser_class)
      expect(parsers.count(custom_parser_class)).to eq(1)
    end
  end

  describe '#insert_before' do
    it 'inserts parser before specified class' do
      before_class = GrapeSwagger::RequestParamParsers::Body
      registry.insert_before(before_class, custom_parser_class)

      parsers = registry.to_a
      custom_index = parsers.index(custom_parser_class)
      before_index = parsers.index(before_class)

      expect(custom_index).to eq(before_index - 1)
    end

    it 'inserts at end if before_class not found' do
      registry.insert_before(custom_parser_class, another_parser_class)

      expect(registry.to_a.last).to eq(another_parser_class)
    end

    it 'removes duplicate before inserting' do
      registry.register(custom_parser_class)
      registry.insert_before(GrapeSwagger::RequestParamParsers::Body, custom_parser_class)

      expect(registry.to_a.count(custom_parser_class)).to eq(1)
    end
  end

  describe '#insert_after' do
    it 'inserts parser after specified class' do
      after_class = GrapeSwagger::RequestParamParsers::Headers
      registry.insert_after(after_class, custom_parser_class)

      parsers = registry.to_a
      custom_index = parsers.index(custom_parser_class)
      after_index = parsers.index(after_class)

      expect(custom_index).to eq(after_index + 1)
    end

    it 'inserts at end if after_class not found' do
      registry.insert_after(custom_parser_class, another_parser_class)

      expect(registry.to_a.last).to eq(another_parser_class)
    end

    it 'removes duplicate before inserting' do
      registry.register(custom_parser_class)
      registry.insert_after(GrapeSwagger::RequestParamParsers::Headers, custom_parser_class)

      expect(registry.to_a.count(custom_parser_class)).to eq(1)
    end
  end

  describe '#each' do
    it 'iterates over all parsers' do
      collected = registry.map { |parser| parser }

      expect(collected).to eq(described_class::DEFAULT_PARSERS)
    end

    it 'supports Enumerable methods' do
      expect(registry.map(&:itself)).to eq(described_class::DEFAULT_PARSERS)
      expect(registry.count).to eq(3)
    end
  end

  describe 'DEFAULT_PARSERS' do
    it 'contains expected parsers in order' do
      expect(described_class::DEFAULT_PARSERS).to eq([
                                                       GrapeSwagger::RequestParamParsers::Headers,
                                                       GrapeSwagger::RequestParamParsers::Route,
                                                       GrapeSwagger::RequestParamParsers::Body
                                                     ])
    end

    it 'is frozen' do
      expect(described_class::DEFAULT_PARSERS).to be_frozen
    end
  end
end
