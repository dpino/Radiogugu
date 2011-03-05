module ApplicationHelper

  DOUBLE_ARROW = " >> "

  def location_breadcrumb(station)
    location = Location.find(station.location_id)
    order = session[:sort_order]

    continent_url = continent_url(location[:continent])
    country_url = country_url(location[:country], order)
    location_url = location_url(location[:location], station.name, location[:country], order)

    return continent_url + DOUBLE_ARROW + country_url + DOUBLE_ARROW + location_url + DOUBLE_ARROW + station.name
  end

  def country_breadcrumb(country_name)
    locations = Location.where(:country => country_name).limit(1)
    if locations.empty?
      return "";
    end
    location = locations[0];
    order = session[:sort_order]

    continent_url = continent_url(location[:continent])
    country_url = country_url(location[:country], order)

    return continent_url + DOUBLE_ARROW + country_url
  end

  def continent_url(continent)
    return link_to continent, url_for(:controller => "countries", :order => "continent") + "##{continent}"
  end

  def country_url(country, order)
    return link_to country, url_for(:controller => "countries", :order => order, :id => country)
  end

  def location_url(location, station_name, country, order)
    if order == :alphabetic
      return link_to location, url_for(:controller => "countries", :order => "alphabetic", :id => country) + "#" + station_name[0,1]
    else
      return link_to location, url_for(:controller => "countries", :order => "location", :id => country) + "#" + location
    end
  end

  def distance_of_time_until_today(time)
    now = Time.now
    return distance_of_time_in_words(time, now)
  end

end
