require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "an email and a password of at least six characters are required" do
    assert create_user.valid?
    assert_not User.new(password: "password123").valid?
    assert_not User.new(email: "a@example.com").valid?
    assert_not User.new(email: "a@example.com", password: "short").valid?
  end

  test "emails are unique and must look like emails" do
    create_user(email: "admin@example.com")

    assert_not User.new(email: "admin@example.com", password: "password123").valid?
    assert_not User.new(email: "not-an-email", password: "password123").valid?
  end

  test "accounts are not admins unless told otherwise" do
    assert_not create_user.admin?
    assert create_admin.admin?
  end

  test "avo_preferences round-trips as a hash" do
    user = create_user
    user.update!(avo_preferences: { "sidebar" => "collapsed" })

    assert_equal({ "sidebar" => "collapsed" }, user.reload.avo_preferences)
  end
end
