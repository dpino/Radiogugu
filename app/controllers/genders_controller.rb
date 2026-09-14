class GendersController < ApplicationController
  def index
    @genders = Gender.all
    session[:active_tab] = :genders
    respond_to do |format|
      format.html
      format.xml { render xml: @genders }
    end
  end

  def show
    gender_id = params[:id]
    @gender = Gender.find(gender_id)

    radios = @gender.radios
    @radios_by_country = to_radios_by_country(radios)
    @total_radios = radios.size
    @total_countries = @radios_by_country.size

    respond_to do |format|
      format.html
      format.xml { render xml: @gender }
    end
  end

  def to_radios_by_country(radios)
    result = Hash.new
    radios.each do |radio|
      next if radio.location_id.nil?

      location = Location.find_by(id: radio.location_id)
      next if location.nil?

      country = location.country
      result[country] ||= Array.new
      radio.location_str = location.location
      result[country] << radio
    end
    result.sort
  end

  def create
  end

  def new
  end

  def edit
  end

  def update
  end

  def destroy
  end
end
