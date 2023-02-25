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
          info =
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

          maybe_add_best_ask_volume_to_info =
            if Map.has_key?(pr_issuer_details, "BestAskVolume") do
              value =
                pr_issuer_details
                |> Map.get("BestAskVolume")
                |> String.to_integer()

              Map.put(info, "BestAskVolume", value)
            else
              info
            end

          maybe_add_isin_to_info =
            if Map.has_key?(maybe_add_best_ask_volume_to_info, "ISIN") do
              maybe_add_best_ask_volume_to_info
            else
              Map.put(maybe_add_best_ask_volume_to_info, "ISIN", pr_issuer_details["ISIN"])
            end

          Securities.update_issuer(issuer, %{info: maybe_add_isin_to_info})

        _ ->
          nil
      end
    end

    SecuritiesCache.update()
    BargainsCache.update()
  end
end
