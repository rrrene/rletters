# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Jobs::Analysis::Collocation do

  it_should_behave_like 'an analysis job'

  before(:each) do
    @user = FactoryGirl.create(:user)
    @dataset = FactoryGirl.create(:full_dataset, entries_count: 10,
                                                 working: true, user: @user)
    @task = FactoryGirl.create(:analysis_task, dataset: @dataset)
  end

  describe '.download?' do
    it 'is true' do
      expect(Jobs::Analysis::Collocation.download?).to be true
    end
  end

  describe '.num_datasets' do
    it 'is 1' do
      expect(Jobs::Analysis::Collocation.num_datasets).to eq(1)
    end
  end

  describe '.perform' do
    it 'accepts all the valid parameters' do
      valid_params = [:mi, :t, :likelihood]
      valid_params << :pos if NLP_ENABLED

      valid_params.each do |p|
        expect {
          Jobs::Analysis::Collocation.perform(
            user_id: @user.to_param,
            dataset_id: @dataset.to_param,
            task_id: @task.to_param,
            analysis_type: p.to_s,
            num_pairs: '10')
        }.to_not raise_error
      end
    end

    context 'when all parameters are valid' do
      before(:each) do
        Jobs::Analysis::Collocation.perform(
          user_id: @user.to_param,
          dataset_id: @dataset.to_param,
          task_id: @task.to_param,
          num_pairs: '10',
          analysis_type: 'mi')

        @output = CSV.parse(@dataset.analysis_tasks[0].result.file_contents(:original))
      end

      it 'names the task correctly' do
        expect(@dataset.analysis_tasks[0].name).to eq('Determine significant associations between word pairs')
      end

      it 'creates good CSV' do
        expect(@output).to be_an(Array)
      end
    end
  end
end