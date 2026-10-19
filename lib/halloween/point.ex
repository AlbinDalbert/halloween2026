defmodule Halloween.Point do
  use Ecto.Schema

  schema "points" do
    belongs_to :user, Halloween.User
    belongs_to :play, Halloween.Play
    field :amount, :integer
    field :reason, :string
    timestamps(type: :utc_datetime, updated_at: false)
  end
end
