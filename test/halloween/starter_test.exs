defmodule Halloween.StarterTest do
  use Halloween.DataCase, async: false
  alias Halloween.{Game, Starter}

  setup do
    on_exit(fn -> Application.put_env(:halloween, :language, "en") end)
  end

  test "the starter decks load in the party's language, with valid cards" do
    Starter.load()
    assert "Costume contest" in Enum.map(Game.list_decks(), & &1.name)

    Application.put_env(:halloween, :language, "sv")
    Starter.load()
    names = Enum.map(Game.list_decks(), & &1.name)
    assert "Maskeradtävling" in names
    assert "Pekleken" in names
  end
end
