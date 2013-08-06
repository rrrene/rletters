# -*- encoding : utf-8 -*-

# Representation of a library-owned OpenURL resolver
#
# @!attribute name
#   @raise [RecordInvalid] if the name is missing (validates :presence)
#   @return [String] The name of the library
# @!attribute url
#   @raise [RecordInvalid] if the URL is missing (validates :presence)
#   @raise [RecordInvalid] if the URL is not a valid URL (validates :format)
#   @return [String] The base URL for its OpenURL resolver
# @!attribute user
#   @raise [RecordInvalid] if the user is missing (validates :presence)
#   @return [User] The user this library entry belongs to
class Library < ActiveRecord::Base
  belongs_to :user

  validates :name, presence: true
  validates :url, presence: true
  validates :url, url: true
  validates :user_id, presence: true

  protected

  before_validation do |library|
    unless library.url.blank?
      library.url = 'http://' + url unless library.url.start_with? 'http'
    end
  end

  after_validation do |library|
    unless library.url.blank?
      library.url = library.url + '?' unless library.url.end_with? '?'
    end
  end
end