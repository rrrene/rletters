# -*- encoding : utf-8 -*-
require 'spec_helper'

RSpec.describe Jobs::Analysis::ArticleDates do

  it_should_behave_like 'an analysis job'

  before(:example) do
    @user = create(:user)
    @dataset = create(:full_dataset, working: true, user: @user)
    @task = create(:analysis_task, dataset: @dataset)
  end

  describe '.download?' do
    it 'is false' do
      expect(Jobs::Analysis::ArticleDates.download?).to be false
    end
  end

  describe '.num_datasets' do
    it 'is 1' do
      expect(Jobs::Analysis::ArticleDates.num_datasets).to eq(1)
    end
  end

  context 'when not normalizing' do
    before(:example) do
      Jobs::Analysis::ArticleDates.perform(
        '123',
        user_id: @user.to_param,
        dataset_id: @dataset.to_param,
        task_id: @task.to_param,
        normalize_doc_counts: 'off')
    end

    it 'names the task correctly' do
      expect(@dataset.analysis_tasks[0].name).to eq('Plot number of articles by date')
    end

    it 'creates good JSON' do
      data = JSON.load(@dataset.analysis_tasks[0].result.file_contents(:original))
      expect(data).to be_a(Hash)
    end

    it 'fills in some values' do
      arr = JSON.load(@dataset.analysis_tasks[0].result.file_contents(:original))['data']
      expect((1990..2012)).to cover(arr[0][0])
      expect((1..5)).to cover(arr[0][1])
    end

    it 'fills in some zeroes in intervening years' do
      arr = JSON.load(@dataset.analysis_tasks[0].result.file_contents(:original))['data']
      elt = arr.find { |y| y[1] == 0 }
      expect(elt).to be
    end
  end

  context 'when normalizing to the corpus' do
    before(:example) do
      Jobs::Analysis::ArticleDates.perform(
        '123',
        user_id: @user.to_param,
        dataset_id: @dataset.to_param,
        task_id: @task.to_param,
        normalize_doc_counts: '1',
        normalize_doc_dataset: '')
    end

    after(:example) do
      @task
    end

    it 'names the task correctly' do
      expect(@dataset.analysis_tasks[0].name).to eq('Plot number of articles by date')
    end

    it 'creates good JSON' do
      arr = JSON.load(@dataset.analysis_tasks[0].result.file_contents(:original))
      expect(arr).to be_a(Hash)
    end

    it 'sets the normalization set properly' do
      data = JSON.load(@dataset.analysis_tasks[0].result.file_contents(:original))
      expect(data['normalization_set']).to eq('Entire Corpus')
    end

    it 'marks that this was a normalized count' do
      data = JSON.load(@dataset.analysis_tasks[0].result.file_contents(:original))
      expect(data['percent']).to be true
    end

    it 'fills in some values' do
      arr = JSON.load(@dataset.analysis_tasks[0].result.file_contents(:original))['data']
      pair = arr[0]
      expect((1895..2012)).to cover(pair[0])
      expect((0..1)).to cover(pair[1])
    end

    it 'expands the range of zeroes to include the entire corpus range' do
      arr = JSON.load(@dataset.analysis_tasks[0].result.file_contents(:original))['data']
      expect(arr.assoc(1910)).to be
      expect(arr.assoc(1910)[1]).to eq(0)
    end
  end

  context 'when normalizing to a dataset' do
    before(:example) do
      @normalization_set = create(:full_dataset, working: true,
                                                 entries_count: 10,
                                                 user: @user)

      Jobs::Analysis::ArticleDates.perform(
        '123',
        user_id: @user.to_param,
        dataset_id: @dataset.to_param,
        task_id: @task.to_param,
        normalize_doc_counts: '1',
        normalize_doc_dataset: @normalization_set.to_param)
    end

    it 'names the task correctly' do
      expect(@dataset.analysis_tasks[0].name).to eq('Plot number of articles by date')
    end

    it 'creates good JSON' do
      data = JSON.load(@dataset.analysis_tasks[0].result.file_contents(:original))
      expect(data).to be_a(Hash)
    end

    it 'sets the normalization set properly' do
      data = JSON.load(@dataset.analysis_tasks[0].result.file_contents(:original))
      expect(data['normalization_set']).to eq(@normalization_set.name)
    end

    it 'marks that this was a normalized count' do
      data = JSON.load(@dataset.analysis_tasks[0].result.file_contents(:original))
      expect(data['percent']).to be true
    end

    it 'fills in some values' do
      arr = JSON.load(@dataset.analysis_tasks[0].result.file_contents(:original))['data']
      pair = arr[0]
      expect((1990..2012)).to cover(pair[0])
      expect((0..1)).to cover(pair[1])
    end
  end

end
