module ApplicationHelper

DOUBLE_ARROW = " >> "

def location_breadcrumb(location_id)
    location = Location.find(location_id)

    continent = location[:continent]
    continent_url = link_to continent, url_for(:controller => "countries", :order => "continent") + "##{continent}"

    country = location[:country]
    country_url = link_to country, url_for(:controller => "countries", :id => country)

    location = location[:location]
    # FIXME: The generated URL depdens on the sort order, need to store it in the session
    location_url = link_to location, url_for(:controller => "countries", :order => "location", :id=> country) + "#" + location

    return continent_url + DOUBLE_ARROW + country_url + DOUBLE_ARROW + location_url
end

end
