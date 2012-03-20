class Admin::ProviderController < ApplicationController
  include ApplicationHelper
 layout 'admin'
  before_filter :authorize, :except => 'login',
    :role => 'administator', 
    :msg => 'Access to this page is restricted.'

  def index
    list
    render :action => 'list'
  end
  
  def initialize
    super
    seek = SearchController.new();
    @filter_tab = SearchTabFilter.load_filter;
    @linkMenu = seek.load_menu;
    @groups_tab = SearchTab.load_groups;
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => "post", :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @provider_pages, @providers = paginate :providers, :per_page => 20, :order => 'provider_name asc'
    @display_columns = ['provider_name', 'title']
  end 

  def show
    @provider = Provider.find(params[:id])
  end

  def new
    @provider = Provider.new
  end

  def create
    @provider = Provider.new(params[:provider])
    if @provider.save
      flash[:notice] = translate('PROVIDER_CREATED')
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @provider = Provider.find(params[:id])
  end

  def update
    @provider = Provider.find(params[:id])
    if @provider.update_attributes(params[:provider])
      flash[:notice] = translate('PROVIDER_UPDATED')
      redirect_to :action => 'show', :id => @provider
    else
      render :action => 'edit'
    end
  end

  def destroy
    Provider.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
