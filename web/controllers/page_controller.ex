defmodule Jcb.PageController do
  use Jcb.Web, :controller
  alias Jcb.Repo
  alias Jcb.User

  def index(conn, _params) do
    users = Repo.all(User)
    render conn, "index.html", users: users
  end
end
