class GendersController < ApplicationController

  # GET /genders
  # GET /genders.xml
  def index
    @genders = Gender.all
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @genders }
    end

  end

  # GET /genders/:id
  # GET /genders/:id.xml
  def show

  end

  # POST /genders
  # POST /genders.xml
  def create

  end

  # GET /genders/new
  # GET /genders/new.xml
  def new

  end

  # GET /genders/:id/edit
  # GET /genders/:id/edit.xml
  def edit

  end

  # PUT /genders/:id
  # PUT /genders/:id.xml
  def update

  end

  # DELETE /genders/:id
  # DELETE /genders/:id.xml
  def destroy

  end

end
