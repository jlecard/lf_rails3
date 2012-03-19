class Admin::DocumentTypesController < ApplicationController

  layout 'libraryfind'
  before_filter :authorize, :except => 'login',
    :role => 'admin', 
    :msg => 'Access to this page is restricted.'
  
  def initialize
    super
    seek = SearchController.new();
    @filter_tab = seek.load_filter;
    @linkMenu = seek.load_menu;
    @groups_tab = seek.load_groups;
  end

  # GET /document_types
  # GET /document_types.xml
  def index
    @document_types = DocumentType.find_by_sql("SELECT document_types.id, document_types.name, collections.alt_name AS collection_name, primary_document_types.name AS primary_document_type_name 
                                                FROM collections, document_types, primary_document_types
                                                WHERE collections.id = document_types.collection_id
                                                  AND primary_document_types.id = document_types.primary_document_type")
   
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @document_types }
    end
  end

  # GET /document_types/1
  # GET /document_types/1.xml
  def show
    @document_type = DocumentType.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @document_type }
    end
  end

  # GET /document_types/new
  # GET /document_types/new.xml
  def new
    @document_type = DocumentType.new
    @primary_document_types = PrimaryDocumentType.find(:all)
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @document_type }
    end
  end

  # GET /document_types/1/edit
  def edit
    @document_type = DocumentType.find(params[:id])
    @primary_document_types = PrimaryDocumentType.find(:all)

  end

  # POST /document_types
  # POST /document_types.xml
  def create
    @document_type = DocumentType.new(params[:document_type])

    respond_to do |format|
      if @document_type.save
        flash[:notice] = 'DocumentType was successfully created.'
        format.html { redirect_to(:action => 'index') }
        format.xml  { render :xml => @document_type, :status => :created, :location => @document_type }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @document_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /document_types/1
  # PUT /document_types/1.xml
  def update
    @document_type = DocumentType.find(params[:id])
    
    respond_to do |format|
      
      if !@document_type.nil? and !params[:document_type][:primary_document_type].nil?
        @document_type.primary_document_type = params[:document_type][:primary_document_type]
        @document_type.save
        flash[:notice] = translate('UPDATE_SUCCESS')
        format.html { redirect_to(:action=> 'index') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @document_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /document_types/1
  # DELETE /document_types/1.xml
  def destroy
    @document_type = DocumentType.find(params[:id])
    @document_type.destroy

    respond_to do |format|
      format.html { redirect_to(:action => 'index') }
      format.xml  { head :ok }
    end
  end
end
