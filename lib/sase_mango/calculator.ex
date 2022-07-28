defmodule SaseMango.Calculator do
  alias SaseMango.Calculator.Input

  def change_input(%Input{} = input, attrs \\ %{}) do
    Input.changeset(input, attrs)
  end

  def run([], _input), do: []

  def run(securities, %Input{} = input) do
    security = Enum.find(securities, fn %{symbol: symbol} -> symbol == input.symbol end)

    total_without_fee = Decimal.mult(input.amount, input.price)
    fee_part = Decimal.div(Decimal.mult(total_without_fee, input.fee), 100)
    total_with_fee = Decimal.add(total_without_fee, fee_part)

    %{
      name: security.name,
      amount: input.amount,
      symbol: security.symbol,
      price: Decimal.new(input.price),
      total_without_fee: total_without_fee,
      total_with_fee: total_with_fee
    }
  end
end
