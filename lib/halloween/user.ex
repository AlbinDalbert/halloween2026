defmodule Halloween.User do
  use Ecto.Schema
  import Ecto.Changeset

  @sigils ~w(🎃 👻 🦇 🕷️ 💀 🧛 🧟 🧙 🕸️ 🐈‍⬛ 🪦 🔮 🕯️ 🍬 🌕 🦉 🐺 🧌 🪄 ⚰️)

  schema "users" do
    field :workos_id, :string
    field :email, :string
    field :name, :string
    field :sigil, :string
    field :avatar_url, :string
    field :host, :boolean, default: false
    timestamps(type: :utc_datetime)
  end

  def sigils, do: @sigils

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:workos_id, :email, :name, :sigil, :avatar_url, :host])
    |> update_change(:name, &trim/1)
    |> validate_required([:workos_id, :sigil])
    |> validate_length(:name, max: 30)
    |> unique_constraint(:workos_id)
  end

  def name_changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :sigil])
    |> update_change(:name, &trim/1)
    |> validate_required([:name])
    |> validate_length(:name, max: 30)
    |> validate_inclusion(:sigil, @sigils)
  end

  defp trim(nil), do: nil
  defp trim(string), do: String.trim(string)
end
