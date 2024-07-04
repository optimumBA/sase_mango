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
  @spec update() :: :ok
  def update do
    issuers = Securities.list_issuers()

    for %Securities.Issuer{} = issuer <- issuers do
      case SaseScraper.get_ticker(issuer.symbol) do
        {:ok, %{"pr_issuer_details" => pr_issuer_details}} ->
          info =
            issuer
            |> get_info(pr_issuer_details)
            |> maybe_add_best_ask_volume_to_info(pr_issuer_details)
            |> maybe_add_isin_to_info(pr_issuer_details)

          Securities.update_issuer(issuer, %{info: info})

        _error ->
          nil
      end
    end

    SecuritiesCache.update()
    BargainsCache.update()
  end

  defp get_info(issuer, pr_issuer_details) do
    Enum.reduce(["AvgPrice", "BestAskPrice"], issuer.info, fn key, info ->
      if Map.has_key?(pr_issuer_details, key) do
        value =
          pr_issuer_details
          |> Map.get(key)
          |> Decimal.new()
          |> Decimal.to_float()

        Map.put(info, key, value)
      else
        info
      end
    end)
  end

  defp maybe_add_best_ask_volume_to_info(info, pr_issuer_details) do
    if Map.has_key?(pr_issuer_details, "BestAskVolume") do
      value =
        pr_issuer_details
        |> Map.get("BestAskVolume")
        |> String.to_integer()

      Map.put(info, "BestAskVolume", value)
    else
      info
    end
  end

  defp maybe_add_isin_to_info(info, pr_issuer_details) do
    if Map.has_key?(info, "ISIN") do
      info
    else
      Map.put(info, "ISIN", pr_issuer_details["ISIN"])
    end
  end
end
