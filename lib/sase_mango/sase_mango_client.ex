defmodule SaseMango.SaseMangoClient do
  require Logger

  def child_spec do
    {Finch,
     name: __MODULE__,
     pools: %{
       default: [size: 5]
     }}
  end

  def get_list(date) do
    Logger.info("Fetching list of issuers for date #{date}")

    send_request(%{
      "id" => 1,
      "dateFrom" => date,
      "lng" => 1,
      "start" => 1,
      "type" => 23
    })
  end

  def get_financial_statement(symbol, year, semi_annual) do
    Logger.info(
      "Fetching #{year} (#{if(semi_annual, do: "semi-", else: "")}annual) financial statement for issuer #{
        symbol
      }"
    )

    send_request(%{
      "Months" => year,
      "id" => if(semi_annual, do: 1, else: 0),
      "lng" => 1,
      "start" => 1,
      "symbol" => symbol,
      "type" => 6
    })
  end

  defp send_request(params) do
    headers = [{"content-type", "application/x-www-form-urlencoded"}]

    body = URI.encode_query(params)

    :post
    |> Finch.build("http://www.sase.ba/FeedServices/HandlerChart.ashx", headers, body)
    |> Finch.request(__MODULE__)
  end
end
