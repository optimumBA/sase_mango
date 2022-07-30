defmodule SaseMango.Calculator do
  alias SaseMango.Calculator.Input

  def change_input(%Input{} = input, attrs \\ %{}) do
    Input.changeset(input, attrs)
  end

  def run([], _input), do: []

  def run(securities, %Input{} = input) do
    security = Enum.find(securities, &(&1.symbol == input.symbol))

    total_without_fee = Decimal.mult(input.amount, input.price)
    fee_part = Decimal.div(Decimal.mult(total_without_fee, input.fee), 100)
    total_with_fee = Decimal.add(total_without_fee, fee_part)

    %{
      id: security.symbol <> Decimal.to_string(input.amount) <> Decimal.to_string(input.price),
      name: security.name,
      amount: input.amount,
      symbol: security.symbol,
      price: Decimal.new(input.price),
      total_without_fee: total_without_fee,
      total_with_fee: total_with_fee
    }
  end

  def add_new_item(results, result) do
    total_without_fee = Decimal.add(results.total_without_fee, result.total_without_fee)
    total_with_fee = Decimal.add(results.total_with_fee, result.total_with_fee)

    %{
      securities: [result | results.securities],
      total_without_fee: total_without_fee,
      total_with_fee: total_with_fee
    }
  end

  def maybe_add_item(securities, results, input) when length(results.securities) > 0 do
    result = run(securities, input)

    case Enum.any?(results.securities, &(&1.id == result.id)) do
      true -> results
      false -> add_new_item(results, result)
    end
  end

  def maybe_add_item(securities, results, input) do
    add_new_item(results, run(securities, input))
  end
end
