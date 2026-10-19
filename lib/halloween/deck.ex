defmodule Halloween.Deck do
  use Ecto.Schema
  import Ecto.Changeset

  schema "decks" do
    field :name, :string
    field :description, :string
    has_many :cards, Halloween.Card, preload_order: [asc: :id]
    timestamps(type: :utc_datetime)
  end

  def changeset(deck, attrs) do
    deck
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
  end
end
