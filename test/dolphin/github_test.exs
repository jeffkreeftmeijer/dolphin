defmodule Dolphin.GithubTest do
  use ExUnit.Case, async: true
  doctest Dolphin.Github

  @credentials Application.get_env(:dolphin, :github_credentials)
  @username @credentials[:username]
  @repository @credentials[:repository]

  describe "post/1" do
    test "posts a file to a Github repository" do
      response = Dolphin.Github.post(%Dolphin.Update{text: "$ man ed\n\n#currentstatus"})

      assert {201,
              %{
                "commit" => %{"message" => "Add 2018-12-27-man-ed-currentstatus.md"},
                "content" => %{
                  "_links" => %{
                    "html" =>
                      "https://github.com/" <> @username <> "/" <> @repository <> "/blob/master/2018-12-27-man-ed-currentstatus.md"
                  }
                }
              }, _} = response
    end
  end
end
