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

  test "one starter deck loads in any language, whatever the party's language" do
    sv = Enum.find(Starter.list(), &(&1.language == "sv" and &1.name == "Halloweenquiz"))
    {:ok, deck} = Starter.load("sv", sv.index)

    assert [%{name: "Halloweenquiz"} = loaded] = Game.list_decks()
    assert loaded.id == deck.id
    assert length(loaded.cards) == sv.cards
  end
end
