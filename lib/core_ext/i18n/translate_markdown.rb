# -*- encoding : utf-8 -*-

# Ruby's internationalization module
module I18n
  class << self
    # Patch the global Ruby internationalization module to support Markdown
    #
    # This method grabs a translation from the database and runs it through
    # Markdown before returning it.  Note that this method does *not* call
    # html_safe by default; if you need that you should call it yourself.
    #
    # @api public
    # @param [String] key the lookup key for the translation requested
    # @return [String] the requested translation, parsed as Markdown
    # @example Parse the translation for `error.not_found` as Markdown
    #   %span= translate_markdown(:"error.not_found")
    def translate_markdown(key, options = {})
      Kramdown::Document.new(I18n.t(key, options)).to_html.html_safe
    end
    alias_method :t_md, :translate_markdown
  end
end

# Rails's translation helper
module ActionView::Helpers::TranslationHelper
  # Fetch a translation and run it through a Markdown parser
  #
  # Some translations are stored in the translation database as Markdown
  # markup.  This helper fetches them and then runs them through Kramdown.
  #
  # This just calls I18n.translate_markdown, but from the helper that is
  # mixed into all view contexts, so that we have this as a method on all
  # pages.
  #
  # @api public
  # @param [String] key the lookup key for the translation requested
  # @return [String] the requested translation, parsed as Markdown
  # @example Parse the translation for `error.not_found` as Markdown
  #   %span= translate_markdown(:"error.not_found")
  def translate_markdown(key, options = {})
    # This method is private, but it's what maps the ".not_found" shortcut
    # style keys to their full equivalents
    key_trans = scope_key_by_partial(key)
    I18n.translate_markdown(key_trans, options).html_safe
  end
  alias_method :t_md, :translate_markdown
end
