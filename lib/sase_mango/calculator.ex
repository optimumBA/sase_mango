defmodule SaseMango.Calculator do
  @moduledoc false

  alias SaseMango.Calculator.Input

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type input :: Input.t()
  @type results :: map()
  @type securities :: [map()]

  @spec change_input(input(), attrs()) :: changeset()
  def change_input(%Input{} = input, attrs \\ %{}) do
    Input.changeset(input, attrs)
  end

  @spec maybe_add_item(securities(), results(), input()) :: results()
  def maybe_add_item(securities, results, input) when length(results.securities) > 0 do
    result = run(securities, input)

    if Enum.any?(results.securities, &(&1.symbol == result.symbol)) do
      update_item(results, result)
    else
      add_new_item(results, result)
    end
  end

  def maybe_add_item(securities, results, input) do
    add_new_item(results, run(securities, input))
  end

  defp add_new_item(results, result) do
    total_without_fee = Decimal.add(results.total_without_fee, result.total_without_fee)
    total_with_fee = Decimal.add(results.total_with_fee, result.total_with_fee)

    %{
      securities: [result | results.securities],
      total_without_fee: total_without_fee,
      total_with_fee: total_with_fee
    }
  end

  defp update_item(results, result) do
    old_security = Enum.find(results.securities, &(&1.symbol == result.symbol))

    total_without_fee =
      results.total_without_fee
      |> Decimal.sub(old_security.total_without_fee)
      |> Decimal.add(result.total_without_fee)

    total_with_fee =
      results.total_with_fee
      |> Decimal.sub(old_security.total_with_fee)
      |> Decimal.add(result.total_with_fee)

    filtered_securities = Enum.filter(results.securities, &(&1.symbol != result.symbol))

    %{
      securities: Enum.sort_by([result | filtered_securities], & &1.symbol, :asc),
      total_without_fee: total_without_fee,
      total_with_fee: total_with_fee
    }
  end

  defp run([], _input), do: []

  defp run(securities, %Input{} = input) do
    security = Enum.find(securities, &(&1.symbol == input.symbol))

    total_without_fee = Decimal.mult(input.amount, input.price)

    fee_part =
      total_without_fee
      |> Decimal.mult(input.fee)
      |> Decimal.div(100)

    total_with_fee = Decimal.add(total_without_fee, fee_part)

    %{
      amount: input.amount,
      id: security.symbol <> Decimal.to_string(input.amount) <> Decimal.to_string(input.price),
      name: security.name,
      price: Decimal.new(input.price),
      symbol: security.symbol,
      total_with_fee: total_with_fee,
      total_without_fee: total_without_fee
    }
  end
end
