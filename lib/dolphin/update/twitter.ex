defmodule Dolphin.Update.Twitter do
  defstruct [:content]
  alias Dolphin.Update

  def from_update(%Update{text: text}) do
    %Dolphin.Update.Twitter{content: text}
  end
end
