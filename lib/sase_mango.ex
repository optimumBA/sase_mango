defmodule SaseMango do
  @moduledoc """
  SaseMango keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  alias SaseMango.SaseMangoClient

  @description_dividends "21. Objavljene dividende i drugi oblici raspodjele dobiti i pokriće gubitka"

  @relevant_segments MapSet.new([
                       "The Official market - The Official market of companies",
                       "The Official market - The Official market of funds",
                       "Free market - Subsegment 1",
                       "Free market - Subsegment 2",
                       "Free market - Subsegment 3"
                     ])

  def get_list(date) do
    with {:ok, %Finch.Response{body: body, status: 200}} <- SaseMangoClient.get_list(date),
         {:ok, issuers} <- Jason.decode(body) do
      issuers
      |> Enum.filter(fn issuer ->
        @relevant_segments |> MapSet.member?(Map.get(issuer, "Segment"))
      end)
    else
      response ->
        response
    end
  end

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

  def calculate_and_export() do
    issuers =
      "issuers.json"
      |> File.read!()
      |> Jason.decode!()
      |> Stream.filter(&Map.has_key?(&1, "FinancialStatement"))
      |> Stream.map(fn issuer ->
        symbol = Map.get(issuer, "Symbol")
        price = Map.get(issuer, "AvgPrice")

        financial_statement = Map.get(issuer, "FinancialStatement", %{})

        nominal_price_string =
          financial_statement
          |> Map.get("GENERALINFO", %{})
          |> Map.get("NumberOfSharesNominalPrice")

        nominal_price_string = if(nominal_price_string, do: nominal_price_string, else: "")

        {nominal_price, total_shares} =
          case Regex.named_captures(
                 ~r/#{symbol}<\/a> \- (?<total_shares>[\d\.]+) \- (?<nominal_price>[\d\.\,]+) KM/,
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

        dividends_total =
          financial_statement
          |> Map.get("EQUITYCHANGES", [])
          |> Enum.filter(fn row -> Map.get(row, "Description") == @description_dividends end)
          |> List.first()

        {dividend, dividend_roi, dividends_total} =
          case dividends_total do
            nil ->
              {0.0, 0.0, 0.0}

            %{"TotalCapital" => dividends_total} ->
              dividends_total =
                if(String.length(dividends_total) == 0,
                  do: 0.0,
                  else: String.to_float(dividends_total)
                )

              dividend = if(is_nil(total_shares), do: 0.0, else: dividends_total / total_shares)

              dividend_roi =
                if(price == 0.0, do: 0.0, else: Float.round(dividend / price * 100.0, 2))

              {dividend, dividend_roi, dividends_total}
          end

        %{
          symbol: symbol,
          total_shares: total_shares,
          nominal_price: nominal_price,
          price: price,
          dividend: dividend,
          dividend_roi: dividend_roi,
          dividends_total: dividends_total
        }
      end)
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

  defp get_details(issuer, year) do
    with symbol when is_binary(symbol) <- Map.get(issuer, "Symbol"),
         {:ok, %Finch.Response{body: body, status: 200}} <-
           SaseMangoClient.get_financial_statement(symbol, year, false),
         data when is_map(data) <- XmlToMap.naive_map(body),
         [key] <- Map.keys(data),
         %{^key => data} <- data do
      Map.put(issuer, "FinancialStatement", data)
    else
      _response ->
        issuer
    end
  end
end
