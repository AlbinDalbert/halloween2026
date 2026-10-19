defmodule Halloween.Game do
  @moduledoc """
  The party game engine: guests, decks of cards, and playing them.

  Every change broadcasts `{:game, :changed}` on one topic. Each screen reloads what it shows
  when it hears it, so all phones and the TV stay in sync without tracking what changed.
  """
  import Ecto.Query
  alias Halloween.{Answer, Card, Deck, Play, Point, Repo, User}

  @topic "game"
  @live_stage ~w(open closed revealed)
  @live_personal ~w(open claimed approved)

  def subscribe, do: Phoenix.PubSub.subscribe(Halloween.PubSub, @topic)

  defp broadcast(result) do
    Phoenix.PubSub.broadcast(Halloween.PubSub, @topic, {:game, :changed})
    result
  end

  ## Guests

  @doc "Guests who have been let in and picked a name. Until then they aren't in the game."
  def list_guests do
    Repo.all(from u in User, where: u.approved and not is_nil(u.name), order_by: u.name)
  end

  @doc "Guests waiting at the door for a host to let them in, first come first."
  def list_requests do
    Repo.all(from u in User, where: not u.approved, order_by: [asc: u.inserted_at, asc: u.id])
  end

  def let_in(user),
    do: user |> Ecto.Changeset.change(approved: true) |> Repo.update() |> broadcast()

  def get_user(id), do: Repo.get(User, id)

  @doc "Creates or updates the guest who just logged in: `%{id, email, picture}` from the provider."
  def login(%{id: id} = profile, host_emails) do
    email = profile[:email]
    host? = email != nil and String.downcase(email) in host_emails
    user = Repo.get_by(User, workos_id: id) || %User{sigil: Enum.random(User.sigils())}

    user
    |> User.changeset(%{
      workos_id: id,
      email: email,
      avatar_url: profile[:picture],
      host: user.host or host?,
      approved: user.approved or host?
    })
    |> Repo.insert_or_update()
    |> broadcast()
  end

  def change_name(user, attrs \\ %{}), do: User.name_changeset(user, attrs)

  def set_name(user, attrs) do
    user |> User.name_changeset(attrs) |> Repo.update() |> broadcast()
  end

  def set_host(user, host?) do
    user
    |> Ecto.Changeset.change(host: host?, approved: user.approved or host?)
    |> Repo.update()
    |> broadcast()
  end

  def remove_guest(user), do: user |> Repo.delete() |> broadcast()

  ## Decks and cards

  def list_decks, do: Repo.all(from d in Deck, order_by: d.name, preload: :cards)

  def get_deck!(id), do: Deck |> Repo.get!(id) |> Repo.preload(:cards)

  def change_deck(deck, attrs \\ %{}), do: Deck.changeset(deck, attrs)

  def save_deck(deck, attrs) do
    deck |> Deck.changeset(attrs) |> Repo.insert_or_update() |> broadcast()
  end

  def delete_deck(deck), do: deck |> Repo.delete() |> broadcast()

  def get_card!(id), do: Repo.get!(Card, id)

  def change_card(card, attrs \\ %{}), do: Card.changeset(card, attrs)

  def save_card(card, attrs) do
    card |> Card.changeset(attrs) |> Repo.insert_or_update() |> broadcast()
  end

  def delete_card(card), do: card |> Repo.delete() |> broadcast()

  ## The stage: the one card every screen shows

  @doc "The card on stage right now, or nil."
  def stage do
    Repo.one(
      from p in Play,
        where: p.audience == "everyone" and p.state in @live_stage,
        order_by: [desc: p.id],
        limit: 1,
        preload: [answers: :user]
    )
  end

  @doc "Puts a random card from the deck on stage, preferring cards that haven't been played."
  def draw(%Deck{} = deck) do
    cards = Enum.filter(deck.cards, &(&1.audience == "everyone"))
    played = MapSet.new(Repo.all(from p in Play, where: p.deck_id == ^deck.id, select: p.card_id))

    case Enum.reject(cards, &(&1.id in played)) do
      [] when cards == [] -> {:error, :empty}
      [] -> play(Enum.random(cards))
      fresh -> play(Enum.random(fresh))
    end
  end

  @doc "Puts the card on stage, replacing whatever was there."
  def play(%Card{audience: "personal"}), do: {:error, :personal}

  def play(%Card{audience: "everyone"} = card) do
    Repo.update_all(from(p in Play, where: p.audience == "everyone" and p.state in @live_stage),
      set: [state: "finished"]
    )

    closes_at = card.seconds && DateTime.add(now(), card.seconds)

    {:ok, play} =
      card
      |> new_play(fill(card.text, list_guests()))
      |> Map.merge(%{state: "open", closes_at: closes_at})
      |> Repo.insert()

    if card.seconds do
      Task.Supervisor.start_child(Halloween.TaskSupervisor, fn ->
        Process.sleep(card.seconds * 1000)
        if play = Repo.get(Play, play.id), do: close(play)
      end)
    end

    broadcast({:ok, play})
  end

  @doc "Saves a guest's answer, replacing their earlier one. Reloads the play to check it's open."
  def answer(play_id, %User{} = user, value) when is_binary(value) do
    play = Repo.get!(Play, play_id)

    if user.approved and open?(play) and valid?(play, value) do
      %Answer{play_id: play.id, user_id: user.id, value: value}
      |> Repo.insert(
        on_conflict: {:replace, [:value, :updated_at]},
        conflict_target: [:play_id, :user_id]
      )
      |> broadcast()
    else
      {:error, :closed}
    end
  end

  defp valid?(%Play{input: "pick_guest"}, value),
    do: value in Enum.map(list_guests(), &to_string(&1.id))

  defp valid?(%Play{input: "pick_option", options: options}, value), do: value in options
  defp valid?(%Play{input: "scale"}, value), do: value in Enum.map(1..10, &to_string/1)
  defp valid?(%Play{input: "button"}, value), do: value == "yes"
  defp valid?(%Play{input: "none"}, _value), do: false
  defp valid?(%Play{}, value), do: String.trim(value) != "" and String.length(value) <= 280

  def open?(%Play{state: "open", closes_at: nil}), do: true
  def open?(%Play{state: "open", closes_at: at}), do: DateTime.compare(now(), at) == :lt
  def open?(%Play{}), do: false

  def close(%Play{state: "open"} = play), do: set_state(play, "closed")
  def close(play), do: {:ok, play}

  @doc "Shows the answers on stage and hands out the points the card is worth."
  def reveal(%Play{state: state} = play) when state in ~w(open closed) do
    play = Repo.preload(play, :answers, force: true)

    Repo.transact(fn ->
      for user_id <- winners(play), do: insert_point(user_id, play.points, play.text, play.id)
      play |> Ecto.Changeset.change(state: "revealed") |> Repo.update()
    end)
    |> broadcast()
  end

  def reveal(play), do: {:ok, play}

  defp winners(%Play{points: 0}), do: []

  defp winners(%Play{input: "pick_option", correct: correct} = play) when correct != nil do
    for a <- play.answers, a.value == correct, do: a.user_id
  end

  defp winners(%Play{input: "pick_guest"} = play) do
    case tally(play) do
      [] ->
        []

      [{_, top} | _] = tally ->
        for {value, answers} <- tally,
            length(answers) == length(top),
            do: String.to_integer(value)
    end
  end

  defp winners(_play), do: []

  @doc "Takes the card off stage."
  def finish(play), do: set_state(play, "finished")

  @doc "Answers grouped by value, most common first: `[{value, [answer]}]`."
  def tally(%Play{answers: answers}) do
    answers
    |> Enum.group_by(& &1.value)
    |> Enum.sort_by(fn {value, answers} -> {-length(answers), value} end)
  end

  ## Personal cards: dealt to one guest, only they see it

  @doc "Deals a card to one guest. `{guest}` never becomes the guest themselves."
  def deal(%Card{audience: "personal"} = card, %User{} = user) do
    text = fill(card.text, Enum.reject(list_guests(), &(&1.id == user.id)))

    card
    |> new_play(text)
    |> Map.merge(%{user_id: user.id, state: "open"})
    |> Repo.insert()
    |> broadcast()
  end

  @doc "Deals every guest a card from the deck, preferring cards they haven't had."
  def deal_all(%Deck{} = deck) do
    cards = Enum.filter(deck.cards, &(&1.audience == "personal"))

    if cards == [] do
      {:error, :empty}
    else
      had = Repo.all(from p in Play, where: p.deck_id == ^deck.id, select: {p.user_id, p.card_id})

      for user <- list_guests() do
        pool = Enum.reject(cards, &({user.id, &1.id} in had))
        deal(Enum.random(if pool == [], do: cards, else: pool), user)
      end

      {:ok, length(list_guests())}
    end
  end

  @doc "A guest's own cards, newest first."
  def personal_plays(%User{} = user) do
    Repo.all(
      from p in Play,
        where: p.user_id == ^user.id and p.state in @live_personal,
        order_by: [desc: p.id]
    )
  end

  @doc "Every guest's cards still in play, for the host."
  def all_personal_plays do
    Repo.all(
      from p in Play,
        where: not is_nil(p.user_id) and p.state in ~w(open claimed),
        order_by: [desc: p.state == "claimed", desc: p.id],
        preload: :user
    )
  end

  def get_play!(id), do: Play |> Repo.get!(id) |> Repo.preload(:user)

  @doc "The guest says they did it. The host approves or rejects."
  def claim(%Play{state: "open", user_id: id} = play, %User{id: id, approved: true}),
    do: set_state(play, "claimed")

  def claim(_play, _user), do: {:error, :not_yours}

  def approve(%Play{state: "claimed"} = play) do
    Repo.transact(fn ->
      if play.points > 0, do: insert_point(play.user_id, play.points, play.text, play.id)
      play |> Ecto.Changeset.change(state: "approved") |> Repo.update()
    end)
    |> broadcast()
  end

  def approve(_play), do: {:error, :not_claimed}

  def reject(%Play{state: "claimed"} = play), do: set_state(play, "open")
  def reject(_play), do: {:error, :not_claimed}

  ## Points

  def award(user_id, amount, reason) do
    user_id |> insert_point(amount, reason, nil) |> broadcast()
  end

  defp insert_point(user_id, amount, reason, play_id) do
    Repo.insert(%Point{user_id: user_id, amount: amount, reason: reason, play_id: play_id})
  end

  @doc "`[{user, points}]`, most points first."
  def leaderboard do
    Repo.all(
      from u in User,
        where: u.approved and not is_nil(u.name),
        left_join: p in Point,
        on: p.user_id == u.id,
        group_by: u.id,
        order_by: [desc: coalesce(sum(p.amount), 0), asc: u.name],
        select: {u, coalesce(sum(p.amount), 0)}
    )
  end

  ## Helpers

  @doc "Replaces each `{guest}` with a different random guest's name, where there are enough."
  def fill(text, guests) do
    [first | rest] = String.split(text, "{guest}")

    names =
      if guests == [], do: ["someone"], else: guests |> Enum.shuffle() |> Enum.map(& &1.name)

    rest
    |> Enum.zip(Stream.cycle(names))
    |> Enum.reduce(first, fn {part, name}, acc -> acc <> name <> part end)
  end

  defp new_play(card, text) do
    %Play{
      card_id: card.id,
      deck_id: card.deck_id,
      text: text,
      audience: card.audience,
      input: card.input,
      reveal: card.reveal,
      options: card.options,
      correct: card.correct,
      points: card.points
    }
  end

  defp set_state(play, state) do
    play |> Ecto.Changeset.change(state: state) |> Repo.update() |> broadcast()
  end

  defp now, do: DateTime.utc_now(:second)
end
