defmodule SaseMango.SecuritiesHelper do
  @moduledoc """
  Securities list helper module.
  Implements functions for managing lists of securities.
  """

  import Ecto.Query

  alias SaseMango.Securities.FinancialStatement
  alias SaseMango.Securities.Issuer
  alias SaseMango.Repo

  @doc """
  Returns today's or the given date in the following format (dd.mm.yyyy).
  """
  def format_date do
    [year, month, day] =
      DateTime.now!("Europe/Sarajevo")
      |> DateTime.to_date()
      |> Date.to_string()
      |> String.split("-")

    "#{day}.#{month}.#{year}"
  end

  def format_date(date) do
    {:ok, date_format} = NaiveDateTime.from_iso8601(date)

    [year, month, day] =
      date_format
      |> NaiveDateTime.to_date()
      |> Date.to_string()
      |> String.split("-")

    "#{day}.#{month}.#{year}"
  end

  @doc """
  Parses the management and supervisory data string and returns a list of tuples in the form {job_title, person}.
  Returns a list of tuples or an empty list.

  ## Examples

      iex> filter_management_and_supervisory_data("Vojko Kokoravec,predsjednik,Dragan Radusinović,član,Radovan Teslić,član, Mitar Kovačević,član")
      [
        {"predsjednik", "Vojko Kokoravec"},
        {"član", "Dragan Radusinović"},
        {"član", "Radovan Teslić"},
        {"član", "Mitar Kovačević"}
      ]

      iex> filter_management_and_supervisory_data(nil)
      []

  """
  def filter_management_and_supervisory_data(data) when data in [nil, ""], do: []

  def filter_management_and_supervisory_data(data_string) when is_binary(data_string) do
    board_data_list = String.split(data_string, ~r/(\s)*(,|-)(\s)*/, trim: true)

    positions = ["predsj", "direktor", "član", "v.d."]

    if rem(Enum.count(board_data_list), 2) == 1 do
      board_data_list_with_index = Enum.with_index(board_data_list)

      board_data_list_with_index
      |> Stream.map(fn {item, i} ->
        next_el = Enum.find(board_data_list_with_index, fn {_item, ei} -> ei == i + 1 end)

        is_name? = !String.contains?(String.downcase(item), positions)

        has_position? =
          next_el &&
            String.contains?(String.downcase(elem(next_el, 0)), positions)

        cond do
          is_name? && has_position? ->
            {elem(next_el, 0), item}

          is_name? ->
            {"", item}

          true ->
            nil
        end
      end)
      |> Stream.reject(&is_nil/1)
      |> Enum.map(& &1)
    else
      board_data_list
      |> Enum.chunk_every(2)
      |> Enum.map(fn [k, v] -> {v, k} end)
    end
  end

  @doc """
  Parses the shares and nominal price data string and returns a list of tuples in the form {issuer_symbol, number_of_shares, nominal_price}.

  ## Examples

      iex> parse_shares_and_nominal_price("<a href='BSNLR'>BSNLR</a> - 8.596.256 - 10,00 KM | <a href='BSNLZ'>BSNLZ</a> - 441.431 - 10,00 KM |")
      [
        {"BSNLR", "8.596.256", "10,00 KM"},
        {"BSNLZ", "441.431", "10,00 KM"}
      ]

      iex> parse_shares_and_nominal_price(nil)
      []

  """
  def parse_shares_and_nominal_price(data) when data in [nil, ""], do: []

  def parse_shares_and_nominal_price(data_string) when is_binary(data_string) do
    data_string
    |> String.split("|", trim: true)
    |> Stream.map(
      &(String.trim(&1)
        |> String.split(~r/<\/a>/))
    )
    |> Stream.map(fn [k, v] ->
      [issuer_symbol] = Regex.split(~r{<a href=\'.*\'>}, k, trim: true)
      [shares_num, nominal_price] = Regex.split(~r{(\s*-\s*)}, v, trim: true)

      {issuer_symbol, shares_num, nominal_price}
    end)
    |> Enum.to_list()
  end

  @doc """
  Returns the list of securities.
  List is calculated depending on the type(regular or bargains list) by either regular or ask price.
  """
  def list_securities(list_type, _params \\ %{}) do
    current_financial_statement = current_financial_statement()
    previous_financial_statement = previous_financial_statement()

    from(i in Issuer, as: :issuer)
    |> join(:inner_lateral, [], fs_1 in subquery(current_financial_statement), as: :current_fs)
    |> join(:inner_lateral, [], fs_2 in subquery(previous_financial_statement), as: :previous_fs)
    |> select([issuer: i, current_fs: current_fs, previous_fs: previous_fs], %{
      issuer: i,
      current: current_fs,
      previous: previous_fs
    })
    |> maybe_filter_available_securities(list_type)
    |> Repo.all()
    |> Stream.map(fn %{} = security ->
      calc_param = get_calculate_param(security, list_type)

      symbol = security.issuer.symbol

      balance_sheet = get_balance_sheet(security.current)
      {book_value, previous_book_value} = get_book_values(balance_sheet)

      equity_changes = get_equity_changes(security.current)
      previous_equity_changes = get_equity_changes(security.previous)

      profit_and_loss_account = get_profit_and_loss_account(security.current)
      {income, previous_income} = get_incomes(profit_and_loss_account)
      {profit, previous_profit} = get_profits(profit_and_loss_account)

      total_dividends = get_total_dividends(equity_changes)
      previous_total_dividends = get_total_dividends(previous_equity_changes)

      {nominal_price, total_shares} = get_nominal_price_and_total_shares(security.current, symbol)

      {_nominal_price, previous_total_shares} =
        get_nominal_price_and_total_shares(security.previous, symbol)

      bvs =
        if(Decimal.equal?(total_shares, 0),
          do: Decimal.new(0),
          else: Decimal.div(book_value, total_shares)
        )

      previous_bvs =
        if(Decimal.equal?(previous_total_shares, 0),
          do: Decimal.new(0),
          else: Decimal.div(previous_book_value, previous_total_shares)
        )

      dividend =
        if(Decimal.equal?(total_shares, 0),
          do: Decimal.new(0),
          else: Decimal.div(total_dividends, total_shares)
        )

      previous_dividend =
        if(Decimal.equal?(previous_total_shares, 0),
          do: Decimal.new(0),
          else: Decimal.div(previous_total_dividends, previous_total_shares)
        )

      price = convert_price_to_decimal(security.issuer.info["AvgPrice"])
      ask_price = convert_price_to_decimal(security.issuer.info["BestAskPrice"])
      bid_price = convert_price_to_decimal(security.issuer.info["BestBidPrice"])

      last_trade_date = convert_date_format(security.issuer.info["LastTradeDate"])

      eps =
        if(Decimal.equal?(total_shares, 0),
          do: Decimal.new(0),
          else: Decimal.div(profit, total_shares)
        )

      previous_eps =
        if(Decimal.equal?(previous_total_shares, 0),
          do:
            if(Decimal.equal?(total_shares, 0),
              do: Decimal.new(0),
              else: Decimal.div(previous_profit, total_shares)
            ),
          else: Decimal.div(previous_profit, previous_total_shares)
        )

      market_value =
        if(Decimal.equal?(total_shares, 0),
          do: Decimal.new(0),
          else: Decimal.mult(calc_param, total_shares)
        )

      profit_margin =
        if(Decimal.equal?(income, 0),
          do: Decimal.new(0),
          else: Decimal.div(profit, income)
        )

      previous_profit_margin =
        if(Decimal.equal?(previous_income, 0),
          do: Decimal.new(0),
          else: Decimal.div(previous_profit, previous_income)
        )

      %{
        ask_price: ask_price,
        ask_volume: security.issuer.info["BestAskVolume"],
        bid_price: bid_price,
        bid_volume: security.issuer.info["BestBidVolume"],
        book_value: book_value,
        bvs: bvs,
        dividend: dividend,
        dividend_roi:
          if(Decimal.equal?(calc_param, 0),
            do: Decimal.new(0),
            else: Decimal.div(dividend, calc_param)
          ),
        eps: eps,
        eps_roi:
          if(Decimal.equal?(calc_param, 0), do: Decimal.new(0), else: Decimal.div(eps, calc_param)),
        last_trade_date: last_trade_date,
        market_value: market_value,
        name: security.issuer.info["SymbolDescription"],
        nominal_price: nominal_price,
        pb:
          if(Decimal.equal?(book_value, 0),
            do: Decimal.new(0),
            else: Decimal.div(market_value, book_value)
          ),
        pe:
          if(Decimal.equal?(total_shares, 0) || Decimal.equal?(profit, 0),
            do: Decimal.new(0),
            else: Decimal.div(calc_param, Decimal.div(profit, total_shares))
          ),
        previous_book_value: previous_book_value,
        previous_bvs: previous_bvs,
        previous_dividend: previous_dividend,
        previous_dividend_roi:
          if(
            Decimal.equal?(calc_param, 0),
            do: Decimal.new(0),
            else: Decimal.div(previous_dividend, calc_param)
          ),
        previous_eps: previous_eps,
        previous_eps_roi:
          if(Decimal.equal?(calc_param, 0),
            do: Decimal.new(0),
            else: Decimal.div(previous_eps, calc_param)
          ),
        previous_profit: previous_profit,
        previous_profit_margin: previous_profit_margin,
        price: price,
        profit: profit,
        profit_margin: profit_margin,
        segment: security.issuer.info["Segment"],
        symbol: symbol
      }
    end)
    |> maybe_additional_filter(list_type)
  end

  defp financial_statements do
    current_year = NaiveDateTime.utc_now().year

    from fs in FinancialStatement,
      select: %{id: fs.id, issuer_id: fs.issuer_id, rank: over(dense_rank(), :issuer)},
      windows: [issuer: [partition_by: fs.issuer_id, order_by: [desc: :year]]],
      where: fs.semi_annual == false,
      where: fs.year >= ^current_year - 3
  end

  defp current_financial_statement do
    from fs in FinancialStatement,
      join: fs_ids in subquery(financial_statements()),
      on: fs_ids.id == fs.id,
      where: fs_ids.issuer_id == parent_as(:issuer).id,
      where: fs_ids.rank == 1
  end

  defp previous_financial_statement do
    from fs in FinancialStatement,
      join: fs_ids in subquery(financial_statements()),
      on: fs_ids.id == fs.id,
      where: fs_ids.issuer_id == parent_as(:issuer).id,
      where: fs_ids.rank == 2
  end

  defp maybe_filter_available_securities(query, :securities), do: query

  defp maybe_filter_available_securities(query, :bargains) do
    query
    |> where([issuer: i], fragment("(?->'BestAskPrice')::NUMERIC > 0", i.info))
    |> where([issuer: i], fragment("(?->'BestAskVolume')::NUMERIC > 0", i.info))
  end

  defp get_calculate_param(security, :securities),
    do: convert_price_to_decimal(security.issuer.info["AvgPrice"])

  defp get_calculate_param(security, :bargains),
    do: convert_price_to_decimal(security.issuer.info["BestAskPrice"])

  defp maybe_additional_filter(securities, :securities), do: securities

  defp maybe_additional_filter(securities, :bargains) do
    Stream.filter(securities, fn security ->
      Decimal.gt?(security.profit, Decimal.new(0)) &&
        Decimal.gt?(security.previous_profit, Decimal.new(0)) &&
        Decimal.lt?(security.ask_price, Decimal.mult(security.bvs, Decimal.div(2, 3))) &&
        Decimal.lt?(security.pb, Decimal.new(20)) &&
        Decimal.lt?(security.pe, Decimal.new(20)) &&
        Decimal.gt?(security.eps_roi, Decimal.from_float(0.05))
    end)
  end

  defp get_balance_sheet(financial_statement) do
    with %FinancialStatement{} = financial_statement <- financial_statement,
         %{} = statement <- Map.get(financial_statement, :statement),
         balance_sheet when is_list(balance_sheet) <- Map.get(statement, "BALANCESHEET") do
      balance_sheet
    else
      _ ->
        %{}
    end
  end

  defp get_equity_changes(financial_statement) do
    with %FinancialStatement{} = financial_statement <- financial_statement,
         %{} = statement <- Map.get(financial_statement, :statement),
         equity_changes when is_list(equity_changes) <- Map.get(statement, "EQUITYCHANGES") do
      equity_changes
    else
      _ ->
        %{}
    end
  end

  defp get_profit_and_loss_account(financial_statement) do
    with %FinancialStatement{} = financial_statement <- financial_statement,
         %{} = statement <- Map.get(financial_statement, :statement),
         profit_and_loss_account when is_list(profit_and_loss_account) <-
           Map.get(statement, "PROFITANDLOSSACCOUNT") do
      profit_and_loss_account
    else
      _ ->
        %{}
    end
  end

  defp get_book_values(balance_sheet) do
    with %{} = row <-
           Enum.find(balance_sheet, fn row ->
             row["Description"] ==
               "A) STALNA SREDSTVA I DUGOROČNI PLASMANI (002+008+014+015+020+021+030+033)"
           end),
         book_value when is_binary(book_value) <- Map.get(row, "Neto"),
         book_value <- Decimal.new(book_value),
         previous_book_value when is_binary(previous_book_value) <-
           Map.get(row, "PreviousYear"),
         previous_book_value <- Decimal.new(previous_book_value) do
      {book_value, previous_book_value}
    else
      _ ->
        {Decimal.new(0), Decimal.new(0)}
    end
  end

  defp get_total_dividends(equity_changes) do
    with %{} = row <-
           Enum.find(equity_changes, fn row ->
             row["Description"] ==
               "21. Objavljene dividende i drugi oblici raspodjele dobiti i pokriće gubitka"
           end),
         total_capital when is_binary(total_capital) <- Map.get(row, "TotalCapital"),
         total_dividends <- Decimal.new(total_capital) do
      total_dividends
    else
      _ ->
        Decimal.new(0)
    end
  end

  defp get_incomes(profit_and_loss_account) do
    with %{} = row <-
           Enum.find(profit_and_loss_account, fn row ->
             row["Description"] == "Poslovni prihodi (202+206+210+211)"
           end),
         income when is_binary(income) <- Map.get(row, "OngoingYear"),
         income <- Decimal.new(income),
         previous_income when is_binary(previous_income) <-
           Map.get(row, "PreviousYear"),
         previous_income <- Decimal.new(previous_income) do
      {income, previous_income}
    else
      _ ->
        {Decimal.new(0), Decimal.new(0)}
    end
  end

  defp get_profits(profit_and_loss_account) do
    with %{} = row <-
           Enum.find(profit_and_loss_account, fn row ->
             row["Description"] ==
               "Ukupna neto sveobuhv. dobit/gubitak prema vlasništvu (332 ili 333)"
           end),
         profit when is_binary(profit) <- Map.get(row, "OngoingYear"),
         profit <- Decimal.new(profit),
         previous_profit when is_binary(previous_profit) <-
           Map.get(row, "PreviousYear"),
         previous_profit <- Decimal.new(previous_profit) do
      {profit, previous_profit}
    else
      _ ->
        {Decimal.new(0), Decimal.new(0)}
    end
  end

  defp get_nominal_price_and_total_shares(financial_statement, symbol) do
    with %FinancialStatement{} = financial_statement <- financial_statement,
         %{} = statement <- Map.get(financial_statement, :statement),
         %{} = general_info <- Map.get(statement, "GENERALINFO"),
         string when is_binary(string) <-
           Map.get(general_info, "NumberOfSharesNominalPrice"),
         %{"nominal_price" => nominal_price, "total_shares" => total_shares} <-
           Regex.named_captures(
             ~r/#{symbol}<\/a> \- (?<total_shares>[\d\.]+) \- (?<nominal_price>[\d\.\,]+) KM/,
             string
           ) do
      nominal_price =
        nominal_price
        |> String.replace(",", ".")
        |> Decimal.new()

      total_shares =
        total_shares
        |> String.replace(".", "")
        |> Decimal.new()

      {nominal_price, total_shares}
    else
      _ ->
        {Decimal.new(0), Decimal.new(0)}
    end
  end

  defp convert_price_to_decimal(price) when is_float(price), do: Decimal.from_float(price)
  defp convert_price_to_decimal(price), do: Decimal.new(price)

  defp convert_date_format(value) do
    {:ok, datetime} =
      Regex.run(~r/[0-9]{1,}/, value)
      |> List.first()
      |> String.slice(0..-4)
      |> String.to_integer()
      |> DateTime.from_unix()

    datetime
  end
end
