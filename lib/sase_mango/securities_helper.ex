defmodule SaseMango.SecuritiesHelper do
  @moduledoc """
  Securities list helper module.
  Implements functions for managing lists of securities.
  """

  import Ecto.Query

  alias SaseMango.Repo
  alias SaseMango.Securities.FinancialStatement
  alias SaseMango.Securities.Issuer

  @type date :: String.t()
  @type management_data :: [tuple()]
  @type price_data :: [tuple()]

  @doc """
  Returns today's or the given date in the following format (dd.mm.yyyy).
  """
  @spec format_date() :: date()
  def format_date do
    [year, month, day] =
      "Europe/Sarajevo"
      |> DateTime.now!()
      |> DateTime.to_date()
      |> Date.to_string()
      |> String.split("-")

    "#{day}.#{month}.#{year}"
  end

  @spec format_date(date()) :: date()
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

      iex> filter_management_and_supervisory_data(
      ...>   "Vojko Kokoravec,predsjednik,Dragan Radusinović,član,Radovan Teslić,član, Mitar Kovačević,član"
      ...> )
      [
        {"predsjednik", "Vojko Kokoravec"},
        {"član", "Dragan Radusinović"},
        {"član", "Radovan Teslić"},
        {"član", "Mitar Kovačević"}
      ]

      iex> filter_management_and_supervisory_data(nil)
      []

  """
  @spec filter_management_and_supervisory_data(String.t()) :: any()
  def filter_management_and_supervisory_data(data) when data in [nil, ""], do: []

  def filter_management_and_supervisory_data(data_string) when is_binary(data_string) do
    board_data_list = String.split(data_string, ~r/(\s)*(,|-)(\s)*/, trim: true)

    positions = ["predsj", "direktor", "član", "v.d."]

    rem_list =
      board_data_list
      |> Enum.count()
      |> rem(2)

    if rem_list == 1 do
      board_data_list_with_index = Enum.with_index(board_data_list)

      board_data_list_with_index
      |> process_board_data_list(positions)
      |> Stream.reject(&is_nil/1)
      |> Enum.map(& &1)
    else
      board_data_list
      |> Enum.chunk_every(2)
      |> Enum.map(fn [k, v] -> {v, k} end)
    end
  end

  defp process_board_data_list(board_data_list_with_index, positions) do
    Stream.map(board_data_list_with_index, fn {item, i} ->
      next_el = Enum.find(board_data_list_with_index, fn {_item, ei} -> ei == i + 1 end)

      is_name? =
        item
        |> String.downcase()
        |> String.contains?(positions)
        |> Kernel.!()

      has_position? =
        unless is_nil(next_el) do
          next_el
          |> elem(0)
          |> String.downcase()
          |> String.contains?(positions)
        end

      cond do
        is_name? && has_position? ->
          {elem(next_el, 0), item}

        is_name? ->
          {"", item}

        true ->
          nil
      end
    end)
  end

  @doc """
  Parses the shares and nominal price data string and returns a list of tuples in the form {issuer_symbol, number_of_shares, nominal_price}.

  ## Examples

      iex> parse_shares_and_nominal_price(
      ...>   "<a href='BSNLR'>BSNLR</a> - 8.596.256 - 10,00 KM | <a href='BSNLZ'>BSNLZ</a> - 441.431 - 10,00 KM |"
      ...> )
      [
        {"BSNLR", "8.596.256", "10,00 KM"},
        {"BSNLZ", "441.431", "10,00 KM"}
      ]

      iex> parse_shares_and_nominal_price(nil)
      []

  """
  @spec parse_shares_and_nominal_price(String.t()) :: price_data()
  def parse_shares_and_nominal_price(data) when data in [nil, ""], do: []

  def parse_shares_and_nominal_price(data_string) when is_binary(data_string) do
    data_string
    |> String.split("|", trim: true)
    |> Stream.map(
      &(&1
        |> String.trim()
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
  @spec list_securities(atom(), map()) :: Enumerable.t()
  def list_securities(list_type, _params \\ %{}) do
    list_type
    |> fetch_financial_statements()
    |> Stream.map(fn %{} = security ->
      build_securities_map(security, list_type)
    end)
    |> maybe_additional_filter(list_type)
  end

  defp build_securities_map(security, list_type) do
    calc_param = get_calculate_param(security, list_type)
    nominal_price = total_shares_and_nominal_price(security).nominal_price

    %{}
    |> Map.put(:nominal_price, nominal_price)
    |> security_issuer_info(security)
    |> book_values_and_bvs(security)
    |> dividend_and_roi(security, calc_param)
    |> previous_dividend_and_roi(security, calc_param)
    |> profits_and_margins(security)
    |> eps_and_roi(security, calc_param)
    |> previous_eps_and_roi(security, calc_param)
    |> market_value(security, calc_param)
    |> pb(security, calc_param)
    |> pe(security, calc_param)
  end

  defp security_issuer_info(acc, security) do
    data = %{
      ask_price: convert_price_to_decimal(security.issuer.info["BestAskPrice"]),
      ask_volume: security.issuer.info["BestAskVolume"],
      bid_price: convert_price_to_decimal(security.issuer.info["BestBidPrice"]),
      bid_volume: security.issuer.info["BestBidVolume"],
      last_trade_date: convert_date_format(security.issuer.info["LastTradeDate"]),
      name: security.issuer.info["SymbolDescription"],
      price: convert_price_to_decimal(security.issuer.info["AvgPrice"]),
      segment: security.issuer.info["Segment"],
      symbol: security.issuer.symbol
    }

    Map.merge(acc, data)
  end

  defp book_values_and_bvs(acc, security) do
    {book_value, previous_book_value} =
      security.current
      |> get_balance_sheet()
      |> get_book_values()

    %{
      previous_total_shares: previous_total_shares,
      total_shares: total_shares
    } = total_shares_and_nominal_price(security)

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

    Map.merge(acc, %{
      book_value: book_value,
      bvs: bvs,
      previous_book_value: previous_book_value,
      previous_bvs: previous_bvs
    })
  end

  defp dividend_and_roi(acc, security, calc_param) do
    total_dividends =
      security.current
      |> get_equity_changes()
      |> get_total_dividends()

    total_shares = total_shares_and_nominal_price(security).total_shares

    dividend =
      if(Decimal.equal?(total_shares, 0),
        do: Decimal.new(0),
        else: Decimal.div(total_dividends, total_shares)
      )

    dividend_roi =
      if(Decimal.equal?(calc_param, 0),
        do: Decimal.new(0),
        else: Decimal.div(dividend, calc_param)
      )

    Map.merge(acc, %{dividend: dividend, dividend_roi: dividend_roi})
  end

  defp previous_dividend_and_roi(acc, security, calc_param) do
    previous_total_dividends =
      security.previous
      |> get_equity_changes()
      |> get_total_dividends()

    previous_total_shares = total_shares_and_nominal_price(security).previous_total_shares

    previous_dividend =
      if(Decimal.equal?(previous_total_shares, 0),
        do: Decimal.new(0),
        else: Decimal.div(previous_total_dividends, previous_total_shares)
      )

    previous_dividend_roi =
      if(Decimal.equal?(calc_param, 0),
        do: Decimal.new(0),
        else: Decimal.div(previous_dividend, calc_param)
      )

    Map.merge(acc, %{
      previous_dividend: previous_dividend,
      previous_dividend_roi: previous_dividend_roi
    })
  end

  defp profits_and_margins(acc, security) do
    {income, previous_income} = incomes(security)
    {profit, previous_profit} = profits(security)

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

    Map.merge(acc, %{
      previous_profit_margin: previous_profit_margin,
      previous_profit: previous_profit,
      profit_margin: profit_margin,
      profit: profit
    })
  end

  defp eps_and_roi(acc, security, calc_param) do
    total_shares = total_shares_and_nominal_price(security).total_shares
    profit = profits_and_margins(%{}, security).profit

    eps =
      if(Decimal.equal?(total_shares, 0),
        do: Decimal.new(0),
        else: Decimal.div(profit, total_shares)
      )

    eps_roi =
      if(Decimal.equal?(calc_param, 0),
        do: Decimal.new(0),
        else: Decimal.div(eps, calc_param)
      )

    Map.merge(acc, %{eps: eps, eps_roi: eps_roi})
  end

  defp previous_eps_and_roi(acc, security, calc_param) do
    previous_profit = profits_and_margins(acc, security).previous_profit_margin

    %{
      previous_total_shares: previous_total_shares,
      total_shares: total_shares
    } = total_shares_and_nominal_price(security)

    previous_eps =
      if(Decimal.equal?(previous_total_shares, 0),
        do:
          if(Decimal.equal?(total_shares, 0),
            do: Decimal.new(0),
            else: Decimal.div(previous_profit, total_shares)
          ),
        else: Decimal.div(previous_profit, previous_total_shares)
      )

    previous_eps_roi =
      if(Decimal.equal?(calc_param, 0),
        do: Decimal.new(0),
        else: Decimal.div(previous_eps, calc_param)
      )

    Map.merge(acc, %{
      previous_eps_roi: previous_eps_roi,
      previous_eps: previous_eps
    })
  end

  defp market_value(acc, security, calc_param) do
    total_shares = total_shares_and_nominal_price(security).total_shares

    market_value =
      if(Decimal.equal?(total_shares, 0),
        do: Decimal.new(0),
        else: Decimal.mult(calc_param, total_shares)
      )

    Map.merge(acc, %{market_value: market_value})
  end

  defp pb(acc, security, calc_param) do
    book_value = book_values_and_bvs(acc, security).book_value
    market_value = market_value(acc, security, calc_param).market_value

    pb =
      if(Decimal.equal?(book_value, 0),
        do: Decimal.new(0),
        else: Decimal.div(market_value, book_value)
      )

    Map.merge(acc, %{pb: pb})
  end

  defp pe(acc, security, calc_param) do
    total_shares = total_shares_and_nominal_price(security).total_shares
    profit = profits_and_margins(acc, security).profit

    pe =
      if(Decimal.equal?(total_shares, 0) || Decimal.equal?(profit, 0),
        do: Decimal.new(0),
        else: Decimal.div(calc_param, Decimal.div(profit, total_shares))
      )

    Map.merge(acc, %{pe: pe})
  end

  defp total_shares_and_nominal_price(security) do
    {nominal_price, total_shares} =
      get_nominal_price_and_total_shares(security.current, security.issuer.symbol)

    {_nominal_price, previous_total_shares} =
      get_nominal_price_and_total_shares(security.previous, security.issuer.symbol)

    %{
      nominal_price: nominal_price,
      previous_total_shares: previous_total_shares,
      total_shares: total_shares
    }
  end

  defp incomes(security) do
    security.current
    |> get_profit_and_loss_account()
    |> get_incomes()
  end

  defp profits(security) do
    security.current
    |> get_profit_and_loss_account()
    |> get_profits()
  end

  defp fetch_financial_statements(list_type) do
    current_financial_statement = current_financial_statement()
    previous_financial_statement = previous_financial_statement()

    query = from(i in Issuer, as: :issuer)

    query
    |> join(:inner_lateral, [], fs_1 in subquery(current_financial_statement), as: :current_fs)
    |> join(:inner_lateral, [], fs_2 in subquery(previous_financial_statement), as: :previous_fs)
    |> select([issuer: i, current_fs: current_fs, previous_fs: previous_fs], %{
      issuer: i,
      current: current_fs,
      previous: previous_fs
    })
    |> maybe_filter_available_securities(list_type)
    |> Repo.all()
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
      _other ->
        %{}
    end
  end

  defp get_equity_changes(financial_statement) do
    with %FinancialStatement{} = financial_statement <- financial_statement,
         %{} = statement <- Map.get(financial_statement, :statement),
         equity_changes when is_list(equity_changes) <- Map.get(statement, "EQUITYCHANGES") do
      equity_changes
    else
      _other ->
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
      _other ->
        %{}
    end
  end

  defp get_book_values(balance_sheet) do
    with %{} = row <-
           Enum.find(balance_sheet, fn row ->
             row["Description"] ==
               "A) STALNA SREDSTVA I DUGOROČNI PLASMANI (002+008+014+015+020+021+030+033)"
           end),
         {:ok, book_value} <- fetch_row_value(row, "Neto"),
         {:ok, previous_book_value} <- fetch_row_value(row, "PreviousYear") do
      {book_value, previous_book_value}
    else
      _other ->
        {Decimal.new(0), Decimal.new(0)}
    end
  end

  defp get_total_dividends(equity_changes) do
    with %{} = row <-
           Enum.find(equity_changes, fn row ->
             row["Description"] ==
               "21. Objavljene dividende i drugi oblici raspodjele dobiti i pokriće gubitka"
           end),
         {:ok, total_dividends} <- fetch_row_value(row, "TotalCapital") do
      total_dividends
    else
      _other ->
        Decimal.new(0)
    end
  end

  defp get_incomes(profit_and_loss_account) do
    with %{} = row <-
           Enum.find(profit_and_loss_account, fn row ->
             row["Description"] == "Poslovni prihodi (202+206+210+211)"
           end),
         {:ok, income} <- fetch_row_value(row, "OngoingYear"),
         {:ok, previous_income} <- fetch_row_value(row, "PreviousYear") do
      {income, previous_income}
    else
      _other ->
        {Decimal.new(0), Decimal.new(0)}
    end
  end

  defp get_profits(profit_and_loss_account) do
    with %{} = row <-
           Enum.find(profit_and_loss_account, fn row ->
             row["Description"] ==
               "Ukupna neto sveobuhv. dobit/gubitak prema vlasništvu (332 ili 333)"
           end),
         {:ok, profit} <- fetch_row_value(row, "OngoingYear"),
         {:ok, previous_profit} <- fetch_row_value(row, "PreviousYear") do
      {profit, previous_profit}
    else
      _other ->
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
      _other ->
        {Decimal.new(0), Decimal.new(0)}
    end
  end

  defp fetch_row_value(row, key) do
    case Map.get(row, key) do
      nil -> {:error, nil}
      value when is_binary(value) -> {:ok, Decimal.new(value)}
    end
  end

  defp convert_price_to_decimal(price) when is_float(price), do: Decimal.from_float(price)
  defp convert_price_to_decimal(price), do: Decimal.new(price)

  defp convert_date_format(value) do
    {:ok, datetime} =
      ~r/[0-9]{1,}/
      |> Regex.run(value)
      |> List.first()
      |> String.slice(0..-4)
      |> String.to_integer()
      |> DateTime.from_unix()

    datetime
  end
end
