class CountriesController < ApplicationController

  # GET /locations
  # GET /locations.xml
  def index
    country = params[:id]
    if country != nil && country.size() > 0
      show_country(country)
      return
    end

    @sort_order = get_order(params[:order])
    if @sort_order == :alphabetic
      countries_by_alphabetic_order()
      return
    end

    countries_and_continents = Location.select("distinct(country),continent").order("continent")
    @countries_by_continent = to_countries_by_continent(countries_and_continents)

    respond_to do |format|
        format.html # { render :action => "countries" }
        format.xml  { render :xml => @countries_by_continent}
    end
  end

  def get_order(order)
    if order != nil
      if order == "alphabetic"
        return :alphabetic
      end
      if order == "by_continent"
        return :by_continent
      end
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

  def show_country(country)
    @locations = Location.select("id, location").where("country = ?", country).order("location")
      @radios_by_location = to_radios_by_location(@locations)

    respond_to do |format|
        format.html { render :action => "locations" }
        format.xml  { render :xml => @countries.errors, :status => :unprocessable_entity }
    end
  end

  def to_radios_by_location(locations)
    result = Hash.new
    locations.each {|location|
        radios = Radio.where("location_id = ?", location[:id])
        city = location[:location]
        result[city] = radios
    }
    return result.sort
  end

  # GET /locations/countries
  # GET /locations/countries.xml
  def show
    @country = Location.where("country = ?", country)

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
