defmodule HalloweenWeb.GameLiveTest do
  use HalloweenWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  import Halloween.Fixtures
  alias Halloween.Game

  defp log_in(conn, user), do: init_test_session(conn, user_id: user.id)

  test "logged out guests are sent to the login page", %{conn: conn} do
    assert {:error, {:redirect, %{to: "/login"}}} = live(conn, ~p"/")
  end

  test "a new guest picks a name first", %{conn: conn} do
    {:ok, user} = Game.login(%{id: "new", email: "new@test"}, [])
    {:ok, view, _html} = live(log_in(conn, user), ~p"/")

    assert render(view) =~ "Who goes there?"
    view |> form(".name-form", user: %{name: "Lurch"}) |> render_submit()
    assert render(view) =~ "Your cards"
  end

  test "a card on stage takes over every phone, and tapping a guest votes", %{conn: conn} do
    alice = guest("Alice")
    bob = guest("Bob")
    deck = deck([%{text: "Who is secretly a vampire?", input: "pick_guest"}])
    {:ok, view, html} = live(log_in(conn, alice), ~p"/")
    refute html =~ "secretly a vampire"

    {:ok, play} = Game.draw(deck)
    assert render(view) =~ "secretly a vampire"

    view |> element(".choice", "Bob") |> render_click()
    assert [%{value: value}] = Game.stage().answers
    assert value == to_string(bob.id)
    assert render(view) =~ "Locked in"

    Game.reveal(Game.get_play!(play.id))
    assert render(view) =~ "tally"
  end

  test "a dealt card stays sealed until the guest opens it", %{conn: conn} do
    alice = guest("Alice")
    deck = deck([%{audience: "personal", input: "button", text: "Steal a spoon"}])
    {:ok, play} = Game.deal(hd(deck.cards), alice)
    {:ok, view, html} = live(log_in(conn, alice), ~p"/")

    refute html =~ "Steal a spoon"
    assert view |> element(".envelope-seal") |> render_click() =~ "Steal a spoon"

    view |> element("button", "I did it") |> render_click()
    assert Game.get_play!(play.id).state == "claimed"
  end

  test "only hosts get the host pages", %{conn: conn} do
    guest = guest("Alice")
    host = guest("Hank", hosts: ["hank@test"])

    assert {:error, {:redirect, %{to: "/"}}} = live(log_in(conn, guest), ~p"/host")
    assert {:ok, _view, _html} = live(log_in(conn, host), ~p"/host")
  end

  test "the host draws a card and reveals it", %{conn: conn} do
    host = guest("Hank", hosts: ["hank@test"])
    deck([%{text: "Who would read the cursed book?", input: "pick_guest"}])
    {:ok, view, _html} = live(log_in(conn, host), ~p"/host")

    view |> element("button", "Draw") |> render_click()
    assert Game.stage().text == "Who would read the cursed book?"

    view |> element("button", "Reveal") |> render_click()
    assert Game.stage().state == "revealed"
  end

  test "the host builds a deck", %{conn: conn} do
    host = guest("Hank", hosts: ["hank@test"])
    {:ok, view, _html} = live(log_in(conn, host), ~p"/host/decks")

    view |> form("form", deck: %{name: "Ghost stories"}) |> render_submit()
    {path, _flash} = assert_redirect(view)
    {:ok, view, _html} = live(log_in(conn, host), path)

    # The choices only show up once the card is multiple choice.
    view |> form("#card-form", card: %{input: "pick_option"}) |> render_change()
    view |> form("#card-form", card: %{options: "Ghost\nGhoul"}) |> render_change()

    view
    |> form("#card-form", card: %{text: "Pick one", correct: "Ghoul"})
    |> render_submit()

    assert [%{options: ["Ghost", "Ghoul"], correct: "Ghoul"}] =
             Game.list_decks() |> hd() |> Map.get(:cards)
  end

  test "the TV shows the join code, then the stage", %{conn: conn} do
    alice = guest("Alice")
    {:ok, view, html} = live(log_in(conn, alice), ~p"/tv")
    assert html =~ "Scan to take your seat"

    Game.draw(deck([%{text: "Who would survive?"}]))
    assert render(view) =~ "Who would survive?"
  end
end
