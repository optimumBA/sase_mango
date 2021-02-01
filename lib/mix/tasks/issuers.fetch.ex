defmodule Mix.Tasks.Issuers.Fetch do
  use Mix.Task

  require Logger

  alias SaseMango.{Issuers, SaseScraper}
  alias SaseMango.Issuers.{FinancialStatement, Issuer}

  @requirements ["app.start"]

  @impl Mix.Task
  def run([date]) do
    {:ok, issuers} = SaseScraper.get_list(date)

    Enum.each(issuers, fn issuer ->
      with {symbol, info} <- Map.pop(issuer, "Symbol"),
           attrs <- %{info: info, symbol: symbol},
           {:ok, issuer} <- create_or_update_issuer(symbol, attrs) do
        for semi_annual <- [true, false], year <- 2015..2020 do
          maybe_create_financial_statement(issuer, semi_annual, year)
        end
      else
        error ->
          error
          |> inspect()
          |> Logger.error()
      end
    end)
  end

  defp create_or_update_issuer(symbol, attrs) do
    case Issuers.get_issuer(symbol) do
      %Issuer{} = issuer ->
        Issuers.update_issuer(issuer, attrs)
        {:ok, issuer}

      nil ->
        Issuers.create_issuer(attrs)
    end
  end

  defp maybe_create_financial_statement(%Issuer{} = issuer, semi_annual, year) do
    case Issuers.get_financial_statement(issuer, semi_annual, year) do
      %FinancialStatement{} ->
        nil

      nil ->
        with {:ok, statement} <-
               SaseScraper.get_financial_statement(issuer.symbol, year, semi_annual) do
          Issuers.create_financial_statement(issuer, %{
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
