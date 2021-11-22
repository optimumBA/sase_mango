defmodule SaseMangoWeb.SecuritiesView do
  use SaseMangoWeb, :view

  def segment("Free market - Subsegment 1"), do: "ST1"
  def segment("Free market - Subsegment 2"), do: "ST2"
  def segment("Free market - Subsegment 3"), do: "ST3"
  def segment("The Official market - The Official market of companies"), do: "Companies"
  def segment("The Official market - The Official market of funds"), do: "Funds"

  def format_number(number) when is_integer(number) do
    Integer.to_string(number)
  end

  def format_number(%Decimal{} = number, decimals) do
    number
    |> Decimal.round(decimals)
    |> Decimal.to_string()
  end

  def format_percentage(%Decimal{} = number) do
    number
    |> Decimal.mult(100)
    |> format_number(2)
    |> Kernel.<>("%")
  end
end
