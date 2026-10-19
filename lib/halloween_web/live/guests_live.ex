defmodule HalloweenWeb.GuestsLive do
  @moduledoc "Everyone who has logged in: make them a host, or remove them."
  use HalloweenWeb, :live_view
  alias Halloween.Game

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Game.subscribe()
    {:ok, socket |> assign(page_title: "Guests") |> load()}
  end

  @impl true
  def handle_info({:game, :changed}, socket), do: {:noreply, load(socket)}

  defp load(socket), do: assign(socket, rows: Game.leaderboard())

  @impl true
  def handle_event("host", %{"id" => id}, socket) do
    user = Game.get_user(id)

    if user.id == socket.assigns.current_user.id do
      {:noreply, put_flash(socket, :error, "You can't stop being a host yourself.")}
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
      <section class="panel">
        <h2>Guests</h2>
        <p :if={@rows == []} class="hint">
          Nobody has taken a seat yet. Put the TV on: it shows a code to scan.
        </p>
        <ul class="guest-list">
          <li :for={{user, points} <- @rows}>
            <.guest user={user} name />
            <span class="meta">{user.email}</span>
            <span class="score">{points} pts</span>
            <span class="actions">
              <button class="btn btn-small" phx-click="host" phx-value-id={user.id}>
                {if user.host, do: "Remove host", else: "Make host"}
              </button>
              <button
                class="btn btn-small btn-ghost"
                phx-click="remove"
                phx-value-id={user.id}
                data-confirm={"Remove #{user.name}, with their answers and points?"}
              >
                Remove
              </button>
            </span>
          </li>
        </ul>
      </section>
    </Layouts.host>
    """
  end
end
