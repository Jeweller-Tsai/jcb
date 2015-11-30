defmodule Jcb.SessionController do
  use Jcb.Web, :controller

  alias Jcb.User

  def new conn, _params do
    changeset = User.changeset(%User{})
    render conn, "new.html", changeset: changeset
  end

  def create conn, %{"user" => %{"username" => username, "password" => password}} do
    user = Repo.get_by User, username: username
    sign_in user, password, conn
  end

  def delete conn, _params do
    conn
    |> put_flash(:info, "Logged out successfully!")
    |> delete_session(:current_user)
    |> redirect(to: page_path(conn, :index))
  end

  defp sign_in nil, _password, conn do
    conn
    |> put_flash(:error, "Invalid username/password combination!")
    |> redirect(to: page_path(conn, :index))
  end

  defp sign_in user, password, conn do
    if User.check_password(password, user.password_digest) do
      conn
      |> put_session(:current_user, %{id: user.id})
      |> put_flash(:info, "Welcome back, #{user.username}!")
      |> redirect(to: page_path(conn, :index))
    else
      failed_login conn
    end
  end

  defp failed_login conn do
    conn
    |> put_flash(:error, "Invalid username/password combination!")
    |> redirect(to: page_path(conn, :index))
  end
end
