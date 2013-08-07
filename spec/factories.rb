# -*- encoding : utf-8 -*-

WORKING_SHASUMS = [
                   '00040b66948f49c3a6c6c0977530e2014899abf9'.freeze,
                   '001954306c066a8a4cff3da02f7e9dda8e0fb634'.freeze,
                   '00496e7961871ad05013e1388aaa6650507b2638'.freeze,
                   '008896a5c58241b65088d931e02f3bea02fc3bf0'.freeze,
                   '00972c5123877961056b21aea4177d0dc69c7318'.freeze,
                   '0097c3434054c25e1ace6243a1ac54b71f35bc28'.freeze,
                   '0097e0f4029fef57b8158970112ab32c1e692cff'.freeze,
                   '00a004096479b9332b153e91053f09df8003ef74'.freeze,
                   '00cdb0f945c1e1d7b7789cd8178f3232a57fee34'.freeze,
                   '00dbffbfff2d18a74ed5f8895fa9f515bf38bf5f'.freeze
                  ].freeze

FactoryGirl.define do

  sequence :working_shasum do |n|
    WORKING_SHASUMS[n % WORKING_SHASUMS.count]
  end

  factory :admin_user do
    sequence(:email) { |n| "admin#{n}@example.com" }
    password 'password'
    password_confirmation 'password'
    remember_me false
  end

  factory :analysis_task do
    name 'Analysis Task'
    dataset
    job_type 'FakeJob'
  end

  factory :dataset do
    ignore do
      working false
    end

    name 'Dataset'
    user

    factory :full_dataset do
      ignore do
        working false
        entries_count 5
      end

      after(:create) do |dataset, evaluator|
        dataset.entries = evaluator.entries_count.times.map do
          FactoryGirl.create(:dataset_entry, dataset: dataset,
                             working: evaluator.working)
        end
      end
    end
  end

  factory :dataset_entry do
    ignore do
      working false
    end

    sequence(:shasum) do |n|
      if working
        FactoryGirl.generate(:working_shasum)
      else
        "#{1_234_567_890_123_456_789_012_345_678_901_234_567_890 + n}"
      end
    end

    dataset
  end

  factory :document do
    ignore do
      shasum '1111111111111111111111111111111111111111'
      doi nil
      license nil
      license_url nil
      authors nil
      title nil
      journal nil
      year nil
      volume nil
      number nil
      pages nil
      fulltext nil
    end

    factory :full_document do
      ignore do
        shasum '00972c5123877961056b21aea4177d0dc69c7318'
        doi '10.1111/j.1439-0310.2008.01576.x'
        license '© Blackwell Verlag GmbH'
        license_url 'http://onlinelibrary.wiley.com/journal/10.1111/(ISSN)1439-0310/homepage/Permissions.html'
        authors 'Carlos A. Botero, Andrew E. Mudge, Amanda M. Koltz, Wesley M. Hochachka, Sandra L. Vehrencamp'
        title 'How Reliable are the Methods for Estimating Repertoire Size?'
        journal 'Ethology'
        year '2008'
        volume '114'
        pages '1227-1238'
        fulltext 'Ethology How Reliable are the Methods for Estimating Repertoire Size?'
      end
    end

    initialize_with do
      Document.new(shasum: shasum, doi: doi, license: license,
                   license_url: license_url, authors: authors, title: title,
                   journal: journal, year: year, volume: volume,
                   number: number, pages: pages, fulltext: fulltext)
    end
  end

  factory :download do
    filename 'test.txt'
    analysis_task
  end

  factory :library do
    name 'Harvard'
    sequence(:url) { |n| "http://sfx.hul.harvard#{n}.edu/sfx_local?" }
    user
  end

  factory :markdown_page do
    name 'test_page'
    content '# Header'
  end

  factory :uploaded_asset do
    name 'test_asset'
    file { File.new(Rails.root.join('spec', 'spec_helper.rb')) }
  end

  factory :user do
    name 'John Doe'
    sequence(:email) { |n| "person#{n}@example.com" }
    password 'password'
    password_confirmation 'password'
    remember_me false
    per_page 10
    language 'en'
    timezone 'Eastern Time (US & Canada)'
  end

end
