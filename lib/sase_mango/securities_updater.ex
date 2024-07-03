defmodule SaseMango.SecuritiesUpdater do
  @moduledoc """
  Module responsible for updating issuer and financial statement tables.
  """

  alias SaseMango.BargainsCache
  alias SaseMango.SaseScraper
  alias SaseMango.Securities
  alias SaseMango.SecuritiesCache

  require Logger

  @doc """
  Updates existing or creates new issuer.
  It also creates financial statement for each issuer if necessary.
  Function takes a date string as argument or creates a current one in the format dd.mm.yyyy".
  """
  @spec update() :: :ok | nil
  def update do
    {year, month, day} =
      "Europe/Sarajevo"
      |> DateTime.now!()
      |> DateTime.to_date()
      |> Date.to_erl()

    date = "#{day}.#{month}.#{year}"

    update(date)
  end

  defp update(date) when is_binary(date) do
    case SaseScraper.get_list(date) do
      {:ok, issuers} ->
        Enum.each(issuers, fn issuer ->
          case update_financial_statement(issuer) do
            {:error, error} ->
              error
              |> inspect()
              |> Logger.error()

            updated_list ->
              updated_list
          end
        end)

        SecuritiesCache.update()
        BargainsCache.update()

      _error ->
        nil
    end
  end

  defp update_financial_statement(issuer) do
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
        {:error, error}
    end
  end

  defp get_issuers_attrs(company_data, info, symbol, top_10_owners),
    do: %{
      info: info,
      symbol: symbol,
      company_data: company_data,
      top_10_owners: top_10_owners
    }

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
        create_financial_statement(issuer, year, semi_annual)
    end
  end

  defp create_financial_statement(issuer, year, semi_annual) do
    case SaseScraper.get_financial_statement(issuer.symbol, year, semi_annual) do
      {:ok, statement} ->
        Securities.create_financial_statement(issuer, %{
          statement: statement,
          semi_annual: semi_annual,
          year: year
        })

      error ->
        error
        |> inspect()
        |> Logger.error()
    end
  end
end
