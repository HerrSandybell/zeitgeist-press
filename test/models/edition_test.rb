require "test_helper"

class EditionTest < ActiveSupport::TestCase
  test "season enum defines all four values" do
    assert_equal({ "spring" => 0, "summer" => 1, "autumn" => 2, "winter" => 3 }, Edition.seasons)
  end

  test "invalid season raises ArgumentError" do
    assert_raises(ArgumentError) { Edition.new(season: :invalid_season) }
  end

  test "is valid with day at boundary values" do
    edition = editions(:one)

    edition.day = 1
    assert_predicate edition, :valid?

    edition.day = 90
    assert_predicate edition, :valid?
  end

  test "is invalid with day below 1" do
    edition = editions(:one)
    edition.day = 0
    assert_not edition.valid?
    assert_includes edition.errors[:day], "must be in 1..90"
  end

  test "is invalid with day above 90" do
    edition = editions(:one)
    edition.day = 91
    assert_not edition.valid?
    assert_includes edition.errors[:day], "must be in 1..90"
  end

  test "is invalid without year" do
    edition = editions(:one)
    edition.year = nil
    assert_not edition.valid?
    assert_includes edition.errors[:year], "can't be blank"
  end

  test "is invalid without season" do
    edition = editions(:one)
    edition.season = nil
    assert_not edition.valid?
    assert_includes edition.errors[:season], "can't be blank"
  end

  test "is invalid without day" do
    edition = editions(:one)
    edition.day = nil
    assert_not edition.valid?
    assert_includes edition.errors[:day], "can't be blank"
  end

  test "is invalid without volume" do
    edition = editions(:one)
    edition.volume = nil
    assert_not edition.valid?
    assert_includes edition.errors[:volume], "can't be blank"
  end

  test "is invalid without issue_number" do
    edition = editions(:one)
    edition.issue_number = nil
    assert_not edition.valid?
    assert_includes edition.errors[:issue_number], "can't be blank"
  end

  test "published defaults to false" do
    edition = Edition.new
    assert_equal false, edition.published
  end
end
