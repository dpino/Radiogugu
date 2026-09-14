class CountriesController < ApplicationController
  def index
    @country = params[:id]
    @sort_order = get_order(params[:order])
    session[:sort_order] = @sort_order
    session[:active_tab] = :countries

    if @country.present?
      stations_in_country(@country)
      return
    end

    @sort_order ||= :alphabetic

    if @sort_order == :alphabetic
      countries_by_alphabetic_order
    else
      countries_by_continent_order
    end
  end

  def countries_by_continent_order
    countries_and_continents = Location.select("distinct(country),continent").order("continent")
    @countries_by_continent = to_countries_by_continent(countries_and_continents)
    respond_to do |format|
      format.html
      format.xml { render xml: @countries_by_continent }
    end
  end

  def get_order(order)
    case order
    when "continent" then :continent
    when "location" then :location
    else :alphabetic
    end
  end

  def countries_by_alphabetic_order
    countries = Location.select("country, count(country) as total").order(:country).group(:country)
    @countries_by_letter = to_countries_by_letter(countries)
    respond_to do |format|
      format.html { render action: "countries_by_alphabetic_order" }
      format.xml { render xml: @countries_by_letter }
    end
  end

  def to_countries_by_letter(countries)
    result = Hash.new
    countries.each do |country|
      letter = country.country[0, 1]
      result[letter] ||= Array.new
      result[letter] << country
    end
    result.sort
  end

  def stations_in_country(country)
    locations = Location.select("id, location").where("country = ?", country).order("location")

    @sort_order ||= :alphabetic

    @stations = if @sort_order == :location
      to_stations_by_location(locations)
    else
      to_stations_in_alphabetic_order(locations)
    end

    respond_to do |format|
      format.html { render action: "stations_in_country" }
      format.xml { render xml: @stations }
    end
  end

  def to_stations_in_alphabetic_order(locations)
    result = Hash.new
    locations.each do |location|
      stations = radios_in_location(location[:id])
      stations.each do |station|
        letter = station.name[0, 1]
        result[letter] ||= Array.new
        result[letter] << station
      end
    end
    result.sort
  end

  def to_stations_by_location(locations)
    result = Hash.new
    locations.each do |location|
      stations = radios_in_location(location[:id])
      city = location[:location]
      result[city] = stations
    end
    result.sort
  end

  def radios_in_location(location_id)
    all_radios = Radio.where(user_id: nil, location_id: location_id)
    return all_radios if current_user.nil?

    modified_by_user = Radio.where(user_id: current_user.id, location_id: location_id)
    return all_radios if modified_by_user.empty?

    other_radios = Radio.where(user_id: nil, location_id: location_id)
                         .where.not(id: parent_ids(modified_by_user))
    other_radios.to_a + modified_by_user.to_a
  end

  def parent_ids(radios)
    radios.map(&:parent_id)
  end

  # GET /countries/1
  def show
    @country = Location.where(country: params[:id])
    session[:active_tab] = :countries

    respond_to do |format|
      format.html
      format.xml { render xml: @country }
    end
  end

  def to_countries_by_continent(countries_and_continents)
    result = Hash.new
    countries_and_continents.each do |location|
      continent = location[:continent]
      result[continent] ||= Array.new
      result[continent] << location[:country]
    end
    result.sort
  end
end
