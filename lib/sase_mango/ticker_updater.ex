defmodule SaseMango.TickerUpdater do
  alias SaseMango.{SaseScraper, Securities, SecuritiesCache}

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

    SecuritiesCache.update()
  end
end
