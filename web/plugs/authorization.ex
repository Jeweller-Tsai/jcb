defmodule Jcb.Plugs.Authorization do
  use Jcb.Web, :controller

  def init default do
    default
  end

  def call conn, _params do
    user = get_session(conn, :current_user)
    if user do
      if user = Jcb.Repo.get(Jcb.User, user.id) do
        assign(conn, :user, user)
      else
        delete_session(conn, :current_user)
        |> sign_out
      end
    else
      sign_out conn
    end
  end

  defp sign_out conn do
    conn
    |> put_flash(:error, "Please log in to proceed!")
    |> redirect(to: session_path(conn, :new))
    |> halt()
  end
end
