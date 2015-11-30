defmodule Jcb.UserChannel do
  use Phoenix.Channel

  alias Jcb.User

  def join("users:search", _message, socket) do
    {:ok, socket}
  end

  def handle_in("search_name", %{"username" => username}, socket) do
    current_username =  socket.assigns[:username]
    usernames = username
                |> User.search_by_username
                |> Enum.reject(&(&1 == current_username))
                |> Enum.take(15)
    push socket, "new_usernames", %{usernames: usernames}
    {:noreply, socket}
  end

end
