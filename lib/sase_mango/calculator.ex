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

  # defp correct_volume(volume, price, fee, max_amount, max_volume) do
  #   amount = Decimal.mult(volume, price)

  #   total_amount =
  #     fee
  #     |> Decimal.div(100)
  #     |> Decimal.mult(amount)
  #     |> Decimal.add(amount)

  #   cond do
  #     volume <= 0 ->
  #       0

  #     Decimal.gt?(total_amount, max_amount) ->
  #       correct_volume(volume - 1, price, fee, max_amount, max_volume)

  #     volume > max_volume ->
  #       max_volume

  #     true ->
  #       volume
  #   end
  # end
end
