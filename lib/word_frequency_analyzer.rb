# -*- encoding : utf-8 -*-

# Compute detailed word frequency information for a given dataset
#
# @!attribute [r] blocks
#   @return [Array<Hash>] The analyzed blocks of text (array of hashes of term
#     frequencies)
# @!attribute [r] block_stats
#   Information about each block.
#
#   Each hash in this array (one per block) has :name, :types, and :tokens
#   keys.
#
#   @return [Array<Hash>] Block information
# @!attribute [r] word_list
#   @return [Array<String>] The list of words (or ngrams) analyzed
# @!attribute [r] tf_in_dataset
#   @return [Hash<String, Integer>] For each word (or ngram), how many times
#     that word occurs in the dataset
# @!attribute [r] df_in_dataset
#   @return [Hash<String, Integer>] For each word (or ngram), the number of
#     documents in the dataset in which that word appears
# @!attribute [r] df_in_corpus
#   @return [Hash<String, Integer>] For each word, the number of documents in
#     the entire Solr corpus in which that word appears.  If +ngrams+ is set,
#     this value will not be available.
# @!attribute [r] num_dataset_tokens
#   @return [Integer] The number of tokens in the dataset.  If +ngrams+ is set,
#     this is the number of ngrams.
# @!attribute [r] num_dataset_types
#   @return [Integer] The number of types in the dataset.  If +ngrams+ is set,
#     this is the number of distinct ngrams.
class WordFrequencyAnalyzer
  attr_reader :blocks, :block_stats, :word_list, :tf_in_dataset,
              :df_in_dataset, :df_in_corpus, :num_dataset_tokens,
              :num_dataset_types

  # Create a new word frequency analyzer and analyze
  #
  # @api public
  # @param [Dataset] dataset The dataset to analyze
  # @param [Hash] options Parameters for how to compute word frequency
  # @option options [Integer] :block_size If set, split the dataset into blocks
  #   of this many words
  # @option options [Integer] :num_blocks If set, split the dataset into this
  #   many blocks of equal size
  # @option options [Boolean] :split_across If true, combine all the dataset
  #   documents together before splitting into blocks; otherwise, split into
  #   blocks only within a document
  # @option options [Integer] :ngrams If set, look for n-grams of this size,
  #   instead of single words
  # @option options [Integer] :num_words If set, only return frequency data for
  #   this many words; otherwise, return all words.  If +ngrams+ is set, this
  #   is a number of ngrams, not a number of words.
  # @option options [Symbol] :stemming If set to +:stem+, stem words with the
  #   Porter stemmer before taking frequency.  If set to +:lemma+, lemmatize
  #   with the Stanford NLP (if availble; slow!).  If unset, do not stem.
  # @option options [Symbol] :last_block This parameter changes what will
  #   happen to the "leftover" words when +block_size+ is set.
  #
  #   [+:big_last+]      add them to the last block, making a block larger than
  #     +block_size+.
  #   [+:small_last+]    make them into their own block, making a block smaller
  #     than +block_size+.
  #   [+:truncate_last+] truncate those leftover words, excluding them from
  #     frequency computation.
  #   [+:truncate_all+]  truncate _every_ text to +block_size+, creating only
  #     one block per document (or, if +split_across+ is set, only one block
  #     period)
  #
  #   The default is +:big_last+.
  # @option options [String] :inclusion_list If specified, then the analyzer
  #   will only compute frequency information for the words that are specified
  #   in this list (which is space-separated).
  #
  #   If +ngrams+ is set, then this works differently.  This list is assumed
  #   to be a comma-separated list of single words.  Ngrams will only be
  #   analyzed, then, if the ngram contains _at least one_ of the words found
  #   in +inclusion_list+.
  # @option options [String] :exclusion_list If specified, then the analyzer
  #   will *not* compute frequency information for the words that are specified
  #   in this list (which is space-separated).
  #
  #   If +ngrams+ is set, then this works differently.  This list is assumed
  #   to be a comma-separated list of single words.  If an ngram contains _any
  #   of the words_ in this list, then it will not be analyzed.
  # @option options [Documents::StopList] :stop_list If specified, then the
  #   analyzer will *not* compute frequency information for the words that
  #   appear within this stop list.  Cannot be used if +ngrams+ is set.
  def initialize(dataset, options = {})
    # Save the dataset and options
    @dataset = dataset
    normalize_options(options)

    # Compute all df and tfs, and the type/token values for the dataset
    compute_df_tf

    # Pick out the set of words we'll analyze
    pick_words

    # Prep the data containers
    @blocks = []
    @block_stats = []

    # If we're split_across, we can now compute block_size from num_blocks
    # and vice versa
    compute_block_size(@num_dataset_tokens) if @split_across

    # Set up the initial block
    @block_num = 0
    clear_block(nil, false)

    # Process all of the documents
    @word_cache.each do |uid, words|
      # If we aren't splitting across, then we have to completely clear
      # out all the count information for every document, and we have to
      # compute how many/how big the blocks should be for this document
      unless @split_across
        @block_num = 0
        compute_block_size(words.count)
      end

      # Do the processing for this document
      words.each do |word|
        # If we're truncating, then we want to be sure to stop when we hit the
        # calculated number of blocks
        if (@last_block == :truncate_last || @last_block == :truncate_all) &&
           @block_num == @num_blocks
          break
        end

        # Add this word to the block if we want it
        if @word_list.include? word
          @block[word] ||= 0
          @block[word] += 1
        end

        # Always increment the block counter and the number of tokens
        @type_counter[word] ||= true
        @block_tokens += 1
        @block_counter += 1

        # If we're doing :big_last for the last block, and this is the last
        # block, then we don't want to stop until we've digested all of the
        # words.  In that case, don't even check the block size.
        unless @last_block == :big_last && @block_num == (@num_blocks - 1)
          # If the block size doesn't divide evenly into the number of blocks
          # that we want, we want to consume the remainder one at a time over
          # the course of all the blocks, and *not* leave it until the end, or
          # else we wind up with one block that contains all the remainder,
          # despite the fact that we were trying to divide evenly.
          check_size = @block_size
          check_size = @block_size + 1 if @num_remainder_blocks != 0

          if @block_counter >= check_size
            @num_remainder_blocks -= 1 if @num_remainder_blocks != 0
            clear_block(uid)
          end
        end
      end

      # If we're not splitting across, we need to make sure the last block
      # for this doc, if there's anything in it, has been added to the list.
      clear_block(uid) if !@split_across && @block_counter != 0
    end

    # If we are splitting across, we need to put the last block into the
    # list
    clear_block if @split_across && @block_counter != 0
  end

  private

  # Set the options from the options hash and normalize their values
  #
  # @api private
  # @param [Hash] options Parameters for how to compute word frequency
  # @see WordFrequencyAnalyzer#initialize
  def normalize_options(options)
    # Set default values
    options.reverse_merge!(num_blocks: 0,
                           block_size: 0,
                           split_across: true,
                           ngrams: 1,
                           num_words: 0)

    # If we get num_blocks and block_size, then the user's done something
    # wrong; just take block_size
    if options[:num_blocks] > 0 && options[:block_size] > 0
      options[:num_blocks] = 0
    end

    # Default to a single block unless otherwise specified
    if options[:num_blocks] <= 0 && options[:block_size] <= 0
      options[:num_blocks] = 1
    end

    # Ngrams has to be 1 or greater
    options[:ngrams] = 1 if options[:ngrams] < 1

    # Make sure num_words isn't negative
    options[:num_words] = 0 if options[:num_words] < 0

    # Make sure last_block is a legitimate value
    unless [:big_last, :small_last,
            :truncate_last, :truncate_all].include? options[:last_block]
      options[:last_block] = :big_last
    end

    # Make sure stemming is a legitimate value
    unless [:stem, :lemma].include? options[:stemming]
      options[:stemming] = nil
    end

    # Make sure inclusion_list isn't blank
    options[:inclusion_list].strip! if options[:inclusion_list]
    options[:inclusion_list] = nil if options[:inclusion_list].blank?

    # Same for exclusion_list
    options[:exclusion_list].strip! if options[:exclusion_list]
    options[:exclusion_list] = nil if options[:exclusion_list].blank?

    # Make sure stop_list is the right type
    options[:stop_list] = nil unless options[:stop_list].is_a? Documents::StopList

    # No stop lists if ngrams is set
    if options[:stop_list] && options[:ngrams] != 1
      fail ArgumentError, 'cannot set both ngrams > 1 and stop_list'
    end

    # Copy over the parameters to member variables
    @num_blocks = options[:num_blocks]
    @block_size = options[:block_size]
    @split_across = options[:split_across]
    @ngrams = options[:ngrams]
    @num_words = options[:num_words]
    @stemming = options[:stemming]
    @last_block = options[:last_block]
    @inclusion_list = options[:inclusion_list].try(:split)
    @exclusion_list = options[:exclusion_list].try(:split)
    @stop_list = options[:stop_list]

    # We will eventually set both @num_blocks and @block_size for our inner
    # loops, so we need to save which of these is the "primary" one, that
    # was set by the user
    if @num_blocks > 0
      @block_method = :count

      # We don't want any of the last_block logic if we're splitting by number
      # of blocks.
      @last_block = nil
    else
      @block_method = :words
    end
  end

  # Compute the df and tf for all the words in the dataset
  #
  # This function computes and sets +df_in_dataset+, +tf_in_dataset+,
  # and +df_in_corpus+ for all the words in the dataset.  Note that this
  # function ignores the +num_words+ parameter, as we need these tf values
  # to sort in order to obtain the most/least frequent words.
  #
  # All three of these variables are hashes, with the words as String keys
  # and the tf/df values as Integer values.
  #
  # Finally, this function also sets +num_dataset_types+ and
  # +num_dataset_tokens+, as we can compute them easily here.
  #
  # Note that there is no such thing as +tf_in_corpus+, as this would be
  # incredibly, prohibitively expensive and is not provided by Solr.
  #
  # @api private
  def compute_df_tf
    @df_in_dataset = {}
    @tf_in_dataset = {}
    @df_in_corpus = {}
    @word_cache = {}

    @dataset.entries.each do |e|
      @word_cache[e.uid] = Document.word_list_for(e.uid, ngrams: @ngrams,
                                                         stemming: @stemming)

      @word_cache[e.uid].group_by { |w| w }.map { |k, v| [k, v.count] }.each do |g|
        @tf_in_dataset[g[0]] ||= 0
        @tf_in_dataset[g[0]] += g[1]

        @df_in_dataset[g[0]] ||= 0
        @df_in_dataset[g[0]] += 1
      end

      # Fetch @df_in_corpus, if available
      if @ngrams == 1
        doc = Document.find(e.uid, term_vectors: true)
        doc.term_vectors.each do |word, hash|
          word = word.stem if @stemming == :stem

          # Oddly enough, you'll get weird bogus values for words that don't
          # appear in your document back from Solr.  Not sure what's up with
          # that.
          if hash[:df] > 0 && @df_in_corpus[word].blank?
            @df_in_corpus[word] = hash[:df]
          end
        end
      end
    end

    @num_dataset_types ||= @tf_in_dataset.count
    @num_dataset_tokens ||= @tf_in_dataset.values.reduce(:+)
  end

  # Determine which words we'll analyze
  #
  # This function consults +inclusion_list+, and either takes the words
  # specified there, or the +num_words+ most frequent words from the
  # +tf_in_dataset+ list and sets the array +word_list+.  It also removes any
  # words specified in +exclusion_list+.
  #
  # @api private
  def pick_words
    # If we have a word-list for 1-grams, this is easy
    if @inclusion_list.present? && @ngrams == 1
      @word_list = @inclusion_list
      return
    end

    # Exclusion list takes precedence over stop list, if both are somehow
    # specified
    excluded = []
    if @exclusion_list
      excluded = @exclusion_list
    elsif @stop_list
      excluded = @stop_list.list.split
    end

    included = []
    if @inclusion_list
      included = @inclusion_list
    end

    sorted_pairs = @tf_in_dataset.to_a.sort { |a, b| b[1] <=> a[1] }
    @word_list = sorted_pairs.map { |a| a[0] }

    if @ngrams == 1
      if excluded.present?
        # For 1-grams we can just use array difference.  If an inclusion list
        # was specified, we already did that up above and bailed early.
        @word_list -= excluded
      end
    else
      if excluded.present?
        # Keep any grams for which there is no overlap between the exclusion
        # list and the gram's words
        @word_list.select! { |w| (w.split & excluded).empty? }
      elsif included.present?
        # Reject any grams for which there is no overlap between the inclusion
        # list and the gram's words
        @word_list.reject! { |w| (w.split & included).empty? }
      end
    end

    @word_list = @word_list.take(@num_words) if @num_words != 0
  end

  # Get the name of this block
  #
  # @param [String] uid the id of the document for this block (if needed)
  # @return [String] The name of this block
  def block_name(uid)
    if @split_across
      if @block_method == :count
        I18n.t('lib.wfa.block_count_dataset',
               num: @block_num, total: @num_blocks)
      else
        I18n.t('lib.wfa.block_size_dataset',
               num: @block_num, size: @block_size)
      end
    else
      title = Document.find_by(uid: uid).try(:title)

      if @block_method == :count
        I18n.t('lib.wfa.block_count_doc',
               num: @block_num, total: @num_blocks,
               title: title || I18n.t('search.document.untitled'))
      else
        I18n.t('lib.wfa.block_size_doc',
               num: @block_num, size: @block_size,
               title: title || I18n.t('search.document.untitled'))
      end
    end
  end

  # Reset all the current block information
  #
  # This clears all the block-related variables and sets us up for a new
  # block.  If the passed parameter is true, then also add the current block
  # to the block list before clearing it.
  #
  # @api private
  def clear_block(uid = nil, add = true)
    if add
      @block_num += 1

      @block_stats << { name: block_name(uid), types: @type_counter.count,
                        tokens: @block_tokens }
      @blocks << @block.deep_dup
    end

    @block_counter = 0
    @block_tokens = 0

    @block = {}
    @type_counter = {}
  end

  # Compute the block size parameters from the number of tokens
  #
  # This function takes whichever of the two block size numbers is primary
  # (by looking at @block_method), and computes the other given the number
  # of tokens (either in the document or in the dataset) and the details of
  # the splitting method.
  #
  # After this function is called, @num_blocks, @block_size,
  # and @num_remainder_blocks will all be set correctly.
  #
  # @api private
  # @param [Integer] num_tokens The number of tokens in our unit of analysis
  def compute_block_size(num_tokens)
    if @block_method == :count
      @block_size = (num_tokens / @num_blocks.to_f).floor
      @num_remainder_blocks = num_tokens - (@block_size * @num_blocks)
    else
      if @last_block == :big_last || @last_block == :truncate_last
        @num_blocks = (num_tokens / @block_size.to_f).floor
      elsif @last_block == :small_last
        @num_blocks = (num_tokens / @block_size.to_f).ceil
      else # :truncate_all
        @num_blocks = 1
      end

      @num_remainder_blocks = 0
    end
  end
end
