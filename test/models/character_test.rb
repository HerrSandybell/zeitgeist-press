require "test_helper"

class CharacterTest < ActiveSupport::TestCase
  test "valid with name and emoji" do
    character = Character.new(name: "Constable Harrow", emoji: "🕵️")
    assert character.valid?
  end

  test "invalid without name" do
    character = Character.new(emoji: "🕵️")
    assert_not character.valid?
    assert_includes character.errors[:name], "can't be blank"
  end

  test "invalid without emoji" do
    character = Character.new(name: "Constable Harrow")
    assert_not character.valid?
    assert_includes character.errors[:emoji], "can't be blank"
  end
end
