defmodule TransactionInteraction do
  alias Jcb.Repo
  alias Jcb.Quota
  alias Jcb.Transaction

  import Ecto.Model, only: [build: 3]

  def create user, transaction_params do
    try do
      Repo.transaction fn ->
        quota = update_or_create_quota! user
        create_transaction! user, quota, transaction_params
      end
    rescue
      e -> {:error, e}
    end
  end

  defp update_or_create_quota! user do
    Quota.select_for_update(user.id)
    |> _update_or_create_quota!(user)
  end

  defp _update_or_create_quota! nil, user do
    user
    |> build(:quotas, %{})
    |> Quota.changeset(%{amount: 1})
    |> Repo.insert!
  end

  defp _update_or_create_quota! quota, _user do
    quota
    |> Quota.changeset(%{amount: quota.amount + 1})
    |> Repo.update!
  end

  defp create_transaction! user, quota, params do
    user
    |> build(:transactions, quota_id: quota.id)
    |> Transaction.changeset(params)
    |> Repo.insert!
  end
end
