defmodule TestUtils do
  def without_configuration(name, key, fun) do
    before = Application.get_env(name, key)
    Application.delete_env(name, key)

    fun.()

    Application.put_env(name, key, before)
  end
end
