defmodule SaseMango.SecuritiesUpdater do
  alias SaseMango.{SaseScraper, Securities}
  alias SaseMangoWeb.Endpoint

  require Logger

  def update() do
    {year, month, day} = DateTime.now!("Europe/Sarajevo") |> DateTime.to_date() |> Date.to_erl()
    date = "#{day}.#{month}.#{year}"

    case SaseScraper.get_list(date) do
      {:ok, issuers} ->
        Enum.each(issuers, fn issuer ->
          with {symbol, info} <- Map.pop(issuer, "Symbol"),
               attrs <- %{info: info, symbol: symbol},
               {:ok, issuer} <- create_or_update_issuer(symbol, attrs) do
            current_year = NaiveDateTime.utc_now() |> Map.fetch!(:year)

            for semi_annual <- [true, false], year <- (current_year - 9)..current_year do
              maybe_create_financial_statement(issuer, semi_annual, year)
            end
          else
            error ->
              error
              |> inspect()
              |> Logger.error()
          end
        end)

        Endpoint.broadcast("securities", "securities_update", %{})

      _ ->
        nil
    end
  end

  defp create_or_update_issuer(symbol, attrs) do
    case Securities.get_issuer(symbol) do
      %Securities.Issuer{} = issuer ->
        Securities.update_issuer(issuer, attrs)
        {:ok, issuer}

      nil ->
        Securities.create_issuer(attrs)
    end
  end

  defp maybe_create_financial_statement(%Securities.Issuer{} = issuer, semi_annual, year) do
    case Securities.get_financial_statement(issuer, semi_annual, year) do
      %Securities.FinancialStatement{} ->
        nil

      nil ->
        with {:ok, statement} <-
               SaseScraper.get_financial_statement(issuer.symbol, year, semi_annual) do
          Securities.create_financial_statement(issuer, %{
            statement: statement,
            semi_annual: semi_annual,
            year: year
          })
        else
          error ->
            error
            |> inspect()
            |> Logger.error()
        end
    end
  end
end
