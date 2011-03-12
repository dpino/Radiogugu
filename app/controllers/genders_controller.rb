class GendersController < ApplicationController

  # GET /genders
  # GET /genders.xml
  def index
    @genders = Gender.all
    session[:active_tab] = :genders
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @genders }
    end

  end

  # GET /genders/:id
  # GET /genders/:id.xml
  def show
    gender_id = params[:id]
    @gender = Gender.find(gender_id)

    radios = @gender.radios
    @radios_by_country = to_radios_by_country(radios)
    @total_radios = radios.size
    @total_countries = @radios_by_country.size

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @genders }
    end
  end

  def to_radios_by_country(radios)
    result = Hash.new
    radios.each { |radio|
      location = Location.find(radio.location_id)
      country = location.country
      if (result[country] == nil)
        result[country] = Array.new
      end
      radio.location_str = location.location
      result[country] << radio
    }
    return result.sort
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
