defmodule Halloween.Decoration do
  @moduledoc """
  A decoration on the TV, on in one scene while its row exists. The scenes are `idle`, between
  cards, and `stage`, with a card on stage. Each scene has its own set.
  """
  use Ecto.Schema

  @names ~w(pumpkin scarecrow moon bats ghost spider cobwebs eyes fog)

  @doc "Every decoration there is, in the order they're offered."
  def names, do: @names

  def scenes, do: ~w(idle stage)

  schema "decorations" do
    field :scene, :string
    field :name, :string
  end
end
