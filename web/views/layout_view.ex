defmodule Jcb.LayoutView do
  use Jcb.Web, :view

  def current_user conn do
    Plug.Conn.get_session conn, :current_user
  end

  defp user_token(conn) do
    if user = conn.assigns[:user] do
      Phoenix.Token.sign(conn, "user socket", user.username)
    end
  end

end
