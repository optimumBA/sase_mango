defmodule SaseMango.SecuritiesUpdater do
  @moduledoc """
  Module responsible for updating issuer and financial statement tables.
  """

  require Logger

  alias SaseMango.BargainsCache
  alias SaseMango.SaseScraper
  alias SaseMango.Securities
  alias SaseMango.SecuritiesCache

  @doc """
  Updates existing or creates new issuer.
  It also creates financial statement for each issuer if necessary.
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
               {:ok, company_data} <- SaseScraper.get_company_data(symbol),
               {:ok, top_10_owners} <- SaseScraper.get_company_owners(String.slice(symbol, 0..3)),
               issuer_attrs <-
                 get_issuers_attrs(company_data, info, symbol, top_10_owners),
               {:ok, issuer} <- create_or_update_issuer(symbol, issuer_attrs) do
            current_year = Map.fetch!(NaiveDateTime.utc_now(), :year)

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

        SecuritiesCache.update()
        BargainsCache.update()

      _ ->
        nil
    end
  end

  def get_issuers_attrs(company_data, info, symbol, top_10_owners),
    do: %{
      info: info,
      symbol: symbol,
      company_data: company_data,
      top_10_owners: top_10_owners
    }

  def create_or_update_issuer(symbol, attrs) do
    case Securities.get_issuer(symbol) do
      %Securities.Issuer{} = issuer ->
        Securities.update_issuer(issuer, attrs)
        {:ok, issuer}

      nil ->
        Securities.create_issuer(attrs)
    end
  end

  def maybe_create_financial_statement(%Securities.Issuer{} = issuer, semi_annual, year) do
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
