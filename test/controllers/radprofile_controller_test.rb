require "test_helper"

class RadprofileControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get radprofile_new_url
    assert_response :success
  end

  test "should get show" do
    get radprofile_show_url
    assert_response :success
  end
end
