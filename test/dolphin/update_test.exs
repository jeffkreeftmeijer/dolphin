defmodule Dolphin.UpdateTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
  doctest Dolphin.Update
  alias Dolphin.Update

  describe "from_params/1" do
    test "creates an update from form parameters" do
      assert Update.from_params(%{"text" => "$ man ed\n\n#currentstatus"}) == %Update{
               text: "$ man ed\n\n#currentstatus"
             }
    end
  end

  describe "post/1" do
    setup do
      FakeGithub.Contents.start_link()
      {:ok, _} = Update.post(%Update{text: "$ man ed\n\n#currentstatus"})
    end

    test "posts the update to github", %{github: [url]} do
      assert url =~
               ~r/https:\/\/github.com\/\w+\/\w+\/blob\/master\/2018-12-27-man-ed-currentstatus.md/
    end

    test "posts the update to twitter", %{twitter: [url]} do
      assert url =~ ~r/https:\/\/twitter.com\/\w+\/status\/12119/
    end

    test "posts the update to mastodon", %{mastodon: [url]} do
      assert url =~ ~r/https:\/\/mastodon.social\/@\w+\/12119/
    end

    test "adds the twitter URL to the github update" do
      [{_filename, content}] = FakeGithub.Contents.files()
      assert content =~ ~r/twitter: \["https:\/\/twitter.com\/\w+\/status\/12119"\]/
      assert content =~ ~r/mastodon: \["https:\/\/mastodon.social\/@\w+\/12119"\]/
    end

    test "adds the current datetime to the github update" do
      [{_filename, content}] = FakeGithub.Contents.files()
      assert content =~ "date: 2018-12-27T15:46:23Z"
    end
  end

  describe "filename/1" do
    property "starts with today's date" do
      check all update <- update() do
        assert update
               |> Update.filename()
               |> String.starts_with?("2018-12-27")
      end
    end

    property "has a .md file extension" do
      check all update <- update() do
        assert update
               |> Update.filename()
               |> String.ends_with?(".md")
      end
    end

    property "only includes lowercase alphanumeric characters and dashes" do
      check all update <- update() do
        assert update
               |> Update.filename()
               |> remove(~r/^\d{4}-\d{2}-\d{2}/)
               |> remove(~r/\.md$/)
               |> String.to_charlist()
               |> Enum.all?(fn character ->
                 character == ?- or character in ?a..?z or character in ?0..?9
               end)
      end
    end

    property "does not include double dashes" do
      check all update <- update() do
        refute update
               |> Update.filename()
               |> String.contains?("--")
      end
    end

    property "does not include a dash immediately followed by a period" do
      check all update <- update() do
        refute update
               |> Update.filename()
               |> String.contains?("-.")
      end
    end

    property "does not include more than five words" do
      check all update <- update(), max_runs: 200 do
        assert update
               |> Update.filename()
               |> count_dashes() <= 7
      end
    end
  end

  defp remove(string, pattern) do
    Regex.replace(pattern, string, "")
  end

  defp count_dashes(string) do
    string
    |> String.to_charlist()
    |> count_dashes(0)
  end

  defp count_dashes([?- | tail], acc), do: count_dashes(tail, acc + 1)
  defp count_dashes([_ | tail], acc), do: count_dashes(tail, acc)
  defp count_dashes([], acc), do: acc

  defp string() do
    StreamData.one_of([StreamData.string(:ascii), StreamData.string(:printable)])
  end

  defp update() do
    ExUnitProperties.gen all text <- string() do
      %Update{text: text}
    end
  end
end
