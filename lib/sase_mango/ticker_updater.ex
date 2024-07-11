defmodule SaseMango.TickerUpdater do
  @moduledoc """
  Module responsible for updating each issuer table.
  """

  alias SaseMango.BargainsCache
  alias SaseMango.SaseScraper
  alias SaseMango.Securities
  alias SaseMango.SecuritiesCache

  @doc """
  Updates all issuers in db.
  """
  def update() do
    issuers = Securities.list_issuers()

    for %Securities.Issuer{} = issuer <- issuers do
      case SaseScraper.get_ticker(issuer.symbol) do
        {:ok, %{"pr_issuer_details" => pr_issuer_details}} ->
          ["AvgPrice", "BestAskPrice", "BestAskVolume"]
          |> Enum.map(fn key ->
              pr_issuer_details
              |> Map.has_key?(key)
              |> has_key(pr_issuer_details, key, issuer.info)
              |> update_info()
              |> maybe_add_isin_to_info(pr_issuer_details)
              |> update_securities(issuer)
          end)
        _ ->
          nil
      end
    end

    SecuritiesCache.update()
    BargainsCache.update()
  end

  defp has_key(true, pr_issuer_details, key, info) do
    {
      pr_issuer_details,
      key,
      info
    }
  end

  defp has_key(_false, _pr_issuer_details, _key, info), do: info

  defp update_info({pr_issuer_details, key, info}) when key in ["AvgPrice", "BestAskPrice"] do
    value =
      pr_issuer_details
      |> Map.get(key)
      |> Decimal.new()
      |> Decimal.to_float()

    Map.put(info, key, value)
  end

  defp update_info({pr_issuer_details, key, info}) when key in ["BestAskVolume"] do
    value =
      pr_issuer_details
      |> Map.get(key)
      |> String.to_integer()

    Map.put(info, key, value)
  end

  defp update_info(info), do: info

  defp maybe_add_isin_to_info(info, pr_issuer_details) do
    if Map.has_key?(info, "ISIN") do
      info
    else
      Map.put(info, "ISIN", pr_issuer_details["ISIN"])
    end
  end

  defp update_securities(info, issuer) do
    Securities.update_issuer(issuer, %{info: info})
  end
end
