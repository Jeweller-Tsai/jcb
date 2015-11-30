defmodule Jcb.Repo.Migrations.AddQuotaIdToTransactions do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add :quota_id, references(:quotas)
    end

    create index(:transactions, [:quota_id])
  end
end
