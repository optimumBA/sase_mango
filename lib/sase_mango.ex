defmodule SaseMango do
  @moduledoc """
  SaseMango keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  alias SaseMango.SaseMangoClient

  @type date :: String.t()
  @type issuers :: list()
  @type year :: integer()

  @description_dividends "21. Objavljene dividende i drugi oblici raspodjele dobiti i pokriće gubitka"

  @relevant_segments MapSet.new([
                       "The Official market - The Official market of companies",
                       "The Official market - The Official market of funds",
                       "Free market - Subsegment 1",
                       "Free market - Subsegment 2",
                       "Free market - Subsegment 3"
                     ])

  @spec get_list(date()) :: issuers() | any()
  def get_list(date) do
    with {:ok, %Finch.Response{body: body, status: 200}} <- SaseMangoClient.get_list(date),
         {:ok, issuers} <- Jason.decode(body) do
      Enum.filter(issuers, &MapSet.member?(@relevant_segments, &1["Segment"]))
    else
      response ->
        response
    end
  end

  @spec get_financial_statements(date(), year()) :: :ok | any()
  def get_financial_statements(date, year) do
    case get_list(date) do
      issuers when is_list(issuers) ->
        issuers =
          issuers
          |> Enum.map(&get_details(&1, year))
          |> Jason.encode!()

        File.write!("issuers.json", issuers)

        :ok

      response ->
        response
    end
  end

  @spec calculate_and_export() :: :ok
  def calculate_and_export do
    issuers =
      "issuers.json"
      |> read_and_filter_issuers_file()
      |> Stream.map(&dividends_and_nomimal_prices_data/1)
      |> Enum.sort_by(& &1.dividend_roi, :desc)
      |> Enum.map(fn issuer ->
        [
          issuer.symbol,
          issuer.total_shares,
          "#{issuer.nominal_price} KM",
          "#{issuer.price} KM",
          issuer.dividend,
          "#{issuer.dividend_roi}%",
          issuer.dividends_total
        ]
      end)
      |> List.insert_at(0, [
        "Symbol",
        "Total shares",
        "Nominal price",
        "Price",
        "Dividend",
        "Dividend ROI (%)",
        "Dividends total"
      ])
      |> CSV.encode()
      |> Enum.join("")

    File.write!("issuers.csv", issuers)
  end

  defp read_and_filter_issuers_file(json_file) do
    json_file
    |> File.read!()
    |> Jason.decode!()
    |> Stream.filter(&Map.has_key?(&1, "FinancialStatement"))
  end

  defp nominal_price_and_total_shares(issuer) do
    nominal_price_string =
      issuer
      |> Map.get("FinancialStatement", %{})
      |> Map.get("GENERALINFO", %{})
      |> Map.get("NumberOfSharesNominalPrice", "")

    case Regex.named_captures(
           ~r/#{issuer["Symbol"]}<\/a> \- (?<total_shares>[\d\.]+) \- (?<nominal_price>[\d\.\,]+) KM/,
           nominal_price_string
         ) do
      nil ->
        {nil, nil}

      %{"nominal_price" => nominal_price, "total_shares" => total_shares} ->
        nominal_price =
          nominal_price
          |> String.replace(".", "")
          |> String.replace(",", ".")
          |> String.to_float()

        total_shares =
          total_shares
          |> String.replace(".", "")
          |> String.to_integer()

        {nominal_price, total_shares}
    end
  end

  defp dividends_roi_and_total(issuer, total_shares) do
    price = issuer["AvgPrice"]

    case dividends_total(issuer) do
      nil ->
        {0.0, 0.0, 0.0}

      %{"TotalCapital" => dividends_total} ->
        dividends_total =
          if(String.length(dividends_total) == 0,
            do: 0.0,
            else: String.to_float(dividends_total)
          )

        dividend = if(is_nil(total_shares), do: 0.0, else: dividends_total / total_shares)

        dividend_roi = if(price == 0.0, do: 0.0, else: Float.round(dividend / price * 100.0, 2))

        {dividend, dividend_roi, dividends_total}
    end
  end

  defp dividends_total(issuer) do
    issuer
    |> Map.get("FinancialStatement", %{})
    |> Map.get("EQUITYCHANGES", [])
    |> Enum.filter(fn row -> Map.get(row, "Description") == @description_dividends end)
    |> List.first()
  end

  defp dividends_and_nomimal_prices_data(issuer) do
    {nominal_price, total_shares} = nominal_price_and_total_shares(issuer)

    {dividend, dividend_roi, dividends_total} = dividends_roi_and_total(issuer, total_shares)

    %{
      dividend_roi: dividend_roi,
      dividend: dividend,
      dividends_total: dividends_total,
      nominal_price: nominal_price,
      price: Map.get(issuer, "AvgPrice"),
      symbol: Map.get(issuer, "Symbol"),
      total_shares: total_shares
    }
  end

  defp get_details(issuer, year) do
    with symbol when is_binary(symbol) <- Map.get(issuer, "Symbol"),
         {:ok, %Finch.Response{body: body, status: 200}} <-
           SaseMangoClient.get_financial_statement(symbol, year, false),
         {:ok, data} <- process_xml_data(body) do
      Map.put(issuer, "FinancialStatement", data)
    else
      _response ->
        issuer
    end
  end

  defp process_xml_data(body) do
    with {:ok, data} <- XmlToMap.naive_map(body),
         [key] <- Map.keys(data),
         %{^key => data} <- data do
      {:ok, data}
    else
      error ->
        error
    end
  end
end
