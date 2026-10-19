defmodule HalloweenWeb.TvLive do
  @moduledoc "The big screen: the card on stage and its results, or the standings in between."
  use HalloweenWeb, :live_view
  alias Halloween.Game

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Game.subscribe()
    url = url(~p"/")

    qr =
      url
      |> EQRCode.encode()
      |> EQRCode.svg(width: 220, color: "#2a1a14", background_color: "#eadfc6")

    {:ok, socket |> assign(page_title: t("TV"), url: url, qr: raw(qr)) |> load()}
  end

  @impl true
  def handle_info({:game, :changed}, socket), do: {:noreply, load(socket)}

  defp load(socket) do
    guests = Game.list_guests()

    assign(socket,
      stage: Game.stage(),
      guests: guests,
      guests_by_id: Map.new(guests, &{&1.id, &1}),
      leaderboard: Game.leaderboard()
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} class="shell-tv">
      <div
        id="tv"
        phx-hook="WakeLock"
        class={["tv", @stage && ["tv-#{@stage.state}", "tv-#{@stage.input}"]]}
      >
        <%= if @stage do %>
          <div class="tv-card">
            <.tarot play={@stage} class="tarot-tv">
              <.countdown play={@stage} />
            </.tarot>
          </div>
          <div class="tv-side">
            <.answered
              :if={@stage.state != "revealed" and @stage.input != "none"}
              play={@stage}
              guests={@guests}
            />
            <p :if={@stage.state == "closed"} class="tv-hush">{t("Answers are in…")}</p>
            <div :if={@stage.state == "revealed"} class="results results-tv">
              <.results play={@stage} guests={@guests_by_id} />
            </div>
          </div>
          <aside class="tv-join-small">{@qr}</aside>
        <% else %>
          <div class="tv-idle">
            <h1 class="tv-title">{t("The Halloween Table")}</h1>
            <div class="tv-join">
              {@qr}
              <p>{t("Scan to take your seat")}</p>
            </div>
          </div>
          <section :if={@leaderboard != []} class="tv-board">
            <h2>{t("Standings")}</h2>
            <.leaderboard rows={@leaderboard} limit={10} />
          </section>
        <% end %>
      </div>
    </Layouts.app>
    """
  end
end
