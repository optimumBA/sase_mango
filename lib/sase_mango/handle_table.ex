defmodule SaseMango.HandleTable do
  @moduledoc """
  The HandleTable context module gives sort and filter/search support for the table and table form.
  """

  alias __MODULE__.SearchFilter

  @number_fields [
    "ask_price",
    "bid_price",
    "book_value",
    "bvs",
    "company_number",
    "dividend_roi",
    "eps_roi",
    "market_value",
    "nominal_price",
    "pb",
    "pe",
    "price",
    "profit_margin",
    "investor_shares_number",
    "total_capital"
  ]

  @text_fields ["symbol", "name"]

  @doc """
  Returns a changeset for a `FilterForm.SearchFilter`.
  """
  def change_table_filter(%SearchFilter{} = filter, attrs \\ %{}) do
    SearchFilter.changeset(filter, attrs)
  end

  defp get_sort_params(field, sort_order) when field in @number_fields do
    {sort_order, Decimal}
  end

  defp get_sort_params(field, sort_order) when field in @text_fields do
    sort_order
  end

  defp get_sort_params(_field, _sort_order), do: nil

  @doc """
  Sorts the list of items by field type in ascending/descending order.
  """
  def sort_table(list, field, sort_order) do
    case get_sort_params(field, sort_order) do
      nil -> list
      sort_params -> Enum.sort_by(list, & &1[String.to_existing_atom(field)], sort_params)
    end
  end

  @doc """
  Makes the slug name from string.
  """
  def create_slug(title) do
    title
    |> String.downcase()
    |> String.replace(~r/[^a-zA-Z0-9 &]/, "")
    |> String.replace("&", "and")
    |> String.split()
    |> Enum.join("-")
  end

  @doc """
  Handles URL params when filtering/sorting tables.
  """
  def merge_url_params(socket, options) do
    %{sort_options: sort_options, filter_options: filter_options} = socket.assigns

    url_params =
      %{}
      |> Map.merge(sort_options)
      |> Map.merge(Map.from_struct(filter_options))
      |> Map.merge(options)
      |> Enum.reject(fn {_key, value} ->
        is_nil(value) || (is_binary(value) && String.length(value) == 0)
      end)
      |> Map.new()

    url_params
  end

  @doc """
  Returns the sort order value.
  """
  def set_sort_order("asc"), do: :asc
  def set_sort_order("desc"), do: :desc
  def set_sort_order(_value), do: :desc

  @doc """
  Reverse the sort order value.
  """
  def revert_sort_order(:asc), do: :desc
  def revert_sort_order(:desc), do: :asc
end
