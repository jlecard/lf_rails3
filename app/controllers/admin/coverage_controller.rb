class Admin::CoverageController < ApplicationController
  include ApplicationHelper
  layout 'admin'
  before_filter :authorize, :except => 'login',
    :role => 'administrator', 
    :msg => 'Access to this page is restricted.'
  
  def initialize
    super
    seek = SearchController.new();
    @filter_tab = SearchTabFilter.load_filter;
    @linkMenu = seek.load_menu;
    @groups_tab = SearchTab.load_groups;
  end

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => "post", :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @coverage_pages, @coverages = paginate :coverages, :per_page => 20, :order => 'journal_title asc'
        @display_columns = ['journal_title', 'provider', 'start_date', 'end_date']
  end

  def show
    @coverage = Coverage.find(params[:id])
  end

  def new
    @coverage = Coverage.new
  end

  def create
    @coverage = Coverage.new(params[:coverage])
    if @coverage.save
      flash[:notice] = translate('COVERAGE_CREATED')
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @coverage = Coverage.find(params[:id])
  end

  def update
    @coverage = Coverage.find(params[:id])
    if @coverage.update_attributes(params[:coverage])
      flash[:notice] = translate('COVERAGE_UPDATED')
      redirect_to :action => 'show', :id => @coverage
    else
      render :action => 'edit'
    end
  end

  def destroy
    Coverage.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
