require "test_helper"

class StoryComponentTest < ViewComponent::TestCase
  test "renders headline and body" do
    story = stories(:one)
    render_inline(StoryComponent.new(story: story))

    assert_selector "article.story.story--major"
    assert_selector "h2.headline.headline--major", text: story.headline
    assert_selector ".story-body", text: story.body
  end

  test "renders optional fields when present" do
    story = stories(:one)
    story.supertitle    = "Dispatch from the Front"
    story.subtitle      = "The Guild Knew They Were Coming"
    story.author        = "J. Pryce"
    story.summary_ticker = "Officers Killed — Twice as Many Wounded"
    story.quote         = "We shall not yield."
    story.quote_origin  = "The Chancellor"

    render_inline(StoryComponent.new(story: story))

    assert_selector ".story-supertitle", text: story.supertitle
    assert_selector ".story-subtitle",   text: story.subtitle
    assert_selector ".story-byline",     text: "By #{story.author}"
    assert_selector ".story-ticker",     text: story.summary_ticker
    assert_selector ".story-quote",      text: story.quote
    assert_selector ".story-quote cite", text: "— #{story.quote_origin}"
  end

  test "omits optional fields when blank" do
    story = stories(:one)
    render_inline(StoryComponent.new(story: story))

    assert_no_selector ".story-supertitle"
    assert_no_selector ".story-subtitle"
    assert_no_selector ".story-byline"
    assert_no_selector ".story-ticker"
    assert_no_selector ".story-quote"
  end

  test "applies story type class to article and headline" do
    render_inline(StoryComponent.new(story: stories(:ad_one)))

    assert_selector "article.story--advertisement"
    assert_selector "h2.headline--advertisement"
  end
end
