require "test_helper"

class CommentTest < ActiveSupport::TestCase
  test "valid with edition, character, and body" do
    comment = Comment.new(
      edition:   editions(:one),
      character: characters(:harrow),
      body:      "The Guild's silence speaks louder than any testimony."
    )
    assert comment.valid?
  end

  test "invalid without body" do
    comment = Comment.new(edition: editions(:one), character: characters(:harrow))
    assert_not comment.valid?
    assert_includes comment.errors[:body], "can't be blank"
  end

  test "invalid without edition" do
    comment = Comment.new(character: characters(:harrow), body: "Test.")
    assert_not comment.valid?
  end

  test "invalid without character" do
    comment = Comment.new(edition: editions(:one), body: "Test.")
    assert_not comment.valid?
  end

  test "invalid when body exceeds 280 characters" do
    comment = Comment.new(
      edition:   editions(:one),
      character: characters(:harrow),
      body:      "x" * 281
    )
    assert_not comment.valid?
    assert_includes comment.errors[:body], "is too long (maximum is 280 characters)"
  end

  test "valid when body is exactly 280 characters" do
    comment = Comment.new(
      edition:   editions(:one),
      character: characters(:harrow),
      body:      "x" * 280
    )
    assert comment.valid?
  end
end
