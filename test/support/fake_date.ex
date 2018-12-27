defmodule FakeDate do
  def utc_today(), do: ~D[2018-12-27]

  def to_iso8601(date), do: Date.to_iso8601(date)
end
