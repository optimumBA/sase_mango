defmodule SaseMangoWeb.SecuritiesView do
  use SaseMangoWeb, :view

  def round_price(price, places \\ 2)

  def round_price(price, places) when is_integer(price) do
    price
    |> Decimal.new()
    |> Decimal.round(places)
  end

  def round_price(price, places) when is_float(price) do
    price
    |> Decimal.from_float()
    |> Decimal.round(places)
  end
end
