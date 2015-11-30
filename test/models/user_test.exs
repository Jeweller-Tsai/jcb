defmodule Jcb.UserTest do
  use Jcb.ModelCase

  alias Jcb.User
  alias Jcb.Transaction
  alias Jcb.Quota
  alias Jcb.Repo

  @valid_attrs %{email: "test@example.com", username: "test", password: "123456", password_confirmation: "123456"}
  @invalid_attrs %{}


  setup do
    #giver = User.changeset(%User{}, @valid_attrs) |> Repo.insert!

    #recipient = User.changeset(%User{}, %{@valid_attrs | email: "test1@example.com", username: "test1"})
                #|> Repo.insert!

                giver = TestHelper.create_user
                recipient = TestHelper.create_user
    {:ok, giver: giver, recipient: recipient}
  end

  test "create a transaction when there is no one", %{giver: giver, recipient: recipient} do
    transaction_params = %{recipient_name: recipient.username, reason: "Thank you for testing!"}
    User.create_transaction giver, transaction_params
    quota = Repo.get_by!(Quota, user_id: giver.id)
    assert quota.amount == 1
    transaction = Repo.get_by!(Transaction, user_id: giver.id)
    assert transaction.recipient_id == recipient.id
  end
  #test "changeset with valid attributes" do
    #changeset = User.changeset(%User{}, @valid_attrs)
    #assert changeset.valid?
  #end

  #test "changeset with invalid attributes" do
    #changeset = User.changeset(%User{}, @invalid_attrs)
    #refute changeset.valid?
  #end
end
