defmodule Jcb.Transaction do
  use Jcb.Web, :model
  use Timex

  alias Jcb.Repo
  alias Jcb.User
  alias Jcb.Quota

  import Ecto.Query, only: [from: 2]

  schema "transactions" do
    belongs_to :user, User
    belongs_to :recipient, User
    belongs_to :quota, Quota

    field :reason, :string
    field :recipient_name, :string, virtual: true

    timestamps
  end

  @required_fields ~w(recipient_name reason)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_recipient
  end

  defp validate_recipient changeset do
    if recipient_name = get_change(changeset, :recipient_name) do
      if recipient = Repo.get_by(User, username: recipient_name) do
        put_change changeset, :recipient_id, recipient.id
      else
        add_error changeset, :recipient, "not exists"
      end
    else
      add_error changeset, :recipient_name, "is empty"
    end
  end

  def to user do
    {started_at, ended_at} = month_edge
    from(t in __MODULE__, [
      where: t.recipient_id == ^user.id,
      where: t.inserted_at >= ^started_at,
      where: t.inserted_at < ^ended_at,
      preload: :user
    ]) |> Repo.all
  end

  def from user do
    {started_at, ended_at} = month_edge
    from(t in __MODULE__, [
      where: t.user_id == ^user.id,
      where: t.inserted_at >= ^started_at,
      where: t.inserted_at < ^ended_at,
      preload: :recipient
    ]) |> Repo.all
  end

  defp month_edge do
    from = Date.now("Asia/Shanghai") |> Date.set(day: 1, hour: 0, minute: 0, second: 0)
    interval = Interval.new(from: from, until: [months: 1])
    {DateConvert.to_erlang_datetime(from), DateConvert.to_erlang_datetime(interval.until)}
  end
end
