defmodule Halloween.Repo.Migrations.CreateDecorations do
  use Ecto.Migration

  def change do
    # A decoration is on in a scene (between cards, or with a card on stage) while its row exists.
    create table(:decorations) do
      add :scene, :string, null: false
      add :name, :string, null: false
    end

    create unique_index(:decorations, [:scene, :name])
  end
end
