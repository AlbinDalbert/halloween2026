defmodule Halloween.Repo.Migrations.CreateTables do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :workos_id, :string, null: false
      add :email, :string
      add :name, :string
      add :sigil, :string, null: false
      add :avatar_url, :string
      add :host, :boolean, null: false, default: false
      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:workos_id])

    create table(:decks) do
      add :name, :string, null: false
      add :description, :string
      timestamps(type: :utc_datetime)
    end

    create table(:cards) do
      add :deck_id, references(:decks, on_delete: :delete_all), null: false
      add :text, :text, null: false
      add :audience, :string, null: false
      add :input, :string, null: false
      add :reveal, :string, null: false
      add :options, {:array, :string}, null: false, default: []
      add :correct, :string
      add :points, :integer, null: false, default: 0
      add :seconds, :integer
      timestamps(type: :utc_datetime)
    end

    create index(:cards, [:deck_id])

    # A play is one card in the game. It copies the card's fields so that editing the card
    # never changes a play, and holds the text with its {guest} placeholders filled in.
    create table(:plays) do
      add :card_id, references(:cards, on_delete: :nilify_all)
      add :deck_id, references(:decks, on_delete: :nilify_all)
      add :user_id, references(:users, on_delete: :delete_all)
      add :text, :text, null: false
      add :audience, :string, null: false
      add :input, :string, null: false
      add :reveal, :string, null: false
      add :options, {:array, :string}, null: false, default: []
      add :correct, :string
      add :points, :integer, null: false, default: 0
      add :closes_at, :utc_datetime
      add :state, :string, null: false
      timestamps(type: :utc_datetime)
    end

    create index(:plays, [:user_id])
    create index(:plays, [:state])

    create table(:answers) do
      add :play_id, references(:plays, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :value, :text, null: false
      timestamps(type: :utc_datetime)
    end

    create unique_index(:answers, [:play_id, :user_id])

    create table(:points) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :play_id, references(:plays, on_delete: :nilify_all)
      add :amount, :integer, null: false
      add :reason, :string
      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:points, [:user_id])
  end
end
