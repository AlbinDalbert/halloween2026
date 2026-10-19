defmodule HalloweenWeb.HostLive do
  @moduledoc "The host's remote control: what's on stage, decks to play from, challenges to confirm."
  use HalloweenWeb, :live_view
  alias Halloween.Game

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Game.subscribe()
    {:ok, socket |> assign(page_title: "Host") |> load()}
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
      requests: Game.list_requests()
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

  def handle_event("deal_all", %{"deck" => id}, socket) do
    case Game.deal_all(Game.get_deck!(id)) do
      {:ok, n} -> {:noreply, put_flash(socket, :info, "Dealt a card to #{n} guests.")}
      error -> {:noreply, result(socket, error)}
    end
  end

  def handle_event("deal", %{"card" => card_id, "user" => user_id}, socket) do
    card = Game.get_card!(card_id)
    user = Game.get_user(user_id)

    case Game.deal(card, user) do
      {:ok, _} -> {:noreply, put_flash(socket, :info, "Dealt to #{user.name}.")}
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

  def handle_event("award", %{"user" => user_id, "amount" => amount, "reason" => reason}, socket) do
    case Integer.parse(amount) do
      {amount, ""} ->
        user = Game.get_user(user_id)
        Game.award(user.id, amount, reason)
        {:noreply, put_flash(socket, :info, "#{amount} points to #{user.name}.")}

      _ ->
        {:noreply, put_flash(socket, :error, "Points must be a whole number.")}
    end
  end

  defp result(socket, {:ok, _}), do: clear_flash(socket)

  defp result(socket, {:error, :empty}),
    do: put_flash(socket, :error, "That deck has no cards for this.")

  defp result(socket, {:error, reason}),
    do: put_flash(socket, :error, "Couldn't do that: #{inspect(reason)}")

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.host flash={@flash} page={:live}>
      <.door requests={@requests} />
      <section class="panel stage-panel">
        <h2>On stage</h2>
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
              Close answers
            </button>
            <button
              :if={@stage.state in ~w(open closed) and @stage.input != "none"}
              class="btn btn-candle"
              phx-click="stage"
              phx-value-do="reveal"
            >
              Reveal
            </button>
            <button :if={@stage.deck_id} class="btn" phx-click="stage" phx-value-do="next">Next card</button>
            <button class="btn btn-ghost" phx-click="stage" phx-value-do="finish">Clear stage</button>
          </div>
          <.answered :if={@stage.input != "none"} play={@stage} guests={@guests} />
          <div :if={@stage.answers != [] and @stage.state != "revealed"} class="results preview">
            <p class="meta">Only you see this until you reveal it.</p>
            <.results play={@stage} guests={@guests_by_id} />
          </div>
        <% else %>
          <p class="hint">
            Nothing on stage. Draw a card from a deck below, and every phone and the TV will show it.
          </p>
        <% end %>
      </section>

      <section :if={@personal != []} class="panel">
        <h2>Guests' cards</h2>
        <ul class="personal-list">
          <li :for={p <- @personal} class={p.state}>
            <.guest user={p.user} name />
            <span class="personal-text">{p.text}</span>
            <span class="actions">
              <%= if p.state == "claimed" do %>
                <button
                  class="btn btn-candle"
                  phx-click="personal"
                  phx-value-do="approve"
                  phx-value-id={p.id}
                >
                  Approve{p.points > 0 && " +#{p.points}"}
                </button>
                <button class="btn" phx-click="personal" phx-value-do="reject" phx-value-id={p.id}>Reject</button>
              <% else %>
                <button
                  class="btn btn-ghost"
                  phx-click="personal"
                  phx-value-do="discard"
                  phx-value-id={p.id}
                >Discard</button>
              <% end %>
            </span>
          </li>
        </ul>
      </section>

      <section class="panel">
        <h2>Decks</h2>
        <p :if={@decks == []} class="hint">
          No decks yet. <.link navigate={~p"/host/decks"}>Make one, or load the starter decks.</.link>
        </p>
        <div :for={deck <- @decks} class="deck-row">
          <div class="deck-head">
            <h3>{deck.name}</h3>
            <span class="meta">{length(deck.cards)} cards</span>
            <span class="actions">
              <button
                :if={Enum.any?(deck.cards, &(&1.audience == "everyone"))}
                class="btn btn-candle"
                phx-click="draw"
                phx-value-deck={deck.id}
              >
                Draw
              </button>
              <button
                :if={Enum.any?(deck.cards, &(&1.audience == "personal"))}
                class="btn"
                phx-click="deal_all"
                phx-value-deck={deck.id}
                data-confirm={"Deal a card from #{deck.name} to every guest?"}
              >
                Deal to everyone
              </button>
            </span>
          </div>
          <details>
            <summary>Pick a card</summary>
            <ul class="card-picker">
              <li :for={card <- deck.cards}>
                <span>{card.text}</span>
                <button
                  :if={card.audience == "everyone"}
                  class="btn btn-small"
                  phx-click="play"
                  phx-value-card={card.id}
                >
                  Play
                </button>
                <form :if={card.audience == "personal"} phx-submit="deal" class="inline-form">
                  <input type="hidden" name="card" value={card.id} />
                  <select name="user" aria-label="Guest">
                    <option :for={g <- @guests} value={g.id}>{g.name}</option>
                  </select>
                  <button class="btn btn-small">Give</button>
                </form>
              </li>
            </ul>
          </details>
        </div>
      </section>

      <section class="panel">
        <h2>Give points</h2>
        <form phx-submit="award" class="inline-form award-form">
          <select name="user" aria-label="Guest">
            <option :for={g <- @guests} value={g.id}>{g.sigil} {g.name}</option>
          </select>
          <input type="number" name="amount" value="1" aria-label="Points" />
          <input type="text" name="reason" placeholder="What for" aria-label="Reason" />
          <button class="btn btn-candle">Give</button>
        </form>
      </section>
    </Layouts.host>
    """
  end
end
