defmodule Jcb.Repo.Migrations.CreateTransaction do
  use Ecto.Migration

  def change do
    create table(:transactions) do
      add :user_id, references(:users)
      add :recipient_id, references(:users)
      add :reason, :text

      timestamps
    end

    create index(:transactions, [:user_id])
    create index(:transactions, [:recipient_id])
  end
end
