# -*- encoding : utf-8 -*-

def double_document_basic(overrides = {})
  defaults = {
    uid: 'doi:10.1234/5678',
    doi: '10.1234/5678',
    license: 'Public domain',
    data_source: 'Test fixture',
    title: 'Test Title',
    authors: [
      double(full: 'A. One',
             first: 'A.', last: 'One', prefix: nil, suffix: nil,
             to_citeproc: { 'family' => 'One', 'given' => 'A.' }),
      double(full: 'B. Two',
             first: 'B.', last: 'Two', prefix: nil, suffix: nil,
             to_citeproc: { 'family' => 'Two', 'given' => 'B.' })
      ],
    journal: 'Journal',
    volume: '10',
    number: '20',
    year: '2010',
    pages: '100-200',
    start_page: '100',
    end_page: '200'
  }
  double('Document', defaults.merge(overrides))
end
