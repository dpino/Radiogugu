class CountriesController < ApplicationController

  # GET /locations
  # GET /locations.xml
  def index
    @country = params[:id]
    @sort_order = get_order(params[:order])
    session[:sort_order] = @sort_order
    session[:active_tab] = :countries

    if @country != nil && @country.size() > 0
      stations_in_country(@country)
      return
    end

    # Default order
    if @sort_order == nil
      @sort_order = :alphabetic
    end

    if @sort_order == :alphabetic
      countries_by_alphabetic_order()
    else
      countries_by_continent_order()
    end
  end

  def countries_by_continent_order()
    countries_and_continents = Location.select("distinct(country),continent").order("continent")
    @countries_by_continent = to_countries_by_continent(countries_and_continents)
    respond_to do |format|
      format.html # { render :action => "countries" }
      format.xml  { render :xml => @countries_by_continent}
    end
  end

  def get_order(order)
    # Default
    if order == nil
      return :alphabetic
    end

    if order == "alphabetic"
      return :alphabetic
    end
    if order == "continent"
      return :continent
    end
    if order == "location"
      return :location
    end
  end

  def countries_by_alphabetic_order()
    countries = Location.select("country, count(country) as total").order(:country).group(:country)
    @countries_by_letter = to_countries_by_letter(countries)
    respond_to do |format|
        format.html { render :action => "countries_by_alphabetic_order" }
        format.xml  { render :xml => countries.errors, :status => :unprocessable_entity }
    end
  end

  def to_countries_by_letter(countries)
    result = Hash.new
    countries.each {|country|
      letter = country.country[0,1]
      if (result[letter] == nil)
        result[letter] = Array.new
      end
      result[letter] << country
    }
    return result.sort
  end

  def stations_in_country(country)
    locations = Location.select("id, location").where("country = ?", country).order("location")

    # Default order
    if @sort_order == nil
      @sort_order = :alphabetic
    end

    if @sort_order == :location
      @stations = to_stations_by_location(locations)
    else
      @stations = to_stations_in_alphabetic_order(locations)
    end

    respond_to do |format|
        format.html { render :action => "stations_in_country" }
        format.xml  { render :xml => @countries.errors, :status => :unprocessable_entity }
    end
  end

  def to_stations_in_alphabetic_order(locations)
    result = Hash.new
    locations.each {|location|
      stations = Radio.where("location_id = ?", location[:id])
      stations.each {|station|
        letter = station.name[0,1]
        if (result[letter] == nil)
          result[letter] = Array.new
        end
        result[letter] << station
      }
    }
    return result.sort
  end

  def to_stations_by_location(locations)
    result = Hash.new
    locations.each {|location|
      stations = Radio.where("location_id = ?", location[:id])
      city = location[:location]
      result[city] = stations
    }
    return result.sort
  end

  # GET /locations/countries
  # GET /locations/countries.xml
  def show
    @country = Location.where("country = ?", country)
    session[:active_tab] = :countries

    respond_to do |format|
        format.html # show.html.erb
        format.xml  { render :xml => @country }
    end
  end

  def to_countries_by_continent(countries_and_continents)
    result = Hash.new
    countries_and_continents.each { |location|
        continent = location[:continent]
        if (result[continent] == nil)
            result[continent] = Array.new
        end
        result[continent] << location[:country]
    }
    return result.sort
  end

end
