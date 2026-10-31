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
    stage = Game.stage()

    assign(socket,
      stage: stage,
      guests: guests,
      guests_by_id: Map.new(guests, &{&1.id, &1}),
      leaderboard: Game.leaderboard(),
      decorations: Game.decorations(if(stage, do: "stage", else: "idle"))
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
        <.decorations on={@decorations} />
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

  attr :on, :list, required: true

  # Pre-drawn decorations, switched on from the host page. Purely for show, so hidden from
  # screen readers. What stands still is behind the screen's text; what moves flies in front.
  defp decorations(assigns) do
    ~H"""
    <div class="decor decor-back" aria-hidden="true">
      <div :if={"cobwebs" in @on} class="decor-cobwebs">
        <svg viewBox="0 0 200 200" class="decor-web"><path d="M0 0L200 0 M0 0L190 62 M0 0L162 118 M0 0L118 162 M0 0L62 190 M0 0L0 200 M45 0Q38 6 43 14Q34 17 36 26Q27 27 26 36Q17 34 14 43Q6 38 0 45 M85 0Q71 11 81 26Q64 33 69 50Q51 51 50 69Q33 64 26 81Q11 71 0 85 M125 0Q105 17 119 39Q95 48 101 73Q75 75 73 101Q48 95 39 119Q17 105 0 125 M165 0Q138 22 157 51Q125 64 133 97Q99 99 97 133Q64 125 51 157Q22 138 0 165" /></svg>
        <svg viewBox="0 0 200 200" class="decor-web decor-web-right"><path d="M0 0L200 0 M0 0L190 62 M0 0L162 118 M0 0L118 162 M0 0L62 190 M0 0L0 200 M45 0Q38 6 43 14Q34 17 36 26Q27 27 26 36Q17 34 14 43Q6 38 0 45 M85 0Q71 11 81 26Q64 33 69 50Q51 51 50 69Q33 64 26 81Q11 71 0 85 M125 0Q105 17 119 39Q95 48 101 73Q75 75 73 101Q48 95 39 119Q17 105 0 125 M165 0Q138 22 157 51Q125 64 133 97Q99 99 97 133Q64 125 51 157Q22 138 0 165" /></svg>
      </div>
      <svg :if={"moon" in @on} viewBox="0 0 200 200" class="decor-moon">
        <circle cx="100" cy="100" r="80" fill="#efe4c4" />
        <circle cx="72" cy="78" r="14" fill="#d8caa4" />
        <circle cx="122" cy="122" r="20" fill="#d8caa4" />
        <circle cx="128" cy="68" r="8" fill="#d8caa4" />
      </svg>
      <div :if={"eyes" in @on} class="decor-eyes">
        <span><svg viewBox="0 0 60 20"><ellipse cx="15" cy="10" rx="7" ry="5" /><ellipse
          cx="45"
          cy="10"
          rx="7"
          ry="5"
        /></svg></span>
        <span><svg viewBox="0 0 60 20"><ellipse cx="15" cy="10" rx="7" ry="5" /><ellipse
          cx="45"
          cy="10"
          rx="7"
          ry="5"
        /></svg></span>
        <span><svg viewBox="0 0 60 20"><ellipse cx="15" cy="10" rx="7" ry="5" /><ellipse
          cx="45"
          cy="10"
          rx="7"
          ry="5"
        /></svg></span>
        <span><svg viewBox="0 0 60 20"><ellipse cx="15" cy="10" rx="7" ry="5" /><ellipse
          cx="45"
          cy="10"
          rx="7"
          ry="5"
        /></svg></span>
      </div>
      <svg :if={"scarecrow" in @on} viewBox="0 0 200 300" class="decor-scarecrow">
        <rect x="96" y="60" width="8" height="240" fill="#5a3b22" />
        <rect x="18" y="118" width="164" height="8" fill="#5a3b22" />
        <path
          d="M22 128l-14-8 M22 134l-17 0 M22 140l-14 8 M178 128l14-8 M178 134l17 0 M178 140l14 8 M72 208l-6 22 M84 208l-2 26 M100 208l0 24 M116 208l2 26 M128 208l6 22"
          stroke="#d9b45a"
          stroke-width="4"
          stroke-linecap="round"
        />
        <path
          d="M62 112L138 112L178 122L178 146L140 140L136 210L64 210L60 140L22 146L22 122Z"
          fill="#7a3b2e"
        />
        <rect x="108" y="160" width="18" height="16" fill="#a8743a" />
        <rect x="70" y="128" width="12" height="12" fill="#4f6a3a" />
        <circle cx="100" cy="84" r="30" fill="#c9a66b" />
        <path
          d="M86 74l8 8M94 74l-8 8M106 74l8 8M114 74l-8 8M84 96Q100 108 116 96M90 99l-2 5M100 102v5M110 99l2 5"
          stroke="#2a1a14"
          stroke-width="3"
          fill="none"
          stroke-linecap="round"
        />
        <path d="M54 60L146 60L132 50L118 16Q100 4 82 18L68 50Z" fill="#3b2a1d" />
        <rect x="74" y="42" width="52" height="7" fill="#9c5a17" />
        <path d="M150 116q4-14 18-12l10-5-5 8q3 9-9 11Z" fill="#0d090b" />
      </svg>
      <svg :if={"pumpkin" in @on} viewBox="0 0 200 170" class="decor-pumpkin">
        <path d="M94 34C92 20 98 8 110 2L116 9C107 14 105 23 107 34Z" fill="#5b6b2f" />
        <ellipse cx="62" cy="102" rx="54" ry="62" fill="#c8641a" />
        <ellipse cx="138" cy="102" rx="54" ry="62" fill="#c8641a" />
        <ellipse cx="100" cy="102" rx="50" ry="66" fill="#e5832a" />
        <g class="decor-pumpkin-face">
          <path d="M56 84L80 70L84 98Z" />
          <path d="M144 84L120 70L116 98Z" />
          <path d="M100 100L91 116L109 116Z" />
          <path d="M48 124Q100 172 152 124Q132 134 120 132L120 142L106 142L106 134Q100 135 94 134L94 142L80 142L80 132Q68 134 48 124Z" />
        </g>
      </svg>
    </div>
    <div class="decor decor-front" aria-hidden="true">
      <div :if={"bats" in @on} class="decor-bats">
        <span class="decor-bat"><svg viewBox="0 0 100 50"><path d="M50 18C46 10 40 12 38 18C30 8 14 6 0 14C10 18 14 26 12 34C20 28 30 30 34 36C38 30 44 30 50 38C56 30 62 30 66 36C70 30 80 28 88 34C86 26 90 18 100 14C86 6 70 8 62 18C60 12 54 10 50 18Z" /></svg></span>
        <span class="decor-bat"><svg viewBox="0 0 100 50"><path d="M50 18C46 10 40 12 38 18C30 8 14 6 0 14C10 18 14 26 12 34C20 28 30 30 34 36C38 30 44 30 50 38C56 30 62 30 66 36C70 30 80 28 88 34C86 26 90 18 100 14C86 6 70 8 62 18C60 12 54 10 50 18Z" /></svg></span>
        <span class="decor-bat"><svg viewBox="0 0 100 50"><path d="M50 18C46 10 40 12 38 18C30 8 14 6 0 14C10 18 14 26 12 34C20 28 30 30 34 36C38 30 44 30 50 38C56 30 62 30 66 36C70 30 80 28 88 34C86 26 90 18 100 14C86 6 70 8 62 18C60 12 54 10 50 18Z" /></svg></span>
      </div>
      <div :if={"spider" in @on} class="decor-spider">
        <svg viewBox="0 0 60 60">
          <line x1="30" y1="-2000" x2="30" y2="16" class="decor-thread" />
          <path
            d="M24 30L6 18L2 6 M24 34L4 32L0 22 M24 38L6 46L2 58 M36 30L54 18L58 6 M36 34L56 32L60 22 M36 38L54 46L58 58"
            class="decor-legs"
          />
          <circle cx="30" cy="22" r="7" class="decor-spider-body" />
          <circle cx="30" cy="38" r="12" class="decor-spider-body" />
          <circle cx="27" cy="21" r="1.6" fill="#c2452d" />
          <circle cx="33" cy="21" r="1.6" fill="#c2452d" />
        </svg>
      </div>
      <div :if={"ghost" in @on} class="decor-ghost">
        <svg viewBox="0 0 100 120">
          <path
            d="M10 60C10 20 30 4 50 4C70 4 90 20 90 60L90 112L78 102L66 114L54 102L42 114L30 102L18 114L10 104Z"
            fill="#eadfc6"
          />
          <ellipse cx="36" cy="48" rx="6" ry="9" fill="#2a1a14" />
          <ellipse cx="64" cy="48" rx="6" ry="9" fill="#2a1a14" />
          <ellipse cx="50" cy="72" rx="7" ry="10" fill="#2a1a14" />
        </svg>
      </div>
      <div :if={"fog" in @on} class="decor-fog"></div>
    </div>
    """
  end
end
