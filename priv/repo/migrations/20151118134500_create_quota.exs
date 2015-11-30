defmodule Jcb.Repo.Migrations.CreateQuota do
  use Ecto.Migration

  def change do
    create table(:quotas) do
      add :month, :string, size: 6
      add :amount, :integer, default: 0
      add :user_id, references(:users)

      timestamps
    end

    create index(:quotas, [:user_id, :month], unique: true)
    execute "ALTER TABLE quotas ADD CONSTRAINT validate_amount CHECK (amount < 11);"
  end
end
