require "test_helper"

class NewspaperTest < ActiveSupport::TestCase
  test "is invalid without name" do
    newspaper = Newspaper.new(name: nil)
    assert_not newspaper.valid?
    assert_includes newspaper.errors[:name], "can't be blank"
  end

  test "is valid with name" do
    assert_predicate newspapers(:one), :valid?
  end

  test "has many editions" do
    association = Newspaper.reflect_on_association(:editions)
    assert_equal :has_many, association.macro
  end

  test "slug parameterizes the name" do
    newspaper = Newspaper.new(name: "Pryce of Progress")
    assert_equal "pryce-of-progress", newspaper.slug
  end

  test "slug handles punctuation and ampersands" do
    newspaper = Newspaper.new(name: "The Times & Echo")
    assert_equal "the-times-echo", newspaper.slug
  end
end
