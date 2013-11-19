# -*- encoding : utf-8 -*-

# A list of common words to exclude from analysis
#
# We often need to remove commonly occurring words from bodies of text for
# analysis purposes.  To make that process easy, we seed lists of those words
# into the database.
#
# @!attribute language
#   @raise [RecordInvalid] if the language is missing (validates :presence)
#   @return [String] Language for this stop list
# @!attribute list
#   @raise [RecordInvalid] if the list is missing (validates :presence)
#   @return [String] Space-separated list of common words to exclude
class Documents::StopList < ActiveRecord::Base
  validates :language, presence: true
  validates :list, presence: true

  # @return [String] the +language+ parameter, translated into the user's
  #   selected language
  def display_language
    I18n.t("languages.#{language}")
  end
end

# Module for resources related to documents and textual analysis
module Documents
  def self.table_name_prefix
    'documents_'
  end
end