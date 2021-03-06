# -*- encoding : utf-8 -*-

# The main application controller for RLetters
#
# This controller implements functionality shared throughout the entire
# RLetters site.
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  # Redirect to the root on successful sign in
  #
  # This method is called by Devise.
  #
  # @api private
  # @param [User, Admin::Administrator] resource the user that just signed in
  # @return [void]
  def after_sign_in_path_for(resource)
    if resource.is_a?(Admin::Administrator)
      admin_root_url
    else
      root_url
    end
  end

  # Redirect to the root on successful sign out
  #
  # This method is called by Devise.
  #
  # @api private
  # @param [User, Admin::Administrator] resource the user that just signed out
  # @return [void]
  def after_sign_out_path_for(resource)
    root_url
  end

  # Render a localized Markdown document
  #
  # This function renders a localized Markdown file located in the locales
  # tree.
  #
  # @api public
  # @param [String] file the document to be rendered
  # @return [SafeBuffer] the rendering result
  # @example Render config/locales/test/test.en.md
  #   %div= render_localized_markdown(:test)
  def render_localized_markdown(file)
    path = Rails.root.join('config', 'locales', file.to_s,
                           "#{file}.#{I18n.locale}.md")

    # Fall back to English if we have to
    unless File.exist?(path)
      if I18n.locale != :en
        path = Rails.root.join('config', 'locales', file.to_s,
                               "#{file}.en.md")
      end
    end

    # Give up if we can't find it
    unless File.exist?(path)
      fail I18n::MissingTranslationData.new(I18n.locale,
                                            "localized_markdown.#{file}",
                                            {})
    end

    render_to_string(file: path, layout: false).html_safe
  end
  helper_method :render_localized_markdown

  private

  before_action :set_locale, :set_timezone

  # Set the locale if the user is logged in
  #
  # This function is called as a `before_action` in all controllers, you do
  # not need to call it yourself.  Do not disable it, or the locale system
  # will go haywire.
  #
  # @api private
  # @return [void]
  def set_locale
    if user_signed_in?
      I18n.locale = current_user.language.to_sym
    else
      I18n.locale = I18n.default_locale
    end
  end

  # Set the timezone if the user is logged in
  #
  # This function is called as a `before_action` in all controllers, you do
  # not need to call it yourself.  Do not disable it, or the timezone system
  # will go haywire.
  #
  # @api private
  # @return [void]
  def set_timezone
    if user_signed_in?
      Time.zone = current_user.timezone
    else
      Time.zone = 'Eastern Time (US & Canada)'
    end
  end

  protected

  # Set cache control headers
  #
  # This helper can be called when we want a page to expire.  This is similar
  # to Rails' `expires_now` function, but sets more headers to work with more
  # browsers.
  #
  # @api private
  # @return [void]
  def disable_browser_cache
    response.cache_control[:no_cache] = true
    response.cache_control[:extras] = ['no-store', 'max-age=0', 'must-revalidate']
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = 'Fri, 01 Jan 1990 00:00:00 GMT'
  end

  # Send the right parameter sanitizers to Devise
  #
  # Devise in Rails 4 uses this hook in the application controller in order
  # to determine which parameters are accepted across the various account
  # management forms.  When a regular user logs in, delegate to that parameter
  # sanitizer.  Otherwise (e.g., for admin logins in the backend), just use
  # the defaults.
  #
  # This method is not tested, as it's only ever called from within the
  # internals of Devise.
  #
  # @api private
  # @return [Devise::ParameterSanitizer] sanitizer to be used
  # :nocov:
  def devise_parameter_sanitizer
    if resource_class == User
      User::ParameterSanitizer.new(User, :user, params)
    else
      super
    end
  end
  # :nocov:
end
