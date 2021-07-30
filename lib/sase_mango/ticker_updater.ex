defmodule SaseMango.TickerUpdater do
  alias SaseMango.{SaseScraper, Securities, SecuritiesCache}

  def update() do
    issuers = Securities.list_issuers()

    for %Securities.Issuer{} = issuer <- issuers do
      case SaseScraper.get_ticker(issuer.symbol) do
        {:ok, %{"pr_issuer_details" => %{"OfficialBestAskPrice" => ask_price}}} ->
          ask_price = String.to_float(ask_price)
          info = issuer.info |> Map.put("BestAskPrice", ask_price)
          Securities.update_issuer(issuer, %{info: info})

        _ ->
          nil
      end
    end

    SecuritiesCache.update()
  end
end
