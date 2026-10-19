defmodule HalloweenWeb.DeckLive do
  @moduledoc "One deck: its name, its cards, and the form for making and editing cards."
  use HalloweenWeb, :live_view
  alias Halloween.{Card, Game}

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    deck = Game.get_deck!(id)

    {:ok,
     socket
     |> assign(page_title: deck.name, deck: deck, deck_form: to_form(Game.change_deck(deck)))
     |> edit(new_card(deck))}
  end

  defp new_card(deck) do
    case List.last(deck.cards) do
      nil ->
        %Card{deck_id: deck.id}

      # New cards start like the deck's last one, since a deck is usually one kind of game.
      last ->
        %Card{
          deck_id: deck.id,
          audience: last.audience,
          input: last.input,
          reveal: last.reveal,
          points: last.points,
          seconds: last.seconds,
          options: if(last.input == "button", do: last.options, else: [])
        }
    end
  end

  defp edit(socket, card) do
    assign(socket, card: card, card_form: to_form(Game.change_card(card)))
  end

  defp reload(socket), do: assign(socket, deck: Game.get_deck!(socket.assigns.deck.id))

  @impl true
  def handle_event("save_deck", %{"deck" => params}, socket) do
    case Game.save_deck(socket.assigns.deck, params) do
      {:ok, _} -> {:noreply, socket |> reload() |> put_flash(:info, t("Deck saved."))}
      {:error, changeset} -> {:noreply, assign(socket, deck_form: to_form(changeset))}
    end
  end

  def handle_event("delete_deck", _params, socket) do
    Game.delete_deck(socket.assigns.deck)
    {:noreply, push_navigate(socket, to: ~p"/host/decks")}
  end

  def handle_event("validate_card", %{"card" => params}, socket) do
    changeset = Game.change_card(socket.assigns.card, card_params(params, socket))
    {:noreply, assign(socket, card_form: to_form(changeset, action: :validate))}
  end

  def handle_event("save_card", %{"card" => params}, socket) do
    case Game.save_card(socket.assigns.card, card_params(params, socket)) do
      {:ok, _} ->
        socket = reload(socket)

        {:noreply,
         socket |> edit(new_card(socket.assigns.deck)) |> put_flash(:info, t("Card saved."))}

      {:error, changeset} ->
        {:noreply, assign(socket, card_form: to_form(changeset))}
    end
  end

  def handle_event("edit_card", %{"id" => id}, socket) do
    {:noreply, edit(socket, Game.get_card!(id))}
  end

  def handle_event("cancel_edit", _params, socket) do
    {:noreply, edit(socket, new_card(socket.assigns.deck))}
  end

  def handle_event("delete_card", %{"id" => id}, socket) do
    Game.delete_card(Game.get_card!(id))
    socket = reload(socket)
    {:noreply, edit(socket, new_card(socket.assigns.deck))}
  end

  defp card_params(params, socket) do
    params
    |> Map.put("deck_id", socket.assigns.deck.id)
    |> Map.update("options", [], &String.split(&1, "\n"))
    |> then(fn p ->
      # Personal cards are challenges or secrets; switching to one picks a sensible answer type.
      if p["audience"] == "personal" and p["input"] not in ~w(none button),
        do: Map.put(p, "input", "button"),
        else: p
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.host flash={@flash} page={:decks}>
      <section class="panel">
        <.form for={@deck_form} id="deck-form" phx-submit="save_deck" class="inline-form deck-form">
          <.input field={@deck_form[:name]} label={t("Deck")} />
          <.input field={@deck_form[:description]} label={t("What it's about")} />
          <button class="btn">{t("Save")}</button>
        </.form>
      </section>

      <section class="panel card-editor">
        <h2>{if @card.id, do: t("Edit card"), else: t("New card")}</h2>
        <.card_form form={@card_form} />
      </section>

      <section class="panel">
        <h2>{t("Cards")}</h2>
        <p :if={@deck.cards == []} class="hint">{t("No cards yet. Write the first one above.")}</p>
        <ul class="card-list">
          <li :for={card <- @deck.cards} class={@card.id == card.id && "editing"}>
            <p class="card-text">{card.text}</p>
            <p class="meta">{summary(card)}</p>
            <span class="actions">
              <button class="btn btn-small" phx-click="edit_card" phx-value-id={card.id}>{t("Edit")}</button>
              <button
                class="btn btn-small btn-ghost"
                phx-click="delete_card"
                phx-value-id={card.id}
                data-confirm={t("Delete this card?")}
              >
                {t("Delete")}
              </button>
            </span>
          </li>
        </ul>
      </section>

      <button
        class="btn btn-danger"
        phx-click="delete_deck"
        data-confirm={t("Delete %{deck} and all its cards?", deck: @deck.name)}
      >
        {t("Delete deck")}
      </button>
    </Layouts.host>
    """
  end

  attr :form, :map, required: true

  defp card_form(assigns) do
    card = assigns.form.source
    get = &Ecto.Changeset.get_field(card, &1)

    assigns =
      assign(assigns,
        audience: get.(:audience),
        input: get.(:input),
        options: get.(:options),
        editing?: get.(:id) != nil
      )

    ~H"""
    <.form for={@form} id="card-form" phx-change="validate_card" phx-submit="save_card" class="stack">
      <.input
        field={@form[:text]}
        type="textarea"
        rows="3"
        label={t("Card text")}
        placeholder={t("Who would {guest} trust to hide a body?")}
      />
      <p class="help">
        {t("Write")}
        <code>{"{guest}"}</code> {t("and it becomes a random guest's name when the card is played.")}
      </p>

      <div class="row">
        <.input
          field={@form[:audience]}
          type="select"
          label={t("Who gets it")}
          options={[{t("Everyone, on stage"), "everyone"}, {t("One guest, privately"), "personal"}]}
        />
        <.input
          field={@form[:input]}
          type="select"
          label={t("How they answer")}
          options={inputs(@audience)}
        />
      </div>

      <.input
        :if={@input == "pick_option"}
        field={@form[:options]}
        type="lines"
        rows="4"
        label={t("Choices, one per line")}
      />
      <.input
        :if={@input == "pick_option"}
        field={@form[:correct]}
        type="select"
        label={t("Right answer")}
        options={[{t("No right answer"), ""} | Enum.map(@options, &{&1, &1})]}
      />
      <.input
        :if={@input == "button" and @audience == "everyone"}
        field={@form[:options]}
        type="lines"
        rows="1"
        label={t("Button text")}
        placeholder={t("Me!")}
      />

      <div class="row">
        <.input
          :if={@audience == "everyone" and @input != "none"}
          field={@form[:reveal]}
          type="select"
          label={t("How the answers are revealed")}
          options={reveals()}
        />
        <.input
          :if={@audience == "everyone" and @input != "none"}
          field={@form[:seconds]}
          type="number"
          min="1"
          label={t("Time limit in seconds")}
          placeholder={t("None")}
        />
        <.input field={@form[:points]} type="number" min="0" label={t("Points")} />
      </div>
      <p class="help">{points_help(@audience, @input)}</p>

      <div class="actions">
        <button class="btn btn-candle">{if @editing?, do: t("Save card"), else: t("Add card")}</button>
        <button :if={@editing?} type="button" class="btn btn-ghost" phx-click="cancel_edit">{t(
          "Cancel"
        )}</button>
      </div>
    </.form>
    """
  end

  defp inputs("personal") do
    [
      {t("A challenge: they tap \"I did it\""), "button"},
      {t("A secret: just for them to read"), "none"}
    ]
  end

  defp inputs(_everyone) do
    [
      {t("Point at a guest"), "pick_guest"},
      {t("Multiple choice"), "pick_option"},
      {t("Write something"), "text"},
      {t("Rate from 1 to 10"), "scale"},
      {t("Take a photo"), "photo"},
      {t("Tap a button"), "button"},
      {t("No answer, just show it"), "none"}
    ]
  end

  defp reveals do
    [
      {t("Bar chart, with who picked what"), "tally"},
      {t("Only the winner"), "winner"},
      {t("Every answer, with names"), "list"},
      {t("Every answer, no names"), "anonymous"}
    ]
  end

  defp label(choices, value), do: Enum.find_value(choices, fn {l, v} -> v == value && l end)

  defp points_help("personal", "button"),
    do: t("They get the points when you approve the challenge.")

  defp points_help(_, "pick_guest"),
    do: t("The most picked guest gets the points when you reveal.")

  defp points_help(_, "pick_option"),
    do: t("Everyone who picks the right answer gets the points.")

  defp points_help(_, _), do: t("Nobody gets these automatically. Give points by hand from Live.")

  defp summary(card) do
    [
      if(card.audience == "personal", do: t("Private"), else: t("On stage")),
      label(inputs(card.audience), card.input),
      (card.audience == "everyone" and card.input != "none") && label(reveals(), card.reveal),
      card.options != [] && Enum.join(card.options, " / "),
      card.points > 0 && t("%{n} pts", n: card.points),
      card.seconds && "#{card.seconds} s"
    ]
    |> Enum.filter(&is_binary/1)
    |> Enum.join(" · ")
  end
end
