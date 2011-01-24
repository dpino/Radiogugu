class CountriesController < ApplicationController

  # GET /locations
  # GET /locations.xml
  def index
      country = params[:id]
      if country != nil && country.size() > 0
        _show(country)
        return
      end
      countries_and_continents = Location.select("distinct(country),continent").order("continent")
      @countries_by_continent = to_countries_by_continent(countries_and_continents)

      respond_to do |format|
          format.html # { render :action => "countries" }
          format.xml  { render :xml => @countries_by_continent}
      end
  end

  def _show(country)
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
