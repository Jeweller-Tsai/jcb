defmodule Jcb.User do
  use Jcb.Web, :model
  #use Timex
  import Ecto.Query, only: [from: 2]
  alias Jcb.Repo
  alias Jcb.Quota
  alias Jcb.Transaction

  schema "users" do
    has_many :transactions, Transaction
    has_many :jcbs, Transaction, foreign_key: :recipient_id
    has_many :quotas, Quota

    field :username, :string
    field :email, :string
    field :password_digest, :string

    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true

    timestamps
  end

  @required_fields ~w(username email password password_confirmation)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> update_change(:email, &String.downcase/1)
    |> update_change(:username, &String.downcase/1)
    |> unique_constraint(:email)
    |> unique_constraint(:username)
    |> validate_format(:email, ~r/\A[\w\.%\+\-]+@([\w\-]+\.)+(\w{2,})\z/i)
    |> validate_length(:password, min: 6, max: 30)
    |> validate_confirmation(:password)
    |> hash_password
  end

  defp hash_password(changeset) do
    if password = get_change(changeset, :password) do
      put_change(changeset, :password_digest, Comeonin.Bcrypt.hashpwsalt(password))
    else
      changeset
    end
  end

  def check_password password, password_digest do
    Comeonin.Bcrypt.checkpw(password, password_digest)
  end

  def search_by_username "" do
    []
  end

  def search_by_username username do
    username = username
                |> String.strip
                |> String.replace(~r/ +/, "%")

    from(u in __MODULE__, where: ilike(u.username, "%#{username}%"), select: u.username)
    |> Repo.all
  end

end
