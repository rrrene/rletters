# -*- encoding : utf-8 -*-
require 'spec_helper'
require 'support/doubles/rsolr_facets'

RSpec.describe RLetters::Solr::Facets do
  before(:example) do
    @facets = described_class.new(double_rsolr_facets,
                                  double_rsolr_facet_queries)
  end

  describe '#for_field' do
    it 'has the right facet hash keys' do
      expect(@facets.for_field(:authors_facet)).not_to be_empty
      expect(@facets.for_field(:journal_facet)).not_to be_empty
      expect(@facets.for_field(:year)).not_to be_empty
    end

    it 'parses authors_facet correctly' do
      f = @facets.for_field(:authors_facet).find { |o| o.value == 'A. One' }
      expect(f).to be
      expect(f.hits).to eq(1)
    end

    it 'does not include authors_facet entries for authors not present' do
      f = @facets.for_field(:authors_facet).find { |o| o.value == 'W. Shatner' }
      expect(f).not_to be
    end

    it 'parses journal_facet correctly' do
      f = @facets.for_field(:journal_facet).find { |o| o.value == 'Journal' }
      expect(f).to be
      expect(f.hits).to eq(1)
    end

    it 'does not include journal_facet entries for journals not present' do
      f = @facets.for_field(:journal_facet).find { |o| o.value == 'Journal of Nothing' }
      expect(f).not_to be
    end

    it 'parses year facet queries correctly' do
      f = @facets.for_field(:year).find { |o| o.value == '[2000 TO 2009]' }
      expect(f).to be
      expect(f.hits).to eq(10)
    end

    it 'does not include year facet queries for non-present years' do
      f = @facets.for_field(:year).find { |o| o.value == '[1940 TO 1949]' }
      expect(f).not_to be
    end
  end

  describe '#sorted_for_field' do
    it 'sorts them appropriately when asked' do
      expect(@facets.sorted_for_field(:year).first.value).to eq('[1990 TO 1999]')
    end
  end

  describe '#for_query' do
    it 'can pick out facets by query' do
      expect(@facets.for_query('year:[2000 TO 2009]')).to be
      expect(@facets.for_query('authors_facet:"B. Two"')).to be
    end
  end
end
