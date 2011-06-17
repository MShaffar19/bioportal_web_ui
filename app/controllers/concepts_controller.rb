require 'cgi'

class ConceptsController < ApplicationController
  # GET /concepts
  # GET /concepts.xml
   
  layout 'ontology'

  # GET /concepts/1
  # GET /concepts/1.xml
  def show
    # Handle multiple methods of passing concept ids
    params[:id] = params[:id] ? params[:id] : params[:conceptid]
    too_many_children_override = params[:too_many_children_override].eql?("true")
    
    if params[:id].nil? || params[:id].empty?
      render :text => "Error: You must provide a valid concept id"
      return
    end
    
    if params[:callback].eql?('children') && params[:child_size].to_i > $MAX_CHILDREN && !too_many_children_override
      retry_link = "<a class='too_many_children_override' href='/ajax_concepts/#{params[:ontology]}/?conceptid=#{CGI.escape(params[:id])}&callback=children&too_many_children_override=true'>Get all terms</a>"      
      render :text => "<div style='background: #eeeeee; padding: 5px; width: 80%;'>There are #{params[:child_size]} terms at this level. Retrieving these may take several minutes. #{retry_link}</div>"
      return
    end
    
    @ontology = DataAccess.getOntology(params[:ontology])

    if @ontology.statusId.to_i.eql?(6)
      @latest_ontology = DataAccess.getLatestOntology(@ontology.ontologyId)
      params[:ontology] = @latest_ontology.id
      flash[:notice] = "The version of <b>#{@ontology.displayLabel}</b> you were attempting to view (#{@ontology.versionNumber}) has been archived and is no longer available for exploring. You have been redirected to the most recent version (#{@latest_ontology.versionNumber})."
      concept_id = params[:id] ? "?conceptid=#{params[:id]}" : ""
      redirect_to "/visualize/#{@latest_ontology.id}#{concept_id}", :status => :moved_permanently
      return
    end
    
    # If we're looking for children, just use the light version of the call
    if params[:callback].eql?("children")
      if too_many_children_override
        @concept = DataAccess.getNode(params[:ontology], params[:id], nil)
      else
        @concept = DataAccess.getNode(params[:ontology], params[:id])
      end
    else
      @concept = DataAccess.getNode(params[:ontology], params[:id])
    end

    # TODO: This should use a proper error-handling technique with custom exceptions
    if @concept.nil?
      @error = "The requested term could not be found."

      if request.xhr?
        render :text => @error
        return
      else
        render :file=> '/ontologies/visualize',:use_full_path => true, :layout => 'ontology' # done this way to share a view
        return
      end
    end

    # This handles special cases where a passed concept id is for a concept
    # that isn't browsable, usually a property for an ontology.
    if !@concept.is_browsable
      render :partial => "shared/not_browsable", :layout => "ontology"
      return
    end
    
    if request.xhr?
      show_ajax_request # process an ajax call
    else
      # We only want to log concept loading, not showing a list of child concepts
      LOG.add :info, 'visualize_concept_direct', request, :ontology_id => @ontology.id, :virtual_id => @ontology.ontologyId, :ontology_name => @ontology.displayLabel, :concept_name => @concept.label, :concept_id => @concept.id if @concept && @ontology

      show_uri_request # process a full call
      render :file=> '/ontologies/visualize',:use_full_path =>true, :layout=>'ontology' # done this way to share a view
    end
  end
  
  def virtual
    # Hack to make ontologyid and conceptid work in addition to id and ontology params
    params[:id] = params[:id].nil? ? params[:conceptid] : params[:id]
    params[:ontology] = params[:ontology].nil? ? params[:ontologyid] : params[:ontology]

    if !params[:id].nil? && params[:id].empty?
      params[:id] = nil
    end

    @ontology = DataAccess.getLatestOntology(params[:ontology])
    @versions = DataAccess.getOntologyVersions(@ontology.ontologyId)
    unless params[:id].nil? || params[:id].empty?
      @concept = DataAccess.getNode(@ontology.id,params[:id])
    end
    
    if @ontology.metadata_only?
      redirect_to "/ontologies/#{@ontology.id}"
      return
    end
    
    if @ontology.statusId.to_i.eql?(3) && @concept
      LOG.add :info, 'show_virtual_concept', request, :virtual_id => @ontology.ontologyId, :ontology_name => @ontology.displayLabel, :concept_name => @concept.label, :concept_id => @concept.id
      redirect_to "/visualize/#{@ontology.id}/?conceptid=#{CGI.escape(@concept.id)}"
      return
    elsif @ontology.statusId.to_i.eql?(3)
      LOG.add :info, 'show_virtual', request, :virtual_id => @ontology.ontologyId, :ontology_name => @ontology.displayLabel
      redirect_to "/visualize/#{@ontology.id}"
      return
    else
      for version in @versions
        if version.statusId.to_i.eql?(3) && @concept
          LOG.add :info, 'show_virtual_concept', request, :virtual_id => @ontology.ontologyId, :ontology_name => @ontology.displayLabel, :concept_name => @concept.label, :concept_id => @concept.id
          redirect_to "/visualize/#{version.id}/?conceptid=#{CGI.escape(@concept.id)}"
          return
        elsif version.statusId.to_i.eql?(3)
          LOG.add :info, 'show_virtual', request, :virtual_id => @ontology.ontologyId, :ontology_name => @ontology.displayLabel
          redirect_to "/visualize/#{version.id}"
          return
        end
      end
      redirect_to "/ontologies/#{@ontology.id}"
      return
    end
  end
  
  # Renders a details pane for a given ontology/term
  def details
    @ontology = DataAccess.getOntology(params[:ontology])
    @concept = DataAccess.getNode(@ontology.id, params[:conceptid], params[:childrenlimit])
    
    if params[:styled].eql?("true")
      render :partial => "details", :layout => "partial"
    else
      render :partial => "details"
    end
  end
  
  def exhibit
    time = Time.now
    #puts "Starting Retrieval"
    @concept =  DataAccess.getNode(params[:ontology],params[:id])
    #puts "Finished in #{Time.now- time}"
    
    string =""
    string << "{
           \"items\" : [\n
       	{ \n
       \"title\": \"#{@concept.label}\" , \n
       \"label\": \"#{@concept.id}\" \n"
    for property in @concept.properties.keys
      if @concept.properties[property].empty?
        next
      end
      
      string << " , "
      
      string << "\"#{property.gsub(":","")}\" : \"#{@concept.properties[property]}\"\n"
      
    end
    
    if @concept.children.length > 0
      string << "} , \n"
    else
      string << "}"
    end
    
    
    for child in @concept.children
      string << "{
         \"title\" : \"#{child.label}\" , \n
         \"label\": \"#{child.id}\"  \n"
      for property in child.properties.keys
        if child.properties[property].empty?
          next
        end
        
        string << " , "        
        
        string << "\"#{property.gsub(":","")}\" : \"#{child.properties[property]}\"\n"
      end
      if child.eql?(@concept.children.last)
        string << "}"
      else
        string << "} , "
      end
    end
    
    response.headers['Content-Type'] = "text/html" 
    
    string<< "]}"
    
    render :text=> string
  end


  
  # PRIVATE -----------------------------------------
  private
    
  def show_ajax_request
    case params[:callback]
    when 'load' # Load pulls in all the details of a node
      time = Time.now
      gather_details
      LOG.add :debug, "Processed concept details (#{Time.now - time})"

      # We only want to log concept loading, not showing a list of child concepts
      LOG.add :info, 'visualize_concept_browse', request, :ontology_id => @ontology.id, :virtual_id => @ontology.ontologyId, :ontology_name => @ontology.displayLabel, :concept_name => @concept.label, :concept_id => @concept.id if @concept && @ontology

      render :partial => 'load'
    when 'children' # Children is called only for drawing the tree
      @children =[]
      start_tree = Time.now
      for child in @concept.children
        @children << TreeNode.new(child, @concept)
        @children.sort!{|x,y| x.label.downcase<=>y.label.downcase} unless @children.empty?
      end
      LOG.add :debug,  "Get children (#{Time.now - start_tree})"
      render :partial => 'childNodes'
    end
  end
    
    # gathers the full set of data for a node
    def show_uri_request
      gather_details
      build_tree
    end
    
    # gathers the information for a node
    def gather_details
      @mappings = DataAccess.getConceptMappings(@concept.ontology.ontologyId, @concept.id)    
      update_tab(@ontology, @concept.id) #updates the 'history' tab with the current node
    end
    
    def build_tree
      # find path to root    
      rootNode = @concept.path_to_root
      @root = TreeNode.new()
      @root.set_children(rootNode.children, rootNode)
    end
 
  
end
