# -*- encoding : utf-8 -*-
require 'citeproc'

module RLetters
  module Documents
    # Conversion code to Citation Style Language
    #
    # The Citation Style Language (http://citationstyles.org) is a language
    # designed for the processing of citations and bibliographic entries. In
    # RLetters, we use CSL to allow users to format the list of search results
    # in whatever bibliography-entry format they choose.
    class AsCSL
      # Initialize a CSL converter
      #
      # @param document [Document] the document to convert
      def initialize(document)
        unless document.is_a? Document
          fail ArgumentError, 'Cannot convert a non-Document class to CSL'
        end
        @doc = document
      end

      # Returns a hash representing the article in CSL format
      #
      # @api public
      # @return [Hash] article as a CSL record
      # @example Get the CSL entry for a given document
      #   doc = Document.new(...)
      #   RLetters::Documents::AsCSL.new(doc).hash
      #   # => { 'type' => 'article-journal', 'author' => ... }
      def hash
        ret = {}
        ret['type'] = 'article-journal'

        if @doc.formatted_author_list.present?
          ret['author'] = @doc.formatted_author_list.map { |a| a.to_citeproc }
        end

        ret['title'] = @doc.title if @doc.title.present?
        ret['container-title'] = @doc.journal if @doc.journal.present?
        ret['issued'] = { 'date-parts' => [[Integer(@doc.year)]] } if @doc.year.present?
        ret['volume'] = @doc.volume if @doc.volume.present?
        ret['issue'] = @doc.number if @doc.number.present?
        ret['page'] = @doc.pages if @doc.pages.present?

        ret
      end

      # Convert the document to CSL, and format it with the given style
      #
      # Takes a document and converts it to a bibliographic entry in the
      # specified style using CSL.
      #
      # @api public
      # @param [CslStyle, String] style_or_url CSL style to use (a CslStyle or
      #   a String URL to fetch)
      # @return [String] bibliographic entry in the given style
      # @example Convert a given document to Chicago author-date format
      #   RLetters::Documents::AsCSL.new(doc).entry(csl_style)
      #   # => "Doe, John. 2000. ..."
      def entry(style_or_url)
        if style_or_url.is_a? Users::CslStyle
          # Get the XML style
          style = style_or_url.style
        elsif style_or_url.is_a? String
          style = style_or_url
        else
          fail ArgumentError, 'Argument must be CslStyle or String'
        end

        CiteProc.process(hash, format: :html, style: style).strip.html_safe
      end
    end
  end
end