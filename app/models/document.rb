# coding: UTF-8

require 'active_record'

class Document
  # The SHA-1 hash of the document's PDF file
  attr_reader :shasum
  
  # The DOI (Digital Object Identifier) of this document
  attr_reader :doi
  
  # A URL to the DOI-resolving page for the document
  def doi_url; "http://dx.doi.org/" + doi; end
    
  # The document's authors, in "First Last" format, separated
  # by commas
  attr_reader :authors
  
  # The title of the document
  attr_reader :title
  
  # The journal in which the document was published
  attr_reader :journal
  
  # The year in which the document was published
  attr_reader :year
  
  # The volume of the journal in which the article appears
  attr_reader :volume
  
  # The issue number of the journal in which the article appears
  attr_reader :number
  
  # Page numbers of the article
  attr_reader :pages
  
  # OCR'ed full text of the document.  Available only if the document
  # is retrieved by +Document.find+ with the +fulltext+ parameter set
  # to +true+.
  attr_reader :fulltext
  
  # Term vectors for this document.  This is provided in the following
  # format:
  #
  #   doc.term_vectors["word"]
  #     # Term frequency (number of times this term appears in doc)
  #     doc.term_vectors["word"][:tf] = Integer
  #     # Term offsets
  #     doc.term_vectors["word"][:offsets] = Array
  #       # The start and end character offsets for "word" within 
  #       # doc.fulltext
  #       doc.term_vectors["word"][:offsets][0] = Range
  #       ...
  #     # Term positions
  #     doc.term_vectors["word"][:positions] = Array
  #       # The word-index of this word in doc.fulltext
  #       doc.term_vectors["word"][:positions][0] = Integer
  #       ...
  #     # Number of documents in collection that contain "word"
  #     doc.term_vectors["word"][:df] = Float
  #     # Term frequency-inverse document frequency for "word"
  #     doc.term_vectors["word"][:tfidf] = Float
  #   doc.term_vectors["otherword"]
  #   ...
  #
  attr_reader :term_vectors  
  
  
  
  # Look up an individual document with the given shasum.  If the fulltext
  # parameter is set to true, +document.fulltext+ and +document.term_vectors+
  # will be set.
  #
  # If a matching document cannot be found, then this function will raise a 
  # RecordNotFound exception.  Other, worse exceptions may be thrown out of
  # RSolr.
  #
  # This function returns a hash:
  #
  #   h = Document.find("1234567890abcdef", true)
  #   h[:document] = Document
  #   h[:query_time] = Float
  #
  def self.find(shasum, fulltext = false)
    solr = RSolr.connect :url => APP_CONFIG['solr_server_url']
    
    # This is the only method here that can fail -- if we get no response,
    # a bad response, or something that cannot be evaluated, then we have
    # trouble.  But we'll just let that exception percolate up and cause a
    # 500 error.
    query_type = fulltext ? "fulltext" : "precise"
    solr_response = solr.get('select', :params => { :qt => query_type, :q => "shasum:#{shasum}" })
    
    raise ActiveRecord::RecordNotFound unless solr_response["response"]
    raise ActiveRecord::RecordNotFound unless solr_response["response"]["numFound"]
    raise ActiveRecord::RecordNotFound if solr_response["response"]["numFound"] == 0
    raise ActiveRecord::RecordNotFound unless solr_response["response"]["docs"]
    
    # Get term vectors, if we're full-text
    term_vectors = nil
    if fulltext and solr_response["termVectors"]
      # The response format here is incredibly arcane and nearly useless,
      # turn it into something worthwhile
      tvec_array = solr_response["termVectors"][1][3]
      term_vectors = {}
      
      (0...tvec_array.length).step(2) do |i|
        term = tvec_array[i]
        attr_array = tvec_array[i+1]
        hash = {}
        
        (0...attr_array.length).step(2) do |j|
          key = attr_array[j]
          val = attr_array[j+1]
          
          case key
          when 'tf'
            hash[:tf] = Integer(val)
          when 'offsets'
            hash[:offsets] = []
            (0...val.length).step(4) do |k|
              s = Integer(val[k+1])
              e = Integer(val[k+3])
              hash[:offsets] << (s...e)
            end
          when 'positions'
            hash[:positions] = []
            (0...val.length).step(2) do |k|
              p = Integer(val[k+1])
              hash[:positions] << p
            end
          when 'df'
            hash[:df] = Float(val)
          when 'tf-idf'
            hash[:tfidf] = Float(val)
          end
        end
        
        term_vectors[term] = hash
      end
    end
    
    { :document => Document.new(solr_response["response"]["docs"][0], term_vectors),
      :query_time => Float(solr_response["responseHeader"]["QTime"]) / 1000.0 }
  end
  
  # Look up an array of documents from the given parameters structure.
  # Recognized here are the following:
  #
  #   # Solr query string
  #   :q => String
  #   # Solr faceted query (an array)
  #   :fq[] => Array[String]
  #   # If present, send query through Solr syntax, else the Dismax parser
  #   :precise => Nil?
  #   # Search query for authors
  #   :authors => String
  #   # Search query for title
  #   :title => String
  #   # Perform an exact or a stemmed title search?
  #   :title_type => String (exact|fuzzy)
  #   # Search query for journal
  #   :journal => String
  #   # Perform an exact or a stemmed journal search?
  #   :journal_type => String (exact|fuzzy)
  #   # Start year for year range
  #   :year_start => String
  #   # End year for year range
  #   :year_end => String
  #   # Search query for volume
  #   :volume => String
  #   # Search query for number
  #   :number => String
  #   # Search query for pages
  #   :pages => String
  #   # Search query for fulltext
  #   :fulltext => String
  #   # Perform an exact or a stemmed fulltext search?
  #   :fulltext_type => String (exact|fuzzy)
  #
  # This function returns a hash:
  #
  #   h = Document.find("1234567890abcdef", true)
  #   h[:documents] = Array[Document]
  #   h[:query_time] = Float
  #   h[:facets] = Hash
  #     h[:facets][:author]
  #     h[:facets][:journal]
  #     h[:facets][:year]
  #       h[:facets][...]["Facet Element"] = Integer
  #
  # On failure, this will simply return an empty +:documents+ array, and
  # will not throw an exception unless an RSolr error occurs.
  def self.search(params)
    solr = RSolr.connect :url => APP_CONFIG['solr_server_url']
    
    params.delete_if { |k, v| v.blank? }
    query_params = { :fq => params[:fq] }
    
    if params.has_key? :precise
      query_params[:qt] = "precise"
      query_params[:q] = "#{params[:q]} "
      
      %W(authors volume number pages).each do |f|
        query_params[:q] += " #{f}:(#{params[f.to_sym]})" if params[f.to_sym]
      end
      
      %W(title journal fulltext).each do |f|
        field = f
        field += "_search" if params[(f + "_type").to_sym] and params[(f + "_type").to_sym] == "fuzzy"
        query_params[:q] += " #{field}:(#{params[f.to_sym]})" if params[f.to_sym]
      end
      
      # Year has to be handled separately for range support
      if params[:year_start] or params[:year_end]
        year = params[:year_start]
        year ||= params[:year_end]
        if params[:year_start] and params[:year_end]
          year = "[#{params[:year_start]} TO #{params[:year_end]}]"
        end
        
        query_params[:q] += " year:(#{year})"
      end
      
      # If there's still no query, return all documents
      query_params[:q].strip!
      if query_params[:q].empty?
        query_params[:q] = "*:*"
      end
    else
      if not params.has_key? :q
        query_params[:q] = "*:*"
        query_params[:qt] = "precise"
      else
        query_params[:q] = params[:q]
      end
    end
    
    # See the note on solr.get in self.find
    solr_response = solr.get('select', :params => query_params)
    unless solr_response["response"] and solr_response["response"]["docs"]
      return { :documents => [], :query_time => 0, :facets => nil }
    end
    
    # Process the facet information
    facets = nil
    if solr_response["facet_counts"]
      facets = {}
      solr_facets = solr_response["facet_counts"]
      
      # The "year" facets are handled as separate queries
      if solr_facets["facet_queries"]
        facets[:year] = {}
        solr_facets["facet_queries"].each do |k, v|
          decade = k.slice(6..-1).split[0]
          decade = "1790" if decade == "*"
          facets[:year][decade] = v
        end
      end
      
      if solr_facets["facet_fields"]
        { "authors_facet" => :author, "journal_facet" => :journal }.each do |s, f|
          facets[f] = Hash[*solr_facets["facet_fields"][s].flatten]
        end
      end
    end
    
    { :documents => solr_response["response"]["docs"].collect { |doc| Document.new doc },
      :query_time => Float(solr_response["responseHeader"]["QTime"]) / 1000.0,
      :facets => facets }
  end
  
  # Initialize a new document from the provided Solr document result.
  #
  #   doc = Document.new(solr_response["response"]["docs"][0])
  #
  # If you want the document to contain term vectors, you
  # can pass those in, otherwise they will be nil by default.
  def initialize(solr_doc, term_vectors = nil)
    %W(shasum doi authors title journal year volume number pages fulltext).each do |k|
      if solr_doc[k]
        instance_variable_set("@#{k}", solr_doc[k])
      else
        instance_variable_set("@#{k}", "")
      end
    end
    
    @term_vectors = term_vectors
  end
  
  # Return the document's SHA-1 sum, which will function as the permanent
  # URL parameter for a document.
  def to_param
    shasum
  end  
  
  

  # Glue for making us act like an ActiveModel object
  extend ActiveModel::Naming
  
  def to_model
    self
  end
  
  def valid?()      true end
  def new_record?() true end
  def destroyed?()  true end
  
  def errors
    obj = Object.new
    def obj.[](key) [] end
    def obj.full_messages() [] end
    obj
  end
end
