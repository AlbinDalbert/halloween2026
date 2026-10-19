defmodule Halloween.Repo.Migrations.AddApprovedToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :approved, :boolean, null: false, default: false
    end

    # Everyone already here was let in before there was a door.
    execute "UPDATE users SET approved = 1", ""
  end
end
