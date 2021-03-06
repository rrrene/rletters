# -*- encoding : utf-8 -*-
require 'spec_helper'

RSpec.describe Jobs::DestroyDataset do

  before(:example) do
    @user = create(:user)
    @dataset = create(:dataset, user: @user)
  end

  context 'when the wrong user is specified' do
    it 'raises an exception and does not destroy a dataset' do
      expect {
        expect {
          Jobs::DestroyDataset.perform(
            '123',
            user_id: create(:user).to_param,
            dataset_id: @dataset.to_param)
        }.to raise_error(ActiveRecord::RecordNotFound)
      }.to_not change { @user.datasets.count }
    end
  end

  context 'when an invalid user is specified' do
    it 'raises an exception' do
      expect {
        Jobs::DestroyDataset.perform('123',
                                     user_id: '12345678',
                                     dataset_id: @dataset.to_param)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'when an invalid dataset is specified' do
    it 'raises an exception and does not destroy a dataset' do
      expect {
        expect {
          Jobs::DestroyDataset.perform('123',
                                       user_id: @user.to_param,
                                       dataset_id: '12345678')
        }.to raise_error(ActiveRecord::RecordNotFound)
      }.to_not change { @user.datasets.count }
    end
  end

  context 'when the parameters are valid' do
    it 'destroys a dataset' do
      expect {
        Jobs::DestroyDataset.perform('123',
                                     user_id: @user.to_param,
                                     dataset_id: @dataset.to_param)
      }.to change { @user.datasets.count }.by(-1)
    end
  end

end
