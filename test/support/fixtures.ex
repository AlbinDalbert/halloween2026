defmodule Halloween.Fixtures do
  alias Halloween.{Card, Deck, Game}

  def guest(name, opts \\ []) do
    {:ok, user} =
      Game.login(%{id: "test-#{name}", email: "#{name}@test"}, opts[:hosts] || [])

    {:ok, user} = Game.set_name(user, %{name: name})
    user
  end

  def deck(cards \\ []) do
    {:ok, deck} = Game.save_deck(%Deck{}, %{name: "Deck #{System.unique_integer([:positive])}"})
    for attrs <- cards, do: card(deck, attrs)
    Game.get_deck!(deck.id)
  end

  def card(deck, attrs) do
    {:ok, card} = Game.save_card(%Card{}, Map.merge(%{deck_id: deck.id, text: "A card"}, attrs))
    card
  end
end
