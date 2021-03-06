# -*- encoding : utf-8 -*-

# A CSL style users may select for citation formatting
#
# CSL styles are stored as a single table of styles in the database, which
# cannot be added to or edited by users.  Administrators can add new styles in
# the administration interface.
#
# @!attribute name
#   @raise [RecordInvalid] if the name is missing (validates :presence)
#   @return [String] Name of this CSL style
# @!attribute style
#   @raise [RecordInvalid] if the source is missing (validates :presence)
#   @return [String] XML source for this CSL style
class Users::CslStyle < ActiveRecord::Base
  self.table_name = 'users_csl_styles'
  validates :name, presence: true
  validates :style, presence: true
end
