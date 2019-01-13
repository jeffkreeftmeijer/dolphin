defmodule Dolphin.Update.SplitTest do
  use ExUnit.Case, async: true
  doctest Dolphin.Update.Split
  alias Dolphin.Update.Split

  test "splits text on double newlines" do
    text = """
    Some of my articles explain how to build your own GenServer in Elixir or how to compare images in plain Ruby, and I’ve built minimal clones of libraries like RSpec and Spring in the past to understand and teach how they work.

    While you shouldn’t rely on a hand-rolled HTTP server or a naïve reimplementation of an ancient OTP construct in production, taking software apart and rebuilding it is the best way I know to understand what’s happening under the hood.
    """

    assert ["Some of my" <> _, "While you shouldn’t" <> _] = Split.split(text, 280)
  end

  test "splits text on double CRLFs" do
    text = """
    Some of my articles explain how to build your own GenServer in Elixir or how to compare images in plain Ruby, and I’ve built minimal clones of libraries like RSpec and Spring in the past to understand and teach how they work.\r\n\r\nWhile you shouldn’t rely on a hand-rolled HTTP server or a naïve reimplementation of an ancient OTP construct in production, taking software apart and rebuilding it is the best way I know to understand what’s happening under the hood.
    """

    assert ["Some of my" <> _, "While you shouldn’t" <> _] = Split.split(text, 280)
  end

  test "does not split if the text fits the allowed characters" do
    text = """
    I *love* reinventing the wheel.

    Some of my articles explain how to build your own GenServer in Elixir or how to compare images in plain Ruby, and I’ve built minimal clones of libraries like RSpec and Spring in the past to understand and teach how they work.
    """

    assert ["I *love* reinventing" <> _] = Split.split(text, 280)
  end

  test "forces a split on a triple newline" do
    text = """
    I *love* reinventing the wheel.


    Some of my articles explain how to build your own GenServer in Elixir or how to compare images in plain Ruby, and I’ve built minimal clones of libraries like RSpec and Spring in the past to understand and teach how they work.
    """

    assert ["I *love* reinventing" <> _, "Some of my" <> _] = Split.split(text, 280)
  end

  test "forces a split on a triple CRLF" do
    text = """
    I *love* reinventing the wheel.\r\n\r\n\r\nSome of my articles explain how to build your own GenServer in Elixir or how to compare images in plain Ruby, and I’ve built minimal clones of libraries like RSpec and Spring in the past to understand and teach how they work.
    """

    assert ["I *love* reinventing" <> _, "Some of my" <> _] = Split.split(text, 280)
  end

  test "counts links as 23 characters" do
    text = "https://w3.org/TR/activitypub\n\n#currentstatus"

    assert [text] = Split.split(text, 40)
  end

  test "does not count local image tags" do
    text = "![An image](/media/file.jpg)\n\n#currentstatus"

    assert [text] = Split.split(text, 14)
  end

  test "duplicates mentions across splits" do
    text = """
    @jvanbaarsen Contexts provide the API to interact with your schemas to keep knowledge about your repository out of the rest of your app.

    While they can group functions for multiple schemas together (like in the Accounts example), you’re encouraged to start with one context per schema if it’s not immediately clear what the groups could be.
    """

    assert ["@jvanbaarsen Contexts" <> _, "@jvanbaarsen While" <> _] = Split.split(text, 280)
  end
end
