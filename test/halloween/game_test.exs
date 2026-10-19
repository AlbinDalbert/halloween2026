defmodule Halloween.GameTest do
  use Halloween.DataCase, async: false
  import Halloween.Fixtures
  alias Halloween.Game

  setup do
    %{alice: guest("Alice"), bob: guest("Bob"), cleo: guest("Cleo")}
  end

  describe "fill/2" do
    test "gives each {guest} a different guest while there are enough", %{alice: a, bob: b} do
      text = Game.fill("{guest} and {guest}", [a, b])
      assert text in ["Alice and Bob", "Bob and Alice"]
    end

    test "says someone when there are no guests" do
      assert Game.fill("Hug {guest}", []) == "Hug someone"
    end

    test "leaves text without placeholders alone", %{alice: a} do
      assert Game.fill("No one here", [a]) == "No one here"
    end
  end

  describe "the stage" do
    test "pekleken: guests vote, the most picked guest wins the points", %{
      alice: a,
      bob: b,
      cleo: c
    } do
      deck = deck([%{input: "pick_guest", reveal: "tally", points: 2}])
      {:ok, play} = Game.draw(deck)
      assert Game.stage().id == play.id

      {:ok, _} = Game.answer(play.id, a, to_string(b.id))
      {:ok, _} = Game.answer(play.id, c, to_string(b.id))
      {:ok, _} = Game.answer(play.id, b, to_string(a.id))
      # Changing your mind replaces your answer.
      {:ok, _} = Game.answer(play.id, b, to_string(c.id))

      stage = Game.stage()
      assert length(stage.answers) == 3
      assert [{bob_id, [_, _]}, {_, [_]}] = Game.tally(stage)
      assert bob_id == to_string(b.id)

      {:ok, _} = Game.reveal(stage)
      assert points(b) == 2
      assert points(a) == 0
    end

    test "trivia: everyone with the right answer gets the points", %{alice: a, bob: b} do
      deck = deck([%{input: "pick_option", options: ["Yes", "No"], correct: "Yes", points: 1}])
      {:ok, play} = Game.draw(deck)
      {:ok, _} = Game.answer(play.id, a, "Yes")
      {:ok, _} = Game.answer(play.id, b, "No")
      {:ok, _} = Game.reveal(Game.stage())
      assert points(a) == 1
      assert points(b) == 0
    end

    test "answers are refused once closed, or when they aren't a valid choice", %{alice: a} do
      deck = deck([%{input: "pick_option", options: ["Yes", "No"]}])
      {:ok, play} = Game.draw(deck)
      assert {:error, :closed} = Game.answer(play.id, a, "Maybe")
      {:ok, _} = Game.close(Game.stage())
      assert {:error, :closed} = Game.answer(play.id, a, "Yes")
    end

    test "playing a card replaces the one on stage" do
      deck = deck([%{text: "One"}, %{text: "Two"}])
      {:ok, first} = Game.draw(deck)
      {:ok, second} = Game.draw(deck)
      assert Game.stage().id == second.id
      assert first.text != second.text
    end

    test "drawing from a deck with no stage cards fails" do
      assert {:error, :empty} = Game.draw(deck([%{audience: "personal", input: "button"}]))
    end
  end

  describe "personal cards" do
    test "deal_all deals everyone a card that never names themselves", %{alice: a} do
      deck = deck([%{audience: "personal", input: "button", text: "Hug {guest}", points: 3}])
      {:ok, 3} = Game.deal_all(deck)

      [play] = Game.personal_plays(a)
      refute play.text =~ "Alice"

      {:ok, play} = Game.claim(play, a)
      {:ok, _} = Game.approve(play)
      assert points(a) == 3
    end

    test "only the guest it was dealt to can claim it", %{alice: a, bob: b} do
      deck = deck([%{audience: "personal", input: "button"}])
      {:ok, play} = Game.deal(hd(deck.cards), a)
      assert {:error, :not_yours} = Game.claim(play, b)
    end
  end

  test "login makes guests in HOST_EMAILS hosts" do
    assert guest("Dana", hosts: ["dana@test"]).host
    refute guest("Eve").host
  end

  test "cards check their options" do
    deck = deck()

    changeset =
      Game.change_card(%Halloween.Card{}, %{
        deck_id: deck.id,
        text: "?",
        input: "pick_option",
        options: ["Only one"]
      })

    refute changeset.valid?
  end

  defp points(user) do
    Enum.find_value(Game.leaderboard(), fn {u, p} -> u.id == user.id && p end)
  end
end
