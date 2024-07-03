defmodule SaseMango.SaseMangoClient do
  @moduledoc false

  require Logger

  @type date :: String.t()
  @type finch_response :: {:ok, Finch.Response.t()} | {:error, any()}
  @type semi_annual :: boolean()
  @type symbol :: String.t()
  @type year :: integer()

  @spec child_spec() :: {Finch, [{:name, SaseMango.SaseMangoClient} | {:pools, map()}, ...]}
  def child_spec do
    {Finch,
     name: __MODULE__,
     pools: %{
       default: [size: 5]
     }}
  end

  @spec get_list(date()) :: finch_response()
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

  @spec get_financial_statement(symbol(), year(), semi_annual()) :: finch_response()
  def get_financial_statement(symbol, year, semi_annual) do
    Logger.info(
      "Fetching #{year} (#{if(semi_annual, do: "semi-", else: "")}annual) financial statement for issuer #{symbol}"
    )

    common_request_params()
    |> Map.merge(%{
      "Months" => year,
      "id" => if(semi_annual, do: 1, else: 0),
      "start" => 1,
      "symbol" => symbol,
      "type" => 6
    })
    |> send_request()
  end

  @spec get_ticker(symbol()) :: finch_response()
  def get_ticker(symbol) do
    Logger.info("Fetching ticker for issuer #{symbol}")

    common_request_params()
    |> Map.merge(%{"symbol" => symbol, "type" => 4, "Months" => 1})
    |> send_request()
  end

  @spec get_general_data(symbol()) :: finch_response()
  def get_general_data(symbol) do
    Logger.info("Fetching company information data for issuer #{symbol}")

    common_request_params()
    |> Map.merge(%{"symbol" => symbol, "type" => 6})
    |> send_request()
  end

  @spec get_top_10_owners(symbol()) :: finch_response()
  def get_top_10_owners(symbol) do
    common_request_params()
    |> Map.merge(%{"symbol" => symbol, "type" => 18, "Months" => 0})
    |> send_request()
  end

  defp common_request_params do
    %{
      "id" => 0,
      "lng" => 1,
      "Months" => 1
    }
  end

  defp send_request(params) do
    headers = [{"content-type", "application/x-www-form-urlencoded"}]

    body = URI.encode_query(params)

    :post
    |> Finch.build("http://www.sase.ba/FeedServices/HandlerChart.ashx", headers, body)
    |> Finch.request(__MODULE__)
  end
end
