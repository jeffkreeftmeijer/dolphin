defmodule Dolphin.UpdateTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
  doctest Dolphin.Update
  alias Dolphin.Update

  describe "post/1" do
    test "posts the update to github" do
      {:ok, [url]} = Update.post(%Update{text: "$ man ed\n\n#currentstatus"})

      assert url =~
               ~r/https:\/\/github.com\/\w+\/\w+\/blob\/master\/2018-12-27-man-ed-currentstatus.md/
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
