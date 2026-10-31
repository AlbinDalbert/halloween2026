defmodule HalloweenWeb.HostLive do
  @moduledoc "The host's remote control: what's on stage, decks to play from, challenges to confirm."
  use HalloweenWeb, :live_view
  alias Halloween.{Decoration, Game}

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Game.subscribe()

    {:ok,
     socket
     |> assign(page_title: t("Host"), deal_each: %{}, show_missions: false)
     |> load()}
  end

  @impl true
  def handle_info({:game, :changed}, socket), do: {:noreply, load(socket)}

  defp load(socket) do
    guests = Game.list_guests()

    assign(socket,
      stage: Game.stage(),
      guests: guests,
      guests_by_id: Map.new(guests, &{&1.id, &1}),
      decks: Game.list_decks(),
      personal: Game.all_personal_plays(),
      requests: Game.list_requests(),
      decorations: Map.new(Decoration.scenes(), &{&1, Game.decorations(&1)})
    )
  end

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

  def handle_event("draw", %{"deck" => id}, socket) do
    {:noreply, socket |> result(Game.draw(Game.get_deck!(id)))}
  end

  def handle_event("play", %{"card" => id}, socket) do
    {:noreply, socket |> result(Game.play(Game.get_card!(id)))}
  end

  def handle_event("deal_plan", %{"deck" => id, "each" => each}, socket) do
    {:noreply, assign(socket, deal_each: Map.put(socket.assigns.deal_each, id, each(each)))}
  end

  def handle_event("deal_all", %{"deck" => id, "each" => each}, socket) do
    each = each(each)

    case Game.deal_all(Game.get_deck!(id), each) do
      {:ok, n} ->
        {:noreply,
         put_flash(socket, :info, t("Dealt %{each} each to %{n} guests.", each: each, n: n))}

      error ->
        {:noreply, result(socket, error)}
    end
  end

  def handle_event("show_missions", _params, socket),
    do: {:noreply, assign(socket, show_missions: !socket.assigns.show_missions)}

  def handle_event("deal", %{"card" => card_id, "user" => user_id}, socket) do
    card = Game.get_card!(card_id)
    user = Game.get_user(user_id)

    case Game.deal(card, user) do
      {:ok, _} -> {:noreply, put_flash(socket, :info, t("Dealt to %{name}.", name: user.name))}
      error -> {:noreply, result(socket, error)}
    end
  end

  def handle_event("stage", _params, %{assigns: %{stage: nil}} = socket), do: {:noreply, socket}

  def handle_event("stage", %{"do" => action}, socket) do
    play = Game.get_play!(socket.assigns.stage.id)

    result =
      case action do
        "close" -> Game.close(play)
        "reveal" -> Game.reveal(play)
        "finish" -> Game.finish(play)
        "next" -> Game.draw(Game.get_deck!(play.deck_id))
      end

    {:noreply, result(socket, result)}
  end

  def handle_event("personal", %{"do" => action, "id" => id}, socket) do
    play = Game.get_play!(id)

    result =
      case action do
        "approve" -> Game.approve(play)
        "reject" -> Game.reject(play)
        "discard" -> Game.finish(play)
      end

    {:noreply, result(socket, result)}
  end

  def handle_event("decorate", params, socket) do
    for scene <- Decoration.scenes(), do: Game.decorate(scene, Map.get(params, scene, []))
    {:noreply, socket}
  end

  def handle_event("award", %{"user" => user_id, "amount" => amount, "reason" => reason}, socket) do
    case Integer.parse(amount) do
      {amount, ""} ->
        user = Game.get_user(user_id)
        Game.award(user.id, amount, reason)
        {:noreply, put_flash(socket, :info, "#{amount} points to #{user.name}.")}

      _ ->
        {:noreply, put_flash(socket, :error, t("Points must be a whole number."))}
    end
  end

  # Missions each, from the deal form: a whole number from 1 to 20.
  defp each(value) do
    case Integer.parse(value) do
      {n, ""} -> n |> max(1) |> min(20)
      _ -> 1
    end
  end

  defp result(socket, {:ok, _}), do: clear_flash(socket)

  defp result(socket, {:error, :empty}),
    do: put_flash(socket, :error, t("That deck has no cards for this."))

  defp result(socket, {:error, reason}),
    do: put_flash(socket, :error, t("Couldn't do that: %{reason}", reason: inspect(reason)))

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.host flash={@flash} page={:live}>
      <.door requests={@requests} />
      <section class="panel stage-panel">
        <h2>{t("On stage")}</h2>
        <%= if @stage do %>
          <.tarot play={@stage} class="tarot-small">
            <.countdown play={@stage} />
          </.tarot>
          <div class="actions">
            <button
              :if={@stage.state == "open" and @stage.input != "none"}
              class="btn"
              phx-click="stage"
              phx-value-do="close"
            >
              {t("Close answers")}
            </button>
            <button
              :if={@stage.state in ~w(open closed) and @stage.input != "none"}
              class="btn btn-candle"
              phx-click="stage"
              phx-value-do="reveal"
            >
              {t("Reveal")}
            </button>
            <button :if={@stage.deck_id} class="btn" phx-click="stage" phx-value-do="next">{t(
              "Next card"
            )}</button>
            <button class="btn btn-ghost" phx-click="stage" phx-value-do="finish">{t("Clear stage")}</button>
          </div>
          <.answered :if={@stage.input != "none"} play={@stage} guests={@guests} />
          <div :if={@stage.answers != [] and @stage.state != "revealed"} class="results preview">
            <p class="meta">{t("Only you see this until you reveal it.")}</p>
            <.results play={@stage} guests={@guests_by_id} />
          </div>
        <% else %>
          <p class="hint">
            {t(
              "Nothing on stage. Draw a card from a deck below, and every phone and the TV will show it."
            )}
          </p>
        <% end %>
      </section>

      <section :if={@personal != []} class="panel">
        <div class="panel-head">
          <h2>{t("Guests' cards")}</h2>
          <button id="show-missions" class="btn btn-small btn-ghost" phx-click="show_missions">
            {if(@show_missions, do: t("Hide"), else: t("Show what everyone got"))}
          </button>
        </div>
        <ul id="personal-list" class="personal-list">
          <li :for={p <- @personal} class={p.state}>
            <.guest user={p.user} name />
            <span :if={p.state == "claimed" or @show_missions} class="personal-text">{p.text}</span>
            <span :if={p.state != "claimed" and !@show_missions} class="personal-text sealed">
              {t("Sealed")}
            </span>
            <span class="actions">
              <%= if p.state == "claimed" do %>
                <button
                  class="btn btn-candle"
                  phx-click="personal"
                  phx-value-do="approve"
                  phx-value-id={p.id}
                >
                  {t("Approve")}{p.points > 0 && " +#{p.points}"}
                </button>
                <button class="btn" phx-click="personal" phx-value-do="reject" phx-value-id={p.id}>{t(
                  "Reject"
                )}</button>
              <% else %>
                <button
                  class="btn btn-ghost"
                  phx-click="personal"
                  phx-value-do="discard"
                  phx-value-id={p.id}
                >{t("Discard")}</button>
              <% end %>
            </span>
          </li>
        </ul>
      </section>

      <section class="panel">
        <h2>{t("Decks")}</h2>
        <p :if={@decks == []} class="hint">
          {t("No decks yet.")}
          <.link navigate={~p"/host/decks"}>{t("Make one, or load the starter decks.")}</.link>
        </p>
        <div :for={deck <- @decks} class="deck-row">
          <div class="deck-head">
            <h3>{deck.name}</h3>
            <span class="meta">{t("%{n} cards", n: length(deck.cards))}</span>
            <span class="actions">
              <button
                :if={Enum.any?(deck.cards, &(&1.audience == "everyone"))}
                class="btn btn-candle"
                phx-click="draw"
                phx-value-deck={deck.id}
              >
                {t("Draw")}
              </button>
            </span>
          </div>
          <form
            :if={Enum.any?(deck.cards, &(&1.audience == "personal"))}
            id={"deal-#{deck.id}"}
            phx-change="deal_plan"
            phx-submit="deal_all"
            class="deal-form"
          >
            <input type="hidden" name="deck" value={deck.id} />
            <label>
              {t("Missions each")}
              <input
                type="number"
                name="each"
                min="1"
                max="20"
                value={Map.get(@deal_each, to_string(deck.id), 1)}
              />
            </label>
            <button class="btn">{t("Deal to everyone")}</button>
            <.deal_plan
              cards={Enum.count(deck.cards, &(&1.audience == "personal"))}
              guests={length(@guests)}
              each={Map.get(@deal_each, to_string(deck.id), 1)}
            />
          </form>
          <details>
            <summary>{t("Pick a card")}</summary>
            <ul class="card-picker">
              <li :for={card <- deck.cards}>
                <span>{card.text}</span>
                <button
                  :if={card.audience == "everyone"}
                  class="btn btn-small"
                  phx-click="play"
                  phx-value-card={card.id}
                >
                  {t("Play")}
                </button>
                <form :if={card.audience == "personal"} phx-submit="deal" class="inline-form">
                  <input type="hidden" name="card" value={card.id} />
                  <select name="user" aria-label={t("Guest")}>
                    <option :for={g <- @guests} value={g.id}>{g.name}</option>
                  </select>
                  <button class="btn btn-small">{t("Give")}</button>
                </form>
              </li>
            </ul>
          </details>
        </div>
      </section>

      <section class="panel">
        <h2>{t("Give points")}</h2>
        <form phx-submit="award" class="inline-form award-form">
          <select name="user" aria-label={t("Guest")}>
            <option :for={g <- @guests} value={g.id}>{g.sigil} {g.name}</option>
          </select>
          <input type="number" name="amount" value="1" aria-label={t("Points")} />
          <input type="text" name="reason" placeholder={t("What for")} aria-label={t("What for")} />
          <button class="btn btn-candle">{t("Give")}</button>
        </form>
      </section>

      <section class="panel">
        <h2>{t("Decorations")}</h2>
        <p class="hint">
          {t("On the TV. Pick them separately for between cards and during a card.")}
        </p>
        <form id="decorations-form" phx-change="decorate" class="decoration-picker">
          <span></span>
          <span class="meta">{t("Between cards")}</span>
          <span class="meta">{t("During a card")}</span>
          <%= for name <- Decoration.names() do %>
            <span>{decoration_label(name)}</span>
            <input
              :for={scene <- Decoration.scenes()}
              type="checkbox"
              name={"#{scene}[]"}
              value={name}
              checked={name in @decorations[scene]}
              id={"decoration-#{scene}-#{name}"}
              aria-label={decoration_label(name)}
            />
          <% end %>
        </form>
      </section>
    </Layouts.host>
    """
  end

  defp decoration_label("pumpkin"), do: t("Jack-o'-lantern")
  defp decoration_label("scarecrow"), do: t("Scarecrow")
  defp decoration_label("moon"), do: t("Full moon")
  defp decoration_label("bats"), do: t("Bats")
  defp decoration_label("ghost"), do: t("Ghost")
  defp decoration_label("spider"), do: t("Spider")
  defp decoration_label("cobwebs"), do: t("Cobwebs")
  defp decoration_label("eyes"), do: t("Eyes in the dark")
  defp decoration_label("fog"), do: t("Fog")

  attr :cards, :integer, required: true
  attr :guests, :integer, required: true
  attr :each, :integer, required: true

  # What a deal will do, in counts only: never who gets which card.
  defp deal_plan(assigns) do
    assigns = assign(assigns, total: assigns.guests * assigns.each)

    ~H"""
    <ul class="deal-plan meta">
      <li>
        {t("%{guests} guests × %{each} = %{total} missions, from a deck of %{cards}.",
          guests: @guests,
          each: @each,
          total: @total,
          cards: @cards
        )}
      </li>
      <%= if @total <= @cards do %>
        <li>{t("Every mission goes to one guest only.")}</li>
      <% else %>
        <li>
          {t("The deck runs out, so it's reshuffled: a mission goes to at most %{n} guests.",
            n: ceil(@total / @cards)
          )}
        </li>
      <% end %>
      <li :if={@each > @cards} class="warn">
        {t("That's more each than the deck has, so guests get some missions twice.")}
      </li>
      <li>{t("Missions nobody holds right now go out first.")}</li>
      <li>{t("Who gets what is random, and sealed from you too until you choose to look.")}</li>
    </ul>
    """
  end
end
