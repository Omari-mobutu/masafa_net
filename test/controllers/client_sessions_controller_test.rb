require "test_helper"

class ClientSessionsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get client_sessions_index_url
    assert_response :success
  end
end
