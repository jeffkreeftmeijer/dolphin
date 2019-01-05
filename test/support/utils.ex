defmodule TestUtils do
  def without_configuration(name, key, fun) do
    before = Application.get_env(name, key)

    empty = Enum.map(before, fn {key, _} -> {key, nil} end)
    Application.put_env(name, key, empty)

    fun.()

    Application.put_env(name, key, before)
  end
end
