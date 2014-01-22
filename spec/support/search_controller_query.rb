# -*- encoding : utf-8 -*-

# Helper methods for making complex Solr queries
module SearchControllerQuery
  def do_solr_query(q = nil, fq = nil, precise = false, other_params = {})
    assign(:page, 0)
    assign(:per_page, 10)

    controller.params[:q] = q
    controller.params[:fq] = fq
    controller.params[:precise] = precise
    controller.params.merge!(other_params)

    solr_query = SearchController.new.send(:search_params_to_solr_query, controller.params)
    assign(:solr_q, solr_query[:q])
    assign(:solr_def_type, solr_query[:def_type])
    assign(:solr_fq, solr_query[:fq])

    assign(:sort, params[:sort] || 'score desc')

    result = RLetters::Solr::Connection.search(solr_query)
    assign(:result, result)
    assign(:documents, result.documents)
  end
end
