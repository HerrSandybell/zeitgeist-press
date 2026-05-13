require "application_system_test_case"

class CommentsTest < ApplicationSystemTestCase
  setup do
    @edition   = editions(:one)
    @newspaper = @edition.newspaper
    visit newspaper_edition_path(@newspaper, @edition)
  end

  test "posting a comment appends it to the thread without a full page reload" do
    select "#{characters(:harrow).emoji} #{characters(:harrow).name}",
           from: "comment[character_id]"
    fill_in "comment[body]", with: "The Guild's silence speaks louder than any testimony."
    click_button "Post Comment"

    assert_selector ".comment-bubble .comment-bubble__name",
                    text: /#{Regexp.escape(characters(:harrow).name)}/i, wait: 5
    assert_selector ".comment-bubble .comment-bubble__text",
                    text: "The Guild's silence speaks louder than any testimony."
  end

  test "body textarea is cleared after posting" do
    select "#{characters(:harrow).emoji} #{characters(:harrow).name}",
           from: "comment[character_id]"
    fill_in "comment[body]", with: "Test message."
    click_button "Post Comment"

    assert_selector ".comment-bubble", wait: 5
    assert_field "comment[body]", with: ""
  end

  test "submitting with an empty body shows a validation error" do
    initial_count = all(".comment-bubble").count
    select "#{characters(:harrow).emoji} #{characters(:harrow).name}",
           from: "comment[character_id]"
    click_button "Post Comment"

    assert_selector "#comment-errors", text: /can't be blank/i, wait: 5
    assert_equal initial_count, all(".comment-bubble").count
  end

  test "new comment is broadcast to a second browser session" do
    using_session(:viewer) do
      visit newspaper_edition_path(@newspaper, @edition)
    end

    using_session(:commenter) do
      visit newspaper_edition_path(@newspaper, @edition)
      select "#{characters(:ysabette).emoji} #{characters(:ysabette).name}",
             from: "comment[character_id]"
      fill_in "comment[body]", with: "I was there. This understates the danger."
      click_button "Post Comment"
    end

    using_session(:viewer) do
      assert_selector ".comment-bubble .comment-bubble__name",
                      text: /#{Regexp.escape(characters(:ysabette).name)}/i, wait: 10
      assert_selector ".comment-bubble .comment-bubble__text",
                      text: "I was there. This understates the danger."
    end
  end
end
