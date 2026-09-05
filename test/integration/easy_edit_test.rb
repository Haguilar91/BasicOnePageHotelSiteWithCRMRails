require "test_helper"

class EasyEditTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create_admin
    sign_in_as @admin
  end

  def sign_in_as(user, password: "password123")
    post user_session_path, params: { user: { email: user.email, password: password } }
  end

  test "edit form renders phone_number with checkboxes and a trash button" do
    phone = create_es(PhoneNumber, number: "+52 442 111 2222", label: "Recepción")
    get edit_easy_edit_path(resource: "phone_number", id: phone.id)
    assert_response :success
    assert_match "data-easy-edit-delete", response.body
    assert_match 'name="record[whatsapp_active]" value="0"', response.body
    assert_match 'type="checkbox"', response.body
  end

  test "update turns a boolean flag off" do
    phone = PhoneNumber.create!(number: "+52 442 111 2222", visible: true)
    patch easy_edit_path(resource: "phone_number", id: phone.id), params: { record: { visible: "0" } }
    assert_response :success
    assert_equal false, phone.reload.visible
  end

  test "flagging a whatsapp line clears the flag on every other row" do
    a = PhoneNumber.create!(number: "+52 1", whatsapp_active: true)
    b = PhoneNumber.create!(number: "+52 2")
    patch easy_edit_path(resource: "phone_number", id: b.id), params: { record: { whatsapp_active: "1" } }
    assert_response :success
    assert_equal false, a.reload.whatsapp_active
    assert_equal true, b.reload.whatsapp_active
  end

  test "destroy removes a deletable record" do
    phone = PhoneNumber.create!(number: "+52 442 111 2222")
    assert_difference("PhoneNumber.count", -1) do
      delete easy_edit_path(resource: "phone_number", id: phone.id)
    end
    assert_response :success
  end

  test "destroy is refused for page_content" do
    pc = PageContent.create!(key: "tmp_key")
    assert_no_difference("PageContent.count") do
      delete easy_edit_path(resource: "page_content", id: "tmp_key")
    end
    assert_response :forbidden
  end

  test "destroy is refused for a signed-in non-admin" do
    delete destroy_user_session_path
    sign_in_as create_user(email: "plain@example.com")

    phone = PhoneNumber.create!(number: "+52 442 111 2222")
    assert_no_difference("PhoneNumber.count") do
      delete easy_edit_path(resource: "phone_number", id: phone.id)
    end
    assert_response :forbidden
  end

  test "destroy is refused for a signed-out visitor" do
    delete destroy_user_session_path
    phone = PhoneNumber.create!(number: "+52 442 111 2222")
    assert_no_difference("PhoneNumber.count") do
      delete easy_edit_path(resource: "phone_number", id: phone.id)
    end
    assert_redirected_to new_user_session_path
  end

  test "the Avo screens for phone numbers render" do
    phone = create_es(PhoneNumber, number: "+52 442 000 0000", label: "Recepción")

    get "/avo/resources/phone_numbers"
    assert_response :success

    get "/avo/resources/phone_numbers/#{phone.id}/edit"
    assert_response :success
    assert_match "Línea de WhatsApp", response.body
  end
end
