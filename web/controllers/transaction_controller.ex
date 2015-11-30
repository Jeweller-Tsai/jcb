defmodule Jcb.TransactionController do
  use Jcb.Web, :controller

  alias Jcb.Pagination
  alias Jcb.Transaction
  alias Jcb.User
  alias Jcb.Repo
  alias Jcb.Quota

  import Ecto.Query, only: [from: 2]
  #import Ecto.Model, only: [assoc: 2]

  plug :scrub_params, "transaction" when action in [:create, :update]

  plug Jcb.Plugs.Authorization when action in [:new, :create, :update, :edit, :delete]

  plug :target_user when action in [:mine]
  defp target_user(conn, _) do
    if user = Repo.get(User, conn.params["user_id"]) do
      assign(conn, :target_user, user)
    else
      conn
      |> redirect(to: page_path(conn, :index))
      |> halt
    end
  end

  def mine(conn, %{"user_id" => user_id}) do
    user = conn.assigns[:target_user]
    gave = Transaction.from user
    received = Transaction.to user
    render(conn, "mime.html", gave: gave, received: received)
  end

  def index(conn, params) do
    page = Dict.get(params, "page")
    %{result: transactions, prev: prev, next: next} = Pagination.paginate(Transaction, page, 50, [:user, :recipient])
    render(conn, "index.html", transactions: transactions, prev: prev, next: next)
  end

  def new(conn, _params) do
    changeset = Transaction.changeset(%Transaction{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"transaction" => transaction_params}) do
    case TransactionInteraction.create(conn.assigns[:user], transaction_params) do
      {:ok, _transaction} ->
        conn
        |> put_flash(:info, "Transaction created successfully.")
        |> redirect(to: transaction_path(conn, :index))
      {:error, error} ->
        render(conn, "new.html", changeset: error.changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    transaction = Repo.get!(Transaction, id)
    render(conn, "show.html", transaction: transaction)
  end

  def edit(conn, %{"id" => id}) do
    transaction = get_transaction conn, id

    if transaction do
      recipient = Repo.get!(User, transaction.recipient_id)
      changeset = %{transaction | recipient_name: recipient.username}
                  |> Transaction.changeset
      #transaction.recipient_name = recipient.username
      render(conn, "edit.html", transaction: transaction, changeset: changeset)
    else
      log_out conn
    end
  end

  def update(conn, %{"id" => id, "transaction" => transaction_params}) do
    transaction = get_transaction conn, id

    if transaction do
      changeset = Transaction.changeset(transaction, transaction_params)
      case Repo.update(changeset) do
        {:ok, transaction} ->
          conn
          |> put_flash(:info, "Transaction updated successfully.")
          |> redirect(to: transaction_path(conn, :show, transaction))
        {:error, changeset} ->
          render(conn, "edit.html", transaction: transaction, changeset: changeset)
      end
    else
      log_out conn
    end
  end

  #def delete(conn, %{"id" => id}) do
    #transaction = get_transaction conn, id

    ## Here we use delete! (with a bang) because we expect
    ## it to always work (and if it does not, it will raise).
    #Repo.delete!(transaction)

    #conn
    #|> put_flash(:info, "Transaction deleted successfully.")
    #|> redirect(to: transaction_path(conn, :index))
  #end

  defp log_out conn do
    conn
    |> delete_session(:current_user)
    |> put_flash(:error, "You're not allow to modify others' JCBs!")
    |> redirect(to: session_path(conn, :new))
    |> halt
  end

  defp get_transaction conn, id do
    conn.assigns[:user]
    |> assoc(:transactions)
    |> Repo.get(id)
  end
end
