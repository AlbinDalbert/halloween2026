defmodule HalloweenWeb.GameComponents do
  @moduledoc "The pieces every screen shares: the card, results, guests and the leaderboard."
  use Phoenix.Component
  use HalloweenWeb, :verified_routes
  import Halloween.Text
  alias Halloween.Game

  attr :user, :map, required: true
  attr :name, :boolean, default: false

  def guest(assigns) do
    ~H"""
    <span class="guest">
      <span class="sigil" aria-hidden={@name && "true"} title={@user.name}>{@user.sigil}</span>
      <span :if={@name} class="guest-name">{@user.name}</span>
    </span>
    """
  end

  @doc """
  A play as a card. It turns over from its back when it's played, and again when it's
  revealed: the id changes, so the element is replaced and its animation runs again.
  """
  attr :play, :map, required: true
  attr :class, :string, default: nil
  slot :inner_block

  def tarot(assigns) do
    ~H"""
    <article
      id={"card-#{@play.id}-#{if @play.state == "revealed", do: "revealed", else: "played"}"}
      class={["tarot", @class]}
    >
      <div class="tarot-inner">
        <div class="tarot-back" aria-hidden="true"></div>
        <div class="tarot-face">
          <p :if={kind(@play) != ""} class="tarot-kind">{kind(@play)}</p>
          <p class="tarot-text">{@play.text}</p>
          {render_slot(@inner_block)}
          <p :if={@play.points > 0} class="tarot-points">
            {points(@play.points)}
          </p>
        </div>
      </div>
    </article>
    """
  end

  defp kind(%{audience: "personal", input: "none"}), do: t("For your eyes only")
  defp kind(%{audience: "personal"}), do: t("Your challenge")
  defp kind(%{input: "pick_guest"}), do: t("Point at someone")
  defp kind(%{input: "pick_option"}), do: t("Choose one")
  defp kind(%{input: "text"}), do: t("Write it down")
  defp kind(%{input: "scale"}), do: t("From 1 to 10")
  defp kind(%{input: "photo"}), do: t("Take a photo")
  defp kind(%{input: "button"}), do: t("Hands up")
  defp kind(_), do: ""

  defp points(1), do: t("1 point")
  defp points(n), do: t("%{n} points", n: n)

  attr :play, :map, required: true

  def countdown(assigns) do
    ~H"""
    <span
      :if={@play.closes_at && @play.state == "open"}
      id={"countdown-#{@play.id}"}
      class="countdown"
      phx-hook="Countdown"
      phx-update="ignore"
      data-at={DateTime.to_iso8601(@play.closes_at)}
    ></span>
    """
  end

  @doc "Who has answered so far, as a row of sigils."
  attr :play, :map, required: true
  attr :guests, :list, required: true

  def answered(assigns) do
    assigns = assign(assigns, :ids, MapSet.new(assigns.play.answers, & &1.user_id))

    ~H"""
    <div class="answered">
      <p class="meta">
        {t("%{n} of %{total} answered", n: MapSet.size(@ids), total: length(@guests))}
      </p>
      <ul class="answered-sigils">
        <li :for={g <- @guests} class={g.id not in @ids && "waiting"} title={g.name}>{g.sigil}</li>
      </ul>
    </div>
    """
  end

  @doc "The answers, the way the card says to reveal them."
  attr :play, :map, required: true
  attr :guests, :map, required: true, doc: "guests by id"

  def results(%{play: %{input: "none"}} = assigns), do: ~H""

  def results(%{play: %{answers: []}} = assigns) do
    ~H"""
    <p class="results-empty">{t("Nobody answered.")}</p>
    """
  end

  def results(%{play: %{input: "photo"}} = assigns) do
    ~H"""
    <ul class="gallery">
      <li :for={a <- sorted(@play.answers)}>
        <img
          src={~p"/uploads/#{a.value}"}
          alt={t("Photo by %{name}", name: a.user.name)}
          loading="lazy"
        />
        <span :if={@play.reveal != "anonymous"}>{a.user.sigil} {a.user.name}</span>
      </li>
    </ul>
    """
  end

  def results(%{play: %{reveal: "winner"}} = assigns) do
    assigns = assign(assigns, :top, top(Game.tally(assigns.play)))

    ~H"""
    <div class="winner">
      <div :for={{value, answers} <- @top} class="winner-one">
        <.value play={@play} value={value} guests={@guests} big />
        <p class="meta">{votes(length(answers))}</p>
      </div>
    </div>
    """
  end

  def results(%{play: %{reveal: "list"}} = assigns) do
    ~H"""
    <ul class="answer-list">
      <li :for={a <- sorted(@play.answers)}>
        <.guest user={a.user} name />
        <span :if={@play.input != "button"} class="answer-value">
          <.value play={@play} value={a.value} guests={@guests} />
        </span>
      </li>
    </ul>
    """
  end

  def results(%{play: %{reveal: "anonymous"}} = assigns) do
    ~H"""
    <ul class="answer-list anonymous">
      <li :for={a <- Enum.sort_by(@play.answers, & &1.value)}>
        <.value play={@play} value={a.value} guests={@guests} />
      </li>
    </ul>
    """
  end

  def results(assigns) do
    tally = Game.tally(assigns.play)
    max = tally |> Enum.map(fn {_, answers} -> length(answers) end) |> Enum.max()
    assigns = assign(assigns, tally: tally, max: max)

    ~H"""
    <p :if={@play.input == "scale"} class="average">
      {t("Average")} <strong>{average(@play.answers)}</strong>
    </p>
    <ol class="tally">
      <li
        :for={{{value, answers}, i} <- Enum.with_index(@tally)}
        class={value == @play.correct && "correct"}
        style={"--share: #{length(answers) / @max}; --i: #{i}"}
      >
        <span class="tally-label"><.value play={@play} value={value} guests={@guests} /></span>
        <span class="tally-bar"><span class="tally-count">{length(answers)}</span></span>
        <span class="tally-voters">
          <span :for={a <- answers} title={a.user.name}>{a.user.sigil}</span>
        </span>
      </li>
    </ol>
    """
  end

  attr :play, :map, required: true
  attr :value, :string, required: true
  attr :guests, :map, required: true
  attr :big, :boolean, default: false

  defp value(%{play: %{input: "pick_guest"}} = assigns) do
    assigns = assign(assigns, :user, Map.get(assigns.guests, String.to_integer(assigns.value)))

    ~H"""
    <span class={["value", @big && "value-big"]}>
      <.guest :if={@user} user={@user} name />
      <span :if={!@user}>{t("Someone who left")}</span>
    </span>
    """
  end

  defp value(%{play: %{input: "button"}} = assigns) do
    ~H"""
    <span class={["value", @big && "value-big"]}>{List.first(@play.options) || t("Me!")}</span>
    """
  end

  defp value(assigns) do
    ~H"""
    <span class={["value", @big && "value-big"]}>{@value}</span>
    """
  end

  defp top([]), do: []

  defp top([{_, answers} | _] = tally),
    do: Enum.filter(tally, fn {_, a} -> length(a) == length(answers) end)

  defp sorted(answers), do: Enum.sort_by(answers, & &1.id)

  defp votes(1), do: t("1 vote")
  defp votes(n), do: t("%{n} votes", n: n)

  defp average(answers) do
    sum = answers |> Enum.map(&String.to_integer(&1.value)) |> Enum.sum()
    decimal(sum / length(answers))
  end

  @doc """
  Guests waiting to be let in, for hosts. The page handles `let_in` and `turn_away` with the
  guest's `id`.
  """
  attr :requests, :list, required: true

  def door(assigns) do
    ~H"""
    <section :if={@requests != []} class="panel door-panel">
      <h2>{t("At the door")}</h2>
      <ul class="guest-list">
        <li :for={user <- @requests}>
          <.guest :if={user.name} user={user} name />
          <span :if={!user.name} class="hint">{t("Still picking a name")}</span>
          <span class="meta">{user.email}</span>
          <span class="actions">
            <button class="btn btn-candle btn-small" phx-click="let_in" phx-value-id={user.id}>
              {t("Let in")}
            </button>
            <button
              class="btn btn-ghost btn-small"
              phx-click="turn_away"
              phx-value-id={user.id}
              data-confirm={t("Turn away %{name}?", name: user.name || user.email)}
            >
              {t("Turn away")}
            </button>
          </span>
        </li>
      </ul>
    </section>
    """
  end

  attr :rows, :list, required: true, doc: "`[{user, points}]` from `Game.leaderboard/0`"
  attr :limit, :integer, default: nil
  attr :me, :map, default: nil

  def leaderboard(assigns) do
    ~H"""
    <ol class="leaderboard">
      <li
        :for={
          {{user, points}, i} <- Enum.with_index(if @limit, do: Enum.take(@rows, @limit), else: @rows)
        }
        class={@me && @me.id == user.id && "is-me"}
      >
        <span class="rank">{i + 1}</span>
        <.guest user={user} name />
        <span class="score">{points}</span>
      </li>
    </ol>
    """
  end
end
