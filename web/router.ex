defmodule Jcb.Router do
  use Jcb.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Jcb do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    resources "/users", UserController
    resources "/sessions", SessionController, only: [:new, :create, :delete]
    resources "/transactions", TransactionController, except: [:delete]
    get "/users/:user_id/transactions", TransactionController, :mine
  end

  # Other scopes may use custom stacks.
  # scope "/api", Jcb do
  #   pipe_through :api
  # end
end
