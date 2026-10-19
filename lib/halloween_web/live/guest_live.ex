defmodule HalloweenWeb.GuestLive do
  @moduledoc """
  A guest's phone. When the host puts a card on stage, it takes over the screen; the rest of
  the time it shows the guest's own cards and the leaderboard.
  """
  use HalloweenWeb, :live_view
  alias Halloween.{Game, Uploads, User}

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Game.subscribe()

    {:ok,
     socket
     |> assign(page_title: "Your cards", editing_name: false, peeking: MapSet.new())
     |> allow_upload(:photo, accept: ~w(.jpg .jpeg .png .webp .gif), max_file_size: 20_000_000)
     |> load()}
  end

  @impl true
  def handle_info({:game, :changed}, socket), do: {:noreply, load(socket)}

  defp load(socket) do
    case Game.get_user(socket.assigns.current_user.id) do
      nil ->
        push_navigate(socket, to: ~p"/login")

      user ->
        stage = Game.stage()
        guests = Game.list_guests()

        assign(socket,
          current_user: user,
          stage: stage,
          mine: stage && Enum.find(stage.answers, &(&1.user_id == user.id)),
          guests: guests,
          guests_by_id: Map.new(guests, &{&1.id, &1}),
          cards: Game.personal_plays(user),
          leaderboard: Game.leaderboard(),
          name_form: to_form(Game.change_name(user))
        )
    end
  end

  @impl true
  def handle_event("answer", %{"value" => value}, socket) do
    {:noreply, answer(socket, value)}
  end

  def handle_event("photo", _params, socket) do
    names =
      consume_uploaded_entries(socket, :photo, fn %{path: path}, entry ->
        {:ok, Uploads.save(path, Path.extname(entry.client_name) |> String.downcase())}
      end)

    {:noreply, Enum.reduce(names, socket, &answer(&2, &1))}
  end

  def handle_event("validate_photo", _params, socket), do: {:noreply, socket}

  def handle_event("claim", %{"id" => id}, socket) do
    Game.claim(Game.get_play!(id), socket.assigns.current_user)
    {:noreply, socket}
  end

  # Cards stay sealed until the guest opens one, so nobody reads it over their shoulder.
  def handle_event("peek", %{"id" => id}, socket) do
    id = String.to_integer(id)
    peeking = socket.assigns.peeking
    peeking = if id in peeking, do: MapSet.delete(peeking, id), else: MapSet.put(peeking, id)
    {:noreply, assign(socket, peeking: peeking)}
  end

  def handle_event("edit_name", _params, socket) do
    {:noreply, assign(socket, editing_name: !socket.assigns.editing_name)}
  end

  def handle_event("save_name", %{"user" => params}, socket) do
    case Game.set_name(socket.assigns.current_user, params) do
      {:ok, _user} -> {:noreply, assign(socket, editing_name: false)}
      {:error, changeset} -> {:noreply, assign(socket, name_form: to_form(changeset))}
    end
  end

  defp answer(socket, value) do
    case Game.answer(socket.assigns.stage.id, socket.assigns.current_user, value) do
      {:ok, _} -> socket
      {:error, _} -> put_flash(socket, :error, "Answers are closed for this card.")
    end
  end

  @impl true
  def render(%{current_user: %{name: nil}} = assigns) do
    ~H"""
    <Layouts.app flash={@flash} class="shell-phone">
      <.name_form form={@name_form} user={@current_user} title="Who goes there?" />
    </Layouts.app>
    """
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} class="shell-phone">
      <header class="me" id="me" phx-hook="Buzz" data-key={@stage && @stage.id}>
        <button class="me-who" phx-click="edit_name" aria-expanded={to_string(@editing_name)}>
          <.guest user={@current_user} name />
        </button>
        <span class="me-score">{score(@leaderboard, @current_user)} pts</span>
      </header>

      <.name_form :if={@editing_name} form={@name_form} user={@current_user} title="Change your name" />

      <section :if={@stage} class="stage">
        <.tarot play={@stage}>
          <.countdown play={@stage} />
        </.tarot>
        <.answer_input
          :if={@stage.state == "open"}
          play={@stage}
          mine={@mine}
          me={@current_user}
          guests={@guests}
          uploads={@uploads}
        />
        <p
          :if={@stage.state == "open" and @mine != nil and @stage.input not in ~w(text photo)}
          class="hint"
        >
          Locked in. You can change it until answers close.
        </p>
        <p :if={@stage.state == "closed"} class="hint">Answers are closed. Eyes on the TV.</p>
        <div :if={@stage.state == "revealed"} class="results">
          <.results play={@stage} guests={@guests_by_id} />
        </div>
      </section>

      <section class="my-cards">
        <h2>Your cards</h2>
        <p :if={@cards == []} class="hint">
          No cards yet. The host deals them during the night.
        </p>
        <div :for={card <- @cards} class={["envelope", card.state]}>
          <button
            class="envelope-seal"
            phx-click="peek"
            phx-value-id={card.id}
            aria-expanded={to_string(card.id in @peeking)}
          >
            <span :if={card.state == "open"}>
              {if card.id in @peeking,
                do: "Tap to seal it again",
                else: "Sealed. Tap to read it in secret."}
            </span>
            <span :if={card.state == "claimed"}>Waiting for the host to confirm</span>
            <span :if={card.state == "approved"}>Done{card.points > 0 && " · +#{card.points}"}</span>
          </button>
          <.tarot :if={card.id in @peeking} play={card} class="tarot-small">
            <button
              :if={card.state == "open" and card.input != "none"}
              class="btn btn-candle"
              phx-click="claim"
              phx-value-id={card.id}
            >
              I did it
            </button>
          </.tarot>
        </div>
      </section>

      <section class="board">
        <h2>Standings</h2>
        <.leaderboard rows={@leaderboard} me={@current_user} />
      </section>

      <footer class="phone-footer">
        <.link :if={@current_user.host} navigate={~p"/host"}>Host controls</.link>
        <.form for={%{}} action={~p"/logout"}>
          <button class="link">Log out</button>
        </.form>
      </footer>
    </Layouts.app>
    """
  end

  attr :form, :map, required: true
  attr :user, :map, required: true
  attr :title, :string, required: true

  defp name_form(assigns) do
    ~H"""
    <.form for={@form} phx-submit="save_name" class="name-form">
      <h1>{@title}</h1>
      <.input field={@form[:name]} label="Your name, as the others know you" maxlength="30" autofocus />
      <fieldset class="sigil-picker">
        <legend>Your sigil</legend>
        <label :for={s <- User.sigils()}>
          <input type="radio" name="user[sigil]" value={s} checked={s == @user.sigil} />
          <span>{s}</span>
        </label>
      </fieldset>
      <button class="btn btn-candle">Take your seat</button>
    </.form>
    """
  end

  attr :play, :map, required: true
  attr :mine, :map, default: nil
  attr :me, :map, required: true
  attr :guests, :list, required: true
  attr :uploads, :map, required: true

  defp answer_input(%{play: %{input: "pick_guest"}} = assigns) do
    ~H"""
    <div class="choices choices-guests">
      <button
        :for={g <- @guests}
        :if={g.id != @me.id}
        class={["choice", picked?(@mine, g.id) && "picked"]}
        phx-click="answer"
        value={g.id}
      >
        <.guest user={g} name />
      </button>
    </div>
    """
  end

  defp answer_input(%{play: %{input: "pick_option"}} = assigns) do
    ~H"""
    <div class="choices">
      <button
        :for={option <- @play.options}
        class={["choice", picked?(@mine, option) && "picked"]}
        phx-click="answer"
        value={option}
      >
        {option}
      </button>
    </div>
    """
  end

  defp answer_input(%{play: %{input: "scale"}} = assigns) do
    ~H"""
    <div class="choices choices-scale">
      <button
        :for={n <- 1..10}
        class={["choice", picked?(@mine, n) && "picked"]}
        phx-click="answer"
        value={n}
      >
        {n}
      </button>
    </div>
    """
  end

  defp answer_input(%{play: %{input: "button"}} = assigns) do
    ~H"""
    <button
      class={["btn btn-huge", @mine && "picked"]}
      phx-click="answer"
      value="yes"
      disabled={@mine != nil}
    >
      {List.first(@play.options) || "Me!"}
    </button>
    """
  end

  defp answer_input(%{play: %{input: "text"}} = assigns) do
    ~H"""
    <form id={"text-#{@play.id}"} phx-submit="answer" class="text-answer">
      <textarea name="value" rows="3" maxlength="280" required placeholder="Write here">{@mine && @mine.value}</textarea>
      <button class="btn btn-candle">{if @mine, do: "Change answer", else: "Send"}</button>
      <p :if={@mine} class="hint">Sent. You can change it until answers close.</p>
    </form>
    """
  end

  defp answer_input(%{play: %{input: "photo"}} = assigns) do
    ~H"""
    <form id={"photo-#{@play.id}"} phx-submit="photo" phx-change="validate_photo" class="photo-answer">
      <img :if={@mine} src={~p"/uploads/#{@mine.value}"} alt="Your photo" class="my-photo" />
      <label class="btn btn-ghost file-pick">
        {if @mine, do: "Take another", else: "Take a photo"}
        <.live_file_input upload={@uploads.photo} capture="environment" />
      </label>
      <.live_img_preview :for={entry <- @uploads.photo.entries} entry={entry} class="my-photo" />
      <p :for={entry <- @uploads.photo.entries} :if={entry.progress > 0} class="hint">
        Uploading {entry.progress}%
      </p>
      <p :for={err <- upload_errors(@uploads.photo)} class="field-error">{upload_error(err)}</p>
      <p
        :for={err <- Enum.flat_map(@uploads.photo.entries, &upload_errors(@uploads.photo, &1))}
        class="field-error"
      >
        {upload_error(err)}
      </p>
      <button :if={@uploads.photo.entries != []} class="btn btn-candle">Send photo</button>
    </form>
    """
  end

  defp answer_input(assigns), do: ~H""

  defp picked?(nil, _value), do: false
  defp picked?(answer, value), do: answer.value == to_string(value)

  defp upload_error(:too_large), do: "That photo is too big (20 MB max)."
  defp upload_error(:not_accepted), do: "That file isn't a photo we can show."
  defp upload_error(_), do: "The photo didn't upload. Try again."

  defp score(leaderboard, user) do
    Enum.find_value(leaderboard, 0, fn {u, points} -> u.id == user.id && points end)
  end
end
