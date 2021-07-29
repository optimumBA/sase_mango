defmodule SaseMango.Securities do
  import Ecto.Query

  alias SaseMango.Securities.{Issuer, FinancialStatement}
  alias SaseMango.Repo

  def get_issuer(symbol) do
    Issuer |> Repo.get_by(symbol: symbol)
  end

  def create_issuer(attrs) do
    %Issuer{}
    |> Issuer.changeset(attrs)
    |> Repo.insert()
  end

  def update_issuer(issuer, attrs) do
    issuer
    |> Issuer.changeset(attrs)
    |> Repo.update()
  end

  def get_financial_statement(%Issuer{} = issuer, semi_annual, year) do
    FinancialStatement |> Repo.get_by(issuer_id: issuer.id, semi_annual: semi_annual, year: year)
  end

  def create_financial_statement(issuer, attrs) do
    %FinancialStatement{}
    |> FinancialStatement.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:issuer, issuer)
    |> Repo.insert()
  rescue
    error ->
      {:error, error}
  end

  def list_securities() do
    current_year = NaiveDateTime.utc_now() |> Map.fetch!(:year)
    current = current_year - 1
    previous = current_year - 2

    from(issuer in Issuer, as: :issuer)
    |> join(:left, [issuer], fs in assoc(issuer, :financial_statements),
      on: fs.year == ^current,
      on: fs.semi_annual == false
    )
    |> join(:left, [issuer], fs in assoc(issuer, :financial_statements),
      on: fs.year == ^previous,
      on: fs.semi_annual == false
    )
    |> select([issuer, current, previous], %{
      issuer: issuer,
      current: current,
      previous: previous
    })
    |> where(fragment("(info->'BestAskPrice')::NUMERIC > 0"))
    |> where(fragment("(info->'AvgPrice')::NUMERIC > 0"))
    |> Repo.all()
    |> Stream.map(fn %{} = security ->
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

      ask_price = convert_price_to_decimal(security.issuer.info["BestAskPrice"])
      price = convert_price_to_decimal(security.issuer.info["AvgPrice"])

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
          else: Decimal.mult(price, total_shares)
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
        ask_price_eps_roi:
          if(Decimal.equal?(ask_price, 0), do: Decimal.new(0), else: Decimal.div(eps, ask_price)),
        book_value: book_value,
        bvs: bvs,
        dividend: dividend,
        dividend_roi:
          if(Decimal.equal?(price, 0), do: Decimal.new(0), else: Decimal.div(dividend, price)),
        eps: eps,
        eps_roi: if(Decimal.equal?(price, 0), do: Decimal.new(0), else: Decimal.div(eps, price)),
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
            else: Decimal.div(price, Decimal.div(profit, total_shares))
          ),
        previous_book_value: previous_book_value,
        previous_bvs: previous_bvs,
        previous_dividend: previous_dividend,
        previous_dividend_roi:
          if(
            Decimal.equal?(price, 0),
            do: Decimal.new(0),
            else: Decimal.div(previous_dividend, price)
          ),
        previous_eps: previous_eps,
        previous_eps_roi:
          if(Decimal.equal?(price, 0), do: Decimal.new(0), else: Decimal.div(previous_eps, price)),
        previous_profit: previous_profit,
        previous_profit_margin: previous_profit_margin,
        price: price,
        profit: profit,
        profit_margin: profit_margin,
        segment: security.issuer.info["Segment"],
        symbol: symbol
      }
    end)
    |> Stream.filter(fn security ->
      Decimal.gt?(security.profit, Decimal.new(0)) &&
        Decimal.gt?(security.previous_profit, Decimal.new(0)) &&
        Decimal.lt?(security.price, Decimal.mult(security.bvs, Decimal.div(2, 3))) &&
        Decimal.lt?(security.pb, Decimal.new(20)) &&
        Decimal.lt?(security.pe, Decimal.new(20)) &&
        Decimal.gt?(security.eps_roi, Decimal.from_float(0.05))
    end)
    |> Enum.sort_by(& &1.ask_price_eps_roi, {:desc, Decimal})
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
end
