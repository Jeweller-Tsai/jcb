defmodule Jcb.Quota do
  use Jcb.Web, :model
  use Timex

  alias Jcb.User
  alias Jcb.Repo
  alias Jcb.Transaction

  schema "quotas" do
    belongs_to :user, User
    has_many :transactions, Transaction

    field :month, :string
    field :amount, :integer

    timestamps
  end

  @required_fields ~w(user_id amount)
  @optional_fields ~w(month)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_inclusion(:amount, 0..10, message: "ran out of quota!")
    |> set_month
  end

  def this_month do
    {:ok, month} = Date.now("Asia/Shanghai")
                    |> DateFormat.format("%Y%m", :strftime)
    month
  end

  defp set_month changeset do
    if get_field(changeset, :month) do
      changeset
    else
      put_change(changeset, :month, this_month)
    end
  end

  def select_for_update user_id, month \\ this_month do
    from(q in __MODULE__,
    where: q.user_id == ^user_id,
    where: q.month == ^month,
    lock: "FOR UPDATE")
    |> Repo.one
  end
end
