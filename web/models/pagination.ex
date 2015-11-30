defmodule Jcb.Pagination do

  alias Jcb.Repo
  import Ecto.Query, only: [from: 2]

  def paginate(model, page, size, preloads \\ nil) do
    page = to_page page
    offset = (page - 1) * size

    result = from(model, limit: ^size, offset: ^offset)
              |> Repo.all
              |> Repo.preload preloads
    count = from(u in model, select: count(u.id))
            |> Repo.one

    prev = if page > 1, do: page - 1
    next = if offset + size < count, do: page + 1
    %{result: result, prev: prev, next: next}
  end

  defp to_page(nil), do: 1

  defp to_page(page) do
    try do
      page = String.to_integer page
      if page > 0, do: page, else: 1
    rescue
      _ -> 1
    end
  end
end
