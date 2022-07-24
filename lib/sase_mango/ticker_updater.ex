defmodule SaseMango.TickerUpdater do
  @moduledoc """
    Module responsible for updating each issuer table.
  """

  alias SaseMango.SaseScraper
  alias SaseMango.Securities
  alias SaseMangoWeb.Endpoint

  @doc """
    Updates each issuer in db.

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

                info
                |> Map.put(key, value)
                |> Map.put("LastTradeDate", pr_issuer_details["LastTradeDate"])
                |> Map.put("TradingDay", pr_issuer_details["TradingDay"])
              else
                info
                |> Map.put("LastTradeDate", pr_issuer_details["LastTradeDate"])
                |> Map.put("TradingDay", pr_issuer_details["TradingDay"])
              end
            end)

          info =
            if Map.has_key?(pr_issuer_details, "BestAskVolume") do
              value =
                pr_issuer_details
                |> Map.get("BestAskVolume")
                |> String.to_integer()

              Map.put(info, "BestAskVolume", value)
            else
              info
            end

          Securities.update_issuer(issuer, %{info: info})

        _ ->
          nil
      end
    end

    Endpoint.broadcast("securities", "securities_update", %{})
  end
end
