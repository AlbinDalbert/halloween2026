defmodule Halloween.Card do
  @moduledoc """
  The one building block of every game. A card is some text shown to an audience, an optional
  way to answer it, and a way to reveal the answers on the TV.

    * `audience` - `everyone` puts the card on the stage, where every screen shows it.
      `personal` deals it to one guest, who sees it privately (challenges, secret roles).
    * `input` - how guests answer. `none` just shows the text.
    * `reveal` - how the answers are shown on stage once the host reveals them.
    * `options` - the choices for `pick_option`, or the button label for `button`.
    * `correct` - for `pick_option`: guests who pick it get the points.
    * `points` - for `pick_guest` the most picked guest gets them, for a personal card the
      guest gets them when the host approves it.
    * `seconds` - closes answers automatically when the time runs out.

  `{guest}` in the text is replaced by a random guest when the card is played.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @audiences ~w(everyone personal)
  @inputs ~w(none pick_guest pick_option text scale photo button)
  @reveals ~w(tally winner list anonymous)

  schema "cards" do
    belongs_to :deck, Halloween.Deck
    field :text, :string
    field :audience, :string, default: "everyone"
    field :input, :string, default: "pick_guest"
    field :reveal, :string, default: "tally"
    field :options, {:array, :string}, default: []
    field :correct, :string
    field :points, :integer, default: 0
    field :seconds, :integer
    timestamps(type: :utc_datetime)
  end

  def audiences, do: @audiences
  def inputs, do: @inputs
  def reveals, do: @reveals

  def changeset(card, attrs) do
    card
    |> cast(attrs, [
      :deck_id,
      :text,
      :audience,
      :input,
      :reveal,
      :options,
      :correct,
      :points,
      :seconds
    ])
    |> update_change(:options, fn options ->
      options |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))
    end)
    |> update_change(:correct, &trim/1)
    |> validate_required([:deck_id, :text, :audience, :input, :reveal, :points])
    |> validate_inclusion(:audience, @audiences)
    |> validate_inclusion(:input, @inputs)
    |> validate_inclusion(:reveal, @reveals)
    |> validate_number(:points, greater_than_or_equal_to: 0)
    |> validate_number(:seconds, greater_than: 0)
    |> validate_options()
  end

  defp validate_options(changeset) do
    input = get_field(changeset, :input)
    options = get_field(changeset, :options)
    correct = get_field(changeset, :correct)

    cond do
      input == "pick_option" and length(options) < 2 ->
        add_error(changeset, :options, "needs at least two options")

      get_field(changeset, :audience) == "personal" and input not in ~w(none button) ->
        add_error(changeset, :input, "must be a challenge or a secret for a personal card")

      input == "pick_option" and correct not in [nil | options] ->
        add_error(changeset, :correct, "must be one of the options")

      true ->
        changeset
    end
  end

  defp trim(nil), do: nil
  defp trim(string), do: String.trim(string)
end
