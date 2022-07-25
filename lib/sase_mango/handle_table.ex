defmodule SaseMango.HandleTable do
  @moduledoc """
    The HandleTable context module gives sort and filter/search support for the table and table form.

  """

  @number_fields [
    :ask_price,
    :bid_price,
    :book_value,
    :bvs,
    :dividend_roi,
    :eps_roi,
    :market_value,
    :nominal_price,
    :pb,
    :pe,
    :price,
    :profit_margin
  ]

  @text_fields [:symbol, :name]

  @doc """
    Helper function that returns sort parameters.

  """
  def get_sort_params(field, sort_order) when field in @number_fields do
    {sort_order, Decimal}
  end

  def get_sort_params(field, sort_order) when field in @text_fields do
    sort_order
  end

  @doc """
    Sorts the list of securities by field type in ascending/descending order.

  """
  def sort_table(securities, field, sort_order) do
    sort_params = get_sort_params(field, sort_order)

    Enum.sort_by(securities, & &1[field], sort_params)
  end
end
