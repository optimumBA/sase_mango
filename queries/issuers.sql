SELECT *
FROM (
  SELECT
    symbol,
    info->>'SymbolDescription' AS description,
    (info->'AvgPrice')::DECIMAL AS price,
    (info->>'BestAskPrice')::numeric AS ask_price,
    ROUND(total_dividends::DECIMAL / total_shares, 2) AS dividend,
    (CASE WHEN (info->'LastTradePrice')::FLOAT = 0 THEN NULL ELSE ROUND((total_dividends::DECIMAL / total_shares) / (info->'LastTradePrice')::DECIMAL * 100, 2) END) AS dividend_roi,
    (CASE WHEN (info->'LastTradePrice')::FLOAT = 0 THEN NULL ELSE ROUND((previous_total_dividends::DECIMAL / total_shares) / (info->'LastTradePrice')::DECIMAL * 100, 2) END) AS previous_dividend_roi,
    ROUND(profits.ongoing_year::DECIMAL / total_shares, 2) AS eps,
    (CASE WHEN (info->'AvgPrice')::FLOAT = 0 THEN NULL ELSE ROUND((profits.ongoing_year::DECIMAL / total_shares) / (info->'AvgPrice')::DECIMAL * 100, 2) END) AS eps_roi,
    (CASE WHEN (info->'BestAskPrice')::FLOAT = 0 THEN NULL ELSE ROUND((profits.ongoing_year::DECIMAL / total_shares) / (info->'BestAskPrice')::DECIMAL * 100, 2) END) AS ask_price_eps_roi,
    ROUND(profits.previous_year::DECIMAL / total_shares, 2) AS previous_eps,
    (CASE WHEN profits.ongoing_year::DECIMAL = 0 THEN NULL ELSE ROUND((info->'AvgPrice')::DECIMAL / (profits.ongoing_year::DECIMAL / total_shares), 4) END) AS pe,
    (CASE WHEN book_value::DECIMAL = 0 THEN NULL ELSE ROUND((info->'AvgPrice')::DECIMAL / (book_value::DECIMAL / total_shares), 4) END) AS pb,
    ((info->>'AvgPrice')::DECIMAL * total_shares) AS market_value,
    book_value,
    previous_book_value,
    ROUND(book_value::DECIMAL / total_shares, 2) AS bvs,
    ROUND(previous_book_value::DECIMAL / total_shares, 2) AS previous_bvs,
    ROUND(previous_total_dividends::DECIMAL / total_shares, 2) AS previous_dividend,
    ((info->>'AvgPrice')::DECIMAL - ROUND(book_value::DECIMAL / total_shares, 2) * 2) AS golden_ratio,
    info->>'Segment' AS segment,
    (info->'LastTradePrice')::DECIMAL AS last_price,
    TO_TIMESTAMP(SUBSTRING(info->>'LastTradeDate', 7, 10)::INTEGER) AS last_date,
    total_shares,
    nominal_price,
    total_dividends::DECIMAL,
    previous_total_dividends::DECIMAL,
    incomes.ongoing_year AS income,
    incomes.previous_year AS previous_income,
    profits.ongoing_year::DECIMAL AS profit,
    profits.previous_year::DECIMAL AS previous_profit,
    (CASE WHEN incomes.ongoing_year::DECIMAL = 0 THEN NULL ELSE ROUND(profits.ongoing_year::DECIMAL / incomes.ongoing_year::DECIMAL, 2) END) AS profit_margin,
    (CASE WHEN incomes.previous_year::DECIMAL = 0 THEN NULL ELSE ROUND(profits.previous_year::DECIMAL / incomes.previous_year::DECIMAL, 2) END) AS previous_profit_margin
    -- TODO: eps_growth
    -- (CASE WHEN profits.ongoing_year::DECIMAL = 0 OR profits.previous_year::DECIMAL = 0 THEN NULL ELSE ((info->'AvgPrice')::DECIMAL / (profits.ongoing_year::DECIMAL / total_shares)) / (eps_growth) END) AS peg
  FROM issuers
  JOIN (
    SELECT issuer_id, total_shares, nominal_price
    FROM (
      SELECT issuer_id, REPLACE(matches[1], '.', '')::INTEGER AS total_shares, REPLACE(matches[2], ',', '.')::DECIMAL AS nominal_price
      FROM (
        SELECT issuer_id, REGEXP_MATCHES(financial_statements."statement"->'GENERALINFO'->>'NumberOfSharesNominalPrice', (issuers.symbol || '<\/a> \- ([\d\.]+) \- ([\d\.\,]+) KM')) AS matches
        FROM financial_statements
        JOIN issuers ON issuers.id = financial_statements.issuer_id
        WHERE year = 2020
        AND semi_annual = FALSE
      ) general_info
    ) general_info
  ) general_info ON general_info.issuer_id = issuers.id
  LEFT JOIN (
    SELECT issuer_id, equity_changes->>'TotalCapital' AS total_dividends
    FROM
      (
        SELECT DISTINCT ON (issuer_id, year, semi_annual) issuer_id, statement
        FROM financial_statements
        WHERE year = 2020 AND semi_annual = FALSE
      ) financial_statements,
      JSONB_ARRAY_ELEMENTS(financial_statements.statement->'EQUITYCHANGES') equity_changes
    WHERE equity_changes->>'Description' = '21. Objavljene dividende i drugi oblici raspodjele dobiti i pokriće gubitka'
  ) equity_changes ON equity_changes.issuer_id = issuers.id
  LEFT JOIN (
    SELECT issuer_id, equity_changes->>'TotalCapital' AS previous_total_dividends
    FROM
      (
        SELECT DISTINCT ON (issuer_id, year, semi_annual) issuer_id, statement
        FROM financial_statements
        WHERE year = 2019 AND semi_annual = FALSE
      ) financial_statements,
      JSONB_ARRAY_ELEMENTS(financial_statements.statement->'EQUITYCHANGES') equity_changes
    WHERE equity_changes->>'Description' = '21. Objavljene dividende i drugi oblici raspodjele dobiti i pokriće gubitka'
  ) previous_equity_changes ON previous_equity_changes.issuer_id = issuers.id
  LEFT JOIN (
    SELECT issuer_id, equity_changes->>'Neto' AS book_value, equity_changes->>'PreviousYear' AS previous_book_value, equity_changes->>'Bruto' AS bruto
    FROM
      (
        SELECT DISTINCT ON (issuer_id, year, semi_annual) issuer_id, statement
        FROM financial_statements
        WHERE year = 2020 AND semi_annual = FALSE
      ) financial_statements,
      JSONB_ARRAY_ELEMENTS(financial_statements.statement->'BALANCESHEET') equity_changes
    WHERE equity_changes->>'Description' = 'A) STALNA SREDSTVA I DUGOROČNI PLASMANI (002+008+014+015+020+021+030+033)'
  ) book_values ON book_values.issuer_id = issuers.id
  LEFT JOIN (
    SELECT issuer_id, profits_and_losses->>'OngoingYear' AS ongoing_year, profits_and_losses->>'PreviousYear' AS previous_year
    FROM
      (
        SELECT DISTINCT ON (issuer_id, year, semi_annual) issuer_id, statement
        FROM financial_statements
        WHERE year = 2020 AND semi_annual = FALSE
      ) financial_statements,
      JSONB_ARRAY_ELEMENTS(financial_statements.statement->'PROFITANDLOSSACCOUNT') profits_and_losses
    WHERE profits_and_losses->>'Description' = 'Poslovni prihodi (202+206+210+211)'
  ) incomes ON incomes.issuer_id = issuers.id
  LEFT JOIN (
    SELECT issuer_id, profits_and_losses->>'OngoingYear' AS ongoing_year, profits_and_losses->>'PreviousYear' AS previous_year
    FROM
      (
        SELECT DISTINCT ON (issuer_id, year, semi_annual) issuer_id, statement
        FROM financial_statements
        WHERE year = 2020 AND semi_annual = FALSE
      ) financial_statements,
      JSONB_ARRAY_ELEMENTS(financial_statements.statement->'PROFITANDLOSSACCOUNT') profits_and_losses
    WHERE profits_and_losses->>'Description' = 'Ukupna neto sveobuhv. dobit/gubitak prema vlasništvu (332 ili 333)'
  ) profits ON profits.issuer_id = issuers.id
) issuers
WHERE price > 0
  AND profit > 0
  AND previous_profit > 0
  AND price < bvs * 2 / 3
  AND pb < 20
  AND pe < 20
  AND eps_roi > 5
  AND ask_price > 0
ORDER BY ask_price_eps_roi DESC NULLS LAST
