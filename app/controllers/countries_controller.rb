class CountriesController < ApplicationController

  # GET /locations
  # GET /locations.xml
  def index
      country = params[:id]
      if country != nil && country.size() > 0
        _show(country)
        return
      end
      countries_and_continents = Location.select("distinct(country),continent").order("continent");
      @countries_by_continent = to_hash(countries_and_continents);

      respond_to do |format|
          format.html # { render :action => "countries" }
          format.xml  { render :xml => @countries_by_continent}
      end
  end

  def _show(country)
    @country = Location.where("country = ?", country)

    respond_to do |format|
        format.html { render :action => "country" }
        format.xml  { render :xml => @countries.errors, :status => :unprocessable_entity }
    end
  end

  # GET /locations/countries
  # GET /locations/countries.xml
  def show
    country = params[:id]
    @country = Location.where("country = ?", country)

    respond_to do |format|
        format.html # show.html.erb
        format.xml  { render :xml => @country }
    end
  end

  def to_hash(countries_and_continents)
    result = Hash.new
    countries_and_continents.each { |location|
        continent = location[:continent]
        if (result[continent] == nil)
            result[continent] = Array.new
        end
        result[continent] << location[:country]
    }
    return result
  end

end
