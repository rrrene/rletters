# coding: UTF-8


# Implement the unAPI protocol for talking to some bibliography managers,
# including (in particular) Zotero.
class UnapiController < ApplicationController
  
  # Show the formats which we support for export.
  def index
    if params[:id]
      hash_to_instance_variables Document.find(params[:id], true, nil)
      
      if params[:format]
        get_item params[:id], params[:format]
      else
        render :template => 'unapi/formats.xml.builder', :layout => false, :status => 300
      end
    else
      render :template => 'unapi/formats.xml.builder', :layout => false
    end
  end
  
  # Get a particular export format, by passing through to the exports
  # controller.
  def get_item(id, format)
    unless ExportsController.method_defined? format.to_sym
      render :file => "#{RAILS_ROOT}/public/404.html", :layout => false, :status => 406
    else
      redirect_to send("#{format}_document_export_path", :document_id => id)
    end
  end
end
                                                               