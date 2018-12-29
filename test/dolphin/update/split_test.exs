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
end
