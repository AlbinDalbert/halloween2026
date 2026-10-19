defmodule Halloween.Play do
  @moduledoc """
  A card in the game. Plays copy their card's fields, so editing a card never changes a play.

  A stage play (`audience: "everyone"`) goes `open` -> `closed` -> `revealed` -> `finished`.
  A personal play (`user_id` set) goes `open` -> `claimed` -> `approved`, or is `finished`
  when the host discards it.
  """
  use Ecto.Schema

  schema "plays" do
    belongs_to :card, Halloween.Card
    belongs_to :deck, Halloween.Deck
    belongs_to :user, Halloween.User
    field :text, :string
    field :audience, :string
    field :input, :string
    field :reveal, :string
    field :options, {:array, :string}, default: []
    field :correct, :string
    field :points, :integer, default: 0
    field :closes_at, :utc_datetime
    field :state, :string
    has_many :answers, Halloween.Answer
    timestamps(type: :utc_datetime)
  end
end
