require 'test_helper'

class RatingsControllerTest < ActionController::TestCase
  test "should get rate" do
    get :rate
    assert_response :success
  end

end
