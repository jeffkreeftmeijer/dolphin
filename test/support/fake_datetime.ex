defmodule FakeDateTime do
  def utc_now() do
    %DateTime{
      year: 2018,
      month: 12,
      day: 27,
      hour: 15,
      minute: 46,
      second: 23,
      time_zone: "Etc/UTC",
      zone_abbr: "UTC",
      utc_offset: 0,
      std_offset: 0
    }
  end

  def to_iso8601(date), do: DateTime.to_iso8601(date)
end
