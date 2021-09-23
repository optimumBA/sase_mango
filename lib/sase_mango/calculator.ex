defmodule SaseMango.Calculator do
  alias SaseMango.Calculator.Input

  def change_input(%Input{} = input, attrs \\ %{}) do
    Input.changeset(input, attrs)
  end

  def run([], _input), do: []

  def run(securities, %Input{} = input) do
    amount_per_issuer = Decimal.div(input.amount, length(securities))

    securities =
      securities
      |> Enum.map(fn %{} = security ->
        volume =
          amount_per_issuer
          |> Decimal.div_int(security.ask_price)
          |> Decimal.to_integer()
          |> correct_volume(security.ask_price, input.fee, amount_per_issuer, security.ask_volume)

        amount = Decimal.mult(volume, security.ask_price)
        fee = Decimal.mult(amount, input.fee) |> Decimal.div(100)
        total = Decimal.add(amount, fee)

        %{
          amount: amount,
          fee: fee,
          name: security.name,
          symbol: security.symbol,
          price: security.ask_price,
          total: total,
          volume: volume
        }
      end)
      |> Enum.reject(fn row -> row.volume <= 0 end)

    total =
      Enum.reduce(securities, Decimal.new(0), fn result, total ->
        Decimal.add(total, result.total)
      end)

    %{securities: securities, total: total}
  end

  defp correct_volume(volume, price, fee, max_amount, max_volume) do
    amount = Decimal.mult(volume, price)

    total_amount =
      fee
      |> Decimal.div(100)
      |> Decimal.mult(amount)
      |> Decimal.add(amount)

    cond do
      volume <= 0 ->
        0

      Decimal.gt?(total_amount, max_amount) ->
        correct_volume(volume - 1, price, fee, max_amount, max_volume)

      volume > max_volume ->
        max_volume

      true ->
        volume
    end
  end
end
