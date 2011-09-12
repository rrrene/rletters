require 'test_helper'

class UserTest < ActiveSupport::TestCase

  # Test validation: require identifier, name and e-mail
  test "should not save empty user" do
    user = User.new
    assert !user.save, 'Saved an empty user'
  end
  
  test "should not save without identifier" do
    user = User.new
    user.name = 'John Doe'
    user.email = 'bob@bob.com'
    assert !user.save, 'Saved a user without identifier set'
  end
  
  test "should not save without name" do
    user = User.new
    user.email = 'bob@bob.com'
    user.identifier = 'https://google.com'
    assert !user.save, 'Saved a user without name set'
  end
  
  test "should not save without email" do
    user = User.new
    user.name = 'John Doe'
    user.identifier = 'https://google.com'
    assert !user.save, 'Saved a user without email set'
  end

  # Validations on email field: no duplicates, valid emails
  test "should not save duplicate email" do
    user = User.new
    user.name = 'Email Test User'
    user.identifier = 'https://google.com/notduplicate'
    user.email = 'jdoe@gmail.com'
    assert !user.save, 'Saved a user with a duplicate email'
  end

  test "should not save bad email" do
    user = User.new
    user.name = 'Email Test User'
    user.identifier = 'https://google.com/notduplicate'
    user.email = 'asdf-not-an-email.com'
    assert !user.save, 'Saved a user with a clearly invalid email'
  end

  # Validations on identifier: unique, needs to be a URL
  test "should not save duplicate identifier" do
    user = User.new
    user.name = 'ID test user'
    user.identifier = 'https://google.com/profiles/johndoe'
    user.email = 'notduplicate@gmail.com'
    assert !user.save, 'Saved a user with a duplicate identifier'
  end

  test "should not save non-URL identifier" do
    user = User.new
    user.name = 'ID test user'
    user.identifier = 'thisisnotaurl'
    user.email = 'notduplicate@gmail.com'
    assert !user.save, 'Saved a user with a non-URL identifier'
  end

  # Parsing of the response from RPX: should return a non-new
  # record for a user we already have
  test "should return existing user from RPX" do
    hash = {
      'name' => 'John Doe',
      'email' => 'jdoe@gmail.com',
      'identifier' => 'https://google.com/profiles/johndoe' }
    user = User.find_or_initialize_with_rpx(hash)
    assert !user.new_record?
  end

  # Should return a new record for a new user
  test "should return new user from RPX" do
    hash = {
      'name' => 'New Guy',
      'email' => 'new@guy.com',
      'identifier' => 'https://newguy.com' }
    user = User.find_or_initialize_with_rpx(hash)
    assert user.new_record?
  end
end