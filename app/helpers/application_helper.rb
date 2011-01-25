module ApplicationHelper

DOUBLE_ARROW = " >> "

def location_breadcrumb(location_id)
    location = Location.find(location_id)
    return location[:continent] + DOUBLE_ARROW + location[:country] + DOUBLE_ARROW + location[:location]
end

end
