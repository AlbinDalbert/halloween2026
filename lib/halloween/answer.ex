defmodule Halloween.Answer do
  use Ecto.Schema

  schema "answers" do
    belongs_to :play, Halloween.Play
    belongs_to :user, Halloween.User
    field :value, :string
    timestamps(type: :utc_datetime)
  end
end
