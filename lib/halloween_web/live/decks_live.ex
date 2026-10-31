defmodule HalloweenWeb.DecksLive do
  @moduledoc "Every deck, and making new ones."
  use HalloweenWeb, :live_view
  alias Halloween.{Deck, Game, Starter}

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Game.subscribe()

    {:ok,
     socket
     |> assign(page_title: t("Decks"), form: to_form(Game.change_deck(%Deck{})))
     |> assign(decks: Game.list_decks())}
  end

  @impl true
  def handle_info({:game, :changed}, socket),
    do: {:noreply, assign(socket, decks: Game.list_decks())}

  @impl true
  def handle_event("create", %{"deck" => params}, socket) do
    case Game.save_deck(%Deck{}, params) do
      {:ok, deck} -> {:noreply, push_navigate(socket, to: ~p"/host/decks/#{deck}")}
      {:error, changeset} -> {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event("starter", _params, socket) do
    Starter.load()
    {:noreply, put_flash(socket, :info, t("Starter decks loaded."))}
  end

  def handle_event("starter_one", %{"language" => language, "index" => index}, socket) do
    case Starter.load(language, String.to_integer(index)) do
      {:ok, deck} -> {:noreply, push_navigate(socket, to: ~p"/host/decks/#{deck}")}
      {:error, _} -> {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.host flash={@flash} page={:decks}>
      <section class="panel">
        <h2>{t("Decks")}</h2>
        <p :if={@decks == []} class="hint">
          {t(
            "A deck is a pile of cards: one game, like Pekleken or trivia. Start from the starter decks, or make your own."
          )}
        </p>
        <button
          class={["btn", @decks == [] && "btn-candle"]}
          phx-click="starter"
          data-confirm={
            @decks != [] && t("Add the starter decks next to the decks you already have?")
          }
        >
          {t("Load the starter decks")}
        </button>
        <ul class="deck-list">
          <li :for={deck <- @decks}>
            <.link navigate={~p"/host/decks/#{deck}"}>
              <strong>{deck.name}</strong>
              <span class="meta">{t("%{n} cards", n: length(deck.cards))}</span>
              <span :if={deck.description} class="deck-desc">{deck.description}</span>
            </.link>
          </li>
        </ul>
      </section>

      <section class="panel">
        <h2>{t("New deck")}</h2>
        <.form for={@form} phx-submit="create" class="stack">
          <.input field={@form[:name]} label={t("Name")} />
          <.input field={@form[:description]} label={t("What it's about (only you see this)")} />
          <button class="btn btn-candle">{t("Create deck")}</button>
        </.form>
      </section>

      <section class="panel">
        <h2>{t("Start from a starter deck")}</h2>
        <p class="hint">{t("Makes a copy you can edit. Pick a language to play it in.")}</p>
        <ul class="card-list">
          <li :for={s <- Starter.list()} id={"starter-#{s.language}-#{s.index}"}>
            <span class="card-text"><strong>{s.name}</strong> · {s.description}</span>
            <span class="meta">{language_name(s.language)} · {t("%{n} cards", n: s.cards)}</span>
            <button
              class="btn btn-small"
              phx-click="starter_one"
              phx-value-language={s.language}
              phx-value-index={s.index}
            >
              {t("Add")}
            </button>
          </li>
        </ul>
      </section>
    </Layouts.host>
    """
  end

  defp language_name("en"), do: "English"
  defp language_name("sv"), do: "Svenska"
end
