ExUnit.start

Mix.Task.run "ecto.create", ["--quiet"]
Mix.Task.run "ecto.migrate", ["--quiet"]
Ecto.Adapters.SQL.begin_test_transaction(Jcb.Repo)

defmodule TestHelper do
  alias Jcb.User
  alias Jcb.Repo

  def create_user do
    n = :random.uniform
    changeset = User.changeset(%User{}, %{username: "test#{n}", email: "test#{n}@exampl.com", password: "123456", password_confirmation: "123456"})
    case Repo.insert(changeset) do
      {:ok, user } -> user
      _ -> create_user
    end
  end
end
