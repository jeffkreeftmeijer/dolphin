defmodule FakeMastodon do
  def search(_conn, "https://ruby.social/@solnic/101275229051824324") do
    %Hunter.Result{
      accounts: [],
      hashtags: [],
      statuses: [
        %Hunter.Status{
          id: "101275229107919444"
        }
      ]
    }
  end
end
