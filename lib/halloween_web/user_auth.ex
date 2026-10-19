defmodule HalloweenWeb.UserAuth do
  @moduledoc "Who is logged in: plugs for controllers and `on_mount` hooks for LiveViews."
  use HalloweenWeb, :verified_routes
  import Plug.Conn
  import Phoenix.Controller
  alias Halloween.Game

  def fetch_user(conn, _opts) do
    user = (id = get_session(conn, :user_id)) && Game.get_user(id)
    assign(conn, :current_user, user)
  end

  def require_user(conn, _opts) do
    if conn.assigns.current_user do
      conn
    else
      conn |> redirect(to: ~p"/login") |> halt()
    end
  end

  def on_mount(:guest, _params, session, socket) do
    case session["user_id"] && Game.get_user(session["user_id"]) do
      nil -> {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/login")}
      user -> {:cont, Phoenix.Component.assign(socket, :current_user, user)}
    end
  end

  def on_mount(:host, params, session, socket) do
    case on_mount(:guest, params, session, socket) do
      {:cont, %{assigns: %{current_user: %{host: true}}}} = cont -> cont
      {:cont, socket} -> {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/")}
      halt -> halt
    end
  end
end
