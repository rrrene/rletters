# -*- encoding : utf-8 -*-
require 'spec_helper'

RSpec.describe Admin::UploadedAsset, type: :model do

  describe '#valid?' do
    context 'when no name spcified' do
      before(:example) do
        @asset = build(:uploaded_asset, name: nil)
      end

      it 'is not valid' do
        expect(@asset).not_to be_valid
      end
    end

    context 'when all parameters are valid' do
      before(:example) do
        @asset = build(:uploaded_asset)
      end

      it 'is valid' do
        expect(@asset).to be_valid
      end
    end
  end

  describe '#friendly_name' do
    before(:example) do
      @asset = create(:uploaded_asset)
    end

    it 'returns the plain name with no translation, friendly name with translation' do
      # There's no way to *delete* a translation from the I18n backend, so
      # we have to do this in one test to make sure they're in order
      expect(@asset.friendly_name).to eq(@asset.name)

      I18n.backend.store_translations :en, uploaded_assets:
        { @asset.name.to_sym => 'The Friendly Name' }
      expect(@asset.friendly_name).to eq('The Friendly Name')
    end
  end

  describe '.url_for' do
    before(:example) do
      @asset = create(:uploaded_asset)
    end

    context 'when a non-existent asset is specified' do
      it 'returns an empty string' do
        expect(Admin::UploadedAsset.url_for('not_an_asset_id')).to eq('')
      end
    end

    context 'when an extant asset is specified' do
      it 'returns a URL' do
        url = Admin::UploadedAsset.url_for(@asset.name)
        expect(url).to start_with('/workflow/image/')
        expect(url).to include(@asset.to_param + '?')
      end
    end
  end

end
