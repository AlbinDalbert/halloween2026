defmodule HalloweenWeb.GuestsLive do
  @moduledoc "Everyone who has logged in: make them a host, or remove them."
  use HalloweenWeb, :live_view
  alias Halloween.Game

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Game.subscribe()
    {:ok, socket |> assign(page_title: t("Guests")) |> load()}
  end

  @impl true
  def handle_info({:game, :changed}, socket), do: {:noreply, load(socket)}

  defp load(socket), do: assign(socket, rows: Game.leaderboard(), requests: Game.list_requests())

  @impl true
  def handle_event("let_in", %{"id" => id}, socket) do
    if user = Game.get_user(id), do: Game.let_in(user)
    {:noreply, socket}
  end

  def handle_event("turn_away", %{"id" => id}, socket) do
    case Game.get_user(id) do
      %{approved: false} = user -> Game.remove_guest(user)
      _ -> nil
    end

    {:noreply, socket}
  end

  def handle_event("host", %{"id" => id}, socket) do
    user = Game.get_user(id)

    if user.id == socket.assigns.current_user.id do
      {:noreply, put_flash(socket, :error, t("You can't stop being a host yourself."))}
    else
      Game.set_host(user, !user.host)
      {:noreply, socket}
    end
  end

  def handle_event("remove", %{"id" => id}, socket) do
    Game.remove_guest(Game.get_user(id))
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.host flash={@flash} page={:guests}>
      <.door requests={@requests} />
      <section class="panel">
        <h2>{t("Guests")}</h2>
        <p :if={@rows == []} class="hint">
          {t("Nobody has taken a seat yet. Put the TV on: it shows a code to scan.")}
        </p>
        <ul class="guest-list">
          <li :for={{user, points} <- @rows}>
            <.guest user={user} name />
            <span class="meta">{user.email}</span>
            <span class="score">{t("%{n} pts", n: points)}</span>
            <span class="actions">
              <button class="btn btn-small" phx-click="host" phx-value-id={user.id}>
                {if user.host, do: t("Remove host"), else: t("Make host")}
              </button>
              <button
                class="btn btn-small btn-ghost"
                phx-click="remove"
                phx-value-id={user.id}
                data-confirm={t("Remove %{name}, with their answers and points?", name: user.name)}
              >
                {t("Remove")}
              </button>
            </span>
          </li>
        </ul>
      </section>
    </Layouts.host>
    """
  end
end
