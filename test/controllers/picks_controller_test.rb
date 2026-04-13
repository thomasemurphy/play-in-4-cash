require "test_helper"

class PicksControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get picks_index_url
    assert_response :success
  end
end
