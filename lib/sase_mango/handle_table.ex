defmodule SaseMango.HandleTable do
  @moduledoc """
  The HandleTable context module gives sort and filter/search support for the table and table form.
  """

  alias __MODULE__.SearchFilter

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type field :: String.t()
  @type search_filter :: SearchFilter.t()
  @type securities :: list()
  @type sort_order :: atom()

  @number_fields [
    "ask_price",
    "bid_price",
    "book_value",
    "bvs",
    "dividend_roi",
    "eps_roi",
    "market_value",
    "nominal_price",
    "pb",
    "pe",
    "price",
    "profit_margin"
  ]

  @text_fields ["symbol", "name"]

  @doc """
  Returns a changeset for a `FilterForm.SearchFilter`.
  """
  @spec change_table_filter(search_filter(), attrs()) :: changeset()
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
  Sorts the list of securities by field type in ascending/descending order.
  """
  @spec sort_table(securities(), field(), sort_order()) :: securities()
  def sort_table(securities, field, sort_order) do
    case get_sort_params(field, sort_order) do
      nil -> securities
      sort_params -> Enum.sort_by(securities, & &1[String.to_existing_atom(field)], sort_params)
    end
  end
end
