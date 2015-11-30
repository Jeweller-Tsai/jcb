defmodule Jcb.QuotaTest do
  use Jcb.ModelCase, async: true
  use Timex

  alias Jcb.Quota

  @valid_attrs %{amount: 10, user_id: 42}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    user = TestHelper.create_user
    changeset = Quota.changeset(%Quota{}, %{@valid_attrs | user_id: user.id})
    assert changeset.valid?
    {:ok, _} = Repo.insert(changeset)
  end

  test "changeset with invalid attributes" do
    changeset = Quota.changeset(%Quota{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "set month automatically" do
    changeset = Quota.changeset(%Quota{}, @valid_attrs)
    assert changeset.valid?
    assert current_month == Ecto.Changeset.get_field(changeset, :month)
  end

  test "amount should be in 0..10" do
    changeset = Quota.changeset(%Quota{}, %{@valid_attrs | amount: 0})
    assert changeset.valid?

    changeset = Quota.changeset(%Quota{}, %{@valid_attrs | amount: -1})
    refute changeset.valid?

    changeset = Quota.changeset(%Quota{}, %{@valid_attrs | amount: 11})
    refute changeset.valid?
  end

  test "get a quota for update" do
    month = "201510"
    user = TestHelper.create_user
    user1 = TestHelper.create_user
    Quota.changeset(%Quota{}, %{amount: 6, user_id: user.id, month: month})
    |> Repo.insert!

    Quota.changeset(%Quota{}, %{@valid_attrs | user_id: user.id})
    |> Repo.insert!

    Quota.changeset(%Quota{}, %{@valid_attrs | user_id: user1.id})
    |> Repo.insert!

    old_quota = Quota.select_for_update user.id, month
    assert old_quota.user_id == user.id
    assert old_quota.month == month

    current_quota = Quota.select_for_update user.id

    assert current_quota.user_id == user.id
    assert current_quota.month == current_month
  end

  defp current_month do
    %{year: year, month: month } = Date.now("Asia/Shanghai")
    if month < 10, do: "#{year}0#{month}", else: "#{year}#{month}"
  end
end
