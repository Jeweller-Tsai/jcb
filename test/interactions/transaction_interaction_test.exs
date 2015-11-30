defmodule Jcb.TransactionInteractionTest do
  use Jcb.ModelCase

  alias Jcb.Transaction
  alias Jcb.Quota
  alias Jcb.Repo

  setup do
    giver = TestHelper.create_user
    recipient = TestHelper.create_user
    transaction_params = %{recipient_name: recipient.username, reason: "Thank you for testing!"}
    {:ok, giver: giver, recipient: recipient, transaction_params: transaction_params}
  end

  test "create a transaction when there is no one", %{giver: giver, recipient: recipient, transaction_params: transaction_params} do
    TransactionInteraction.create giver, transaction_params
    quota = Repo.get_by!(Quota, user_id: giver.id)
    assert quota.amount == 1
    transaction = Repo.get_by!(Transaction, user_id: giver.id)
    assert transaction.recipient_id == recipient.id
  end

  test "update quota when there are transactions", %{giver: giver, recipient: recipient, transaction_params: transaction_params} do
    create_quota giver.id, 1

    TransactionInteraction.create giver, transaction_params
    quota = Repo.get_by!(Quota, user_id: giver.id)
    assert quota.amount == 2
    transaction = Repo.get_by!(Transaction, user_id: giver.id)
    assert transaction.recipient_id == recipient.id
  end

  test "out of quota", %{giver: giver, transaction_params: transaction_params} do
    create_quota giver.id, 10

    TransactionInteraction.create giver, transaction_params
    quota = Repo.get_by!(Quota, user_id: giver.id)
    assert quota.amount == 10
    refute Repo.get_by(Transaction, user_id: giver.id)
  end

  test "concurrently create transactions when quota not exists", %{giver: giver, recipient: recipient, transaction_params: transaction_params} do
    create_transactions_concurrently giver, transaction_params

    quota = Repo.get_by!(Quota, user_id: giver.id)
    assert quota.amount == 2

    transactions = Repo.all(Transaction, user_id: giver.id, recipient_id: recipient.id)
    assert length(transactions) == 2
  end

  test "concurrently create transactions when quota exists", %{giver: giver, recipient: recipient, transaction_params: transaction_params} do
    create_quota giver.id, 1

    create_transactions_concurrently giver, transaction_params

    quota = Repo.get_by!(Quota, user_id: giver.id)
    assert quota.amount == 3

    transactions = Repo.all(Transaction, user_id: giver.id, recipient_id: recipient.id)
    assert length(transactions) == 2
  end

  test "concurrently create transactions when running out of quota", %{giver: giver, recipient: recipient, transaction_params: transaction_params} do
    create_quota giver.id, 9

    create_transactions_concurrently giver, transaction_params

    quota = Repo.get_by!(Quota, user_id: giver.id)
    assert quota.amount == 10

    transactions = Repo.all(Transaction, user_id: giver.id, recipient_id: recipient.id)
    assert length(transactions) == 1
  end

  defp create_quota user_id, amount do
    Quota.changeset(%Quota{}, %{user_id: user_id, amount: amount})
    |> Repo.insert!
  end

  defp create_transactions_concurrently giver, transaction_params do
    me = self

    {:ok, another} = Task.start_link fn ->
      assert_receive :create_transaction, 5000
      TransactionInteraction.create giver, transaction_params
      send me, :created
    end

    send another, :create_transaction
    TransactionInteraction.create giver, transaction_params
    assert_receive :created, 5000
  end

  test "cc", %{giver: giver, recipient: recipient, transaction_params: transaction_params} do
    cc giver, transaction_params
    quota = Repo.get_by!(Quota, user_id: giver.id)
    assert quota.amount == 10
    transactions = Repo.all(Transaction, user_id: giver.id, recipient_id: recipient.id)
    assert length(transactions) == 10
  end

  defp cc giver, transaction_params do
    me = self

    pids = Enum.map(1..10, fn(i) ->
      {:ok, pid} = Task.start_link fn ->
        assert_receive :create_transaction, 5000
        TransactionInteraction.create giver, transaction_params
        send me, :created
      end

      pid
    end)

    {:ok, _} = Task.start_link fn ->
      for pid <- pids, do: send(pid, :create_transaction)
    end
    TransactionInteraction.create giver, transaction_params
    assert_receive :created, 5000
  end
end
