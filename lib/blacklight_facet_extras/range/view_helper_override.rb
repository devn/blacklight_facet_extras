module BlacklightFacetExtras::Range::ViewHelperOverride

    def render_facet_limit(solr_field)
      config = facet_range_config(solr_field)
      if ( config )
        render(:partial => "catalog/_facet_partials/range", :locals=> {:solr_field => solr_field })
      else
        super(solr_field)
      end
    end
    def solr_range_to_a(solr_field)
      config = facet_range_config(solr_field)
      return RSolr::Ext::Response::Facets::FacetField.new(solr_field,[]) unless config and @response and @response["facet_counts"] and @response["facet_counts"]["facet_ranges"] and @response["facet_counts"]["facet_ranges"][solr_field]

      data = @response["facet_counts"]["facet_ranges"][solr_field]

      arr = []

      arr << BlacklightFacetExtras::Range::FacetItem.new("before", data[:before], :from => '*', :to => data[:start]) if data[:before] > 0

      last = 0
      range = data[:counts].each_slice(2).map { |value, hits| BlacklightFacetExtras::Range::FacetItem.new(value,hits) }

      if range.length > 1
      
      range.each_cons(2) do |item, peek| 
        item.from = item.value
        item.to = peek.value
        item.display_label = "#{item.from} - #{item.to}"
        arr << item
      end

      arr << range.last.tap { |x| x.from = x.value; x.to = data[:end]; x.display_label = "#{x.from} - #{x.to}" }
      end

      arr << BlacklightFacetExtras::Range::FacetItem.new("after", data[:after], :from => data[:end], :to => '*') if data[:after] > 0
      RSolr::Ext::Response::Facets::FacetField.new(solr_field, arr)
    end

    def render_facet_value(facet_solr_field, item, options ={})
      if item.is_a? BlacklightFacetExtras::Range::FacetItem
        (link_to_unless(options[:suppress_link], item.display_label || item.value , add_facet_params_and_redirect(facet_solr_field, item.value), :class=>"facet_select label") + " " + render_facet_count(item.hits)).html_safe
      else
        super(facet_solr_field, item, options ={})
      end
    end
end
