defmodule SaseMango.SecuritiesUpdater do
  @moduledoc """
    Module responsible for updating issuer and financial statement tables.

  """

  require Logger

  alias SaseMango.SaseScraper
  alias SaseMango.Securities
  alias SaseMango.SecuritiesCache
  alias SaseMango.BargainsCache

  @doc """
    Updates existing or create new issuer.

    Creates financial statement for each issuer is necessary.

    Function takes a date string as argument or creates a current one in the format dd.mm.yyyy".
  """
  def update() do
    {year, month, day} = DateTime.now!("Europe/Sarajevo") |> DateTime.to_date() |> Date.to_erl()
    date = "#{day}.#{month}.#{year}"
    update(date)
  end

  def update(date) when is_binary(date) do
    case SaseScraper.get_list(date) do
      {:ok, issuers} ->
        Enum.each(issuers, fn issuer ->
          with {symbol, info} <- Map.pop(issuer, "Symbol"),
               attrs <- %{info: info, symbol: symbol},
               {:ok, issuer} <- create_or_update_issuer(symbol, attrs) do
            current_year = NaiveDateTime.utc_now() |> Map.fetch!(:year)

            for semi_annual <- [true, false], year <- (current_year - 3)..current_year do
              maybe_create_financial_statement(issuer, semi_annual, year)
            end
          else
            error ->
              error
              |> inspect()
              |> Logger.error()
          end
        end)

        SecuritiesCache.update_securities()
        BargainsCache.update_bargains()

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
