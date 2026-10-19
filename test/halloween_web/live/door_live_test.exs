defmodule HalloweenWeb.DoorLiveTest do
  use HalloweenWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  import Halloween.Fixtures
  alias Halloween.Game

  defp log_in(conn, user), do: init_test_session(conn, user_id: user.id)

  test "someone new waits at the door until a host lets them in", %{conn: conn} do
    lurch = guest("Lurch", waiting: true)
    host = guest("Hank", hosts: ["hank@test"])
    {:ok, phone, html} = live(log_in(conn, lurch), ~p"/")
    assert html =~ "wait at the door"

    {:ok, host_view, html} = live(log_in(build_conn(), host), ~p"/host")
    assert html =~ "At the door"
    assert html =~ "Lurch"

    host_view |> element("button", "Let in") |> render_click()
    assert render(phone) =~ "Your cards"
    refute render(host_view) =~ "At the door"
  end

  test "a guest who is turned away is sent back to the login page", %{conn: conn} do
    lurch = guest("Lurch", waiting: true)
    host = guest("Hank", hosts: ["hank@test"])
    {:ok, phone, _html} = live(log_in(conn, lurch), ~p"/")
    {:ok, host_view, _html} = live(log_in(build_conn(), host), ~p"/host/guests")

    host_view |> element("button", "Turn away") |> render_click()
    assert_redirect(phone, ~p"/login")
    assert Game.get_user(lurch.id) == nil
  end

  test "guests at the door aren't in the game", %{conn: conn} do
    lurch = guest("Lurch", waiting: true)
    alice = guest("Alice")
    refute lurch.id in Enum.map(Game.list_guests(), & &1.id)

    {:ok, play} = Game.draw(deck([%{input: "pick_guest"}]))
    assert {:error, :closed} = Game.answer(play.id, lurch, to_string(alice.id))

    assert {:error, {:redirect, %{to: "/"}}} = live(log_in(conn, lurch), ~p"/tv")
    assert conn |> log_in(lurch) |> get(~p"/uploads/anything.jpg") |> redirected_to() == "/"
  end

  test "hosts see on their phone that someone is at the door", %{conn: conn} do
    host = guest("Hank", hosts: ["hank@test"])
    alice = guest("Alice")
    guest("Lurch", waiting: true)

    {:ok, _view, html} = live(log_in(conn, host), ~p"/")
    assert html =~ "Someone is at the door"
    {:ok, _view, html} = live(log_in(build_conn(), alice), ~p"/")
    refute html =~ "at the door"
  end

  test "hosts from HOST_EMAILS skip the door" do
    assert guest("Hank", hosts: ["hank@test"], waiting: true).approved
  end
end
