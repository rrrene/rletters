# -*- encoding : utf-8 -*-

# Store all the Paperclip attachments in the database
Paperclip::Attachment.default_options[:storage] = :database
Paperclip::Attachment.default_options[:processors] = []

# JSON files are text/plain
Paperclip.options[:content_type_mappings] = {
  json: 'text/plain'
}
