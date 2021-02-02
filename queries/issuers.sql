SELECT
  symbol,
  info->>'SymbolDescription' AS description,
  info->>'Segment' AS segment,
  info->'AvgPrice' AS price,
  info->'LastTradePrice' AS last_price,
  TO_TIMESTAMP(SUBSTRING(info->>'LastTradeDate', 7, 10)::INTEGER) AS last_date,
  total_shares,
  nominal_price,
  total_dividends::DECIMAL,
  previous_total_dividends::DECIMAL,
  ROUND(total_dividends::DECIMAL / total_shares, 2) AS dividend,
  ROUND(previous_total_dividends::DECIMAL / total_shares, 2) AS previous_dividend,
  (CASE WHEN (info->'LastTradePrice')::FLOAT = 0 THEN NULL ELSE ROUND((total_dividends::DECIMAL / total_shares) / (info->'LastTradePrice')::DECIMAL * 100, 2) END) AS dividend_roi,
  (CASE WHEN (info->'LastTradePrice')::FLOAT = 0 THEN NULL ELSE ROUND((previous_total_dividends::DECIMAL / total_shares) / (info->'LastTradePrice')::DECIMAL * 100, 2) END) AS previous_dividend_roi
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
      WHERE year = 2019 AND semi_annual = FALSE
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
      WHERE year = 2018 AND semi_annual = FALSE
    ) financial_statements,
    JSONB_ARRAY_ELEMENTS(financial_statements.statement->'EQUITYCHANGES') equity_changes
  WHERE equity_changes->>'Description' = '21. Objavljene dividende i drugi oblici raspodjele dobiti i pokriće gubitka'
) previous_equity_changes ON previous_equity_changes.issuer_id = issuers.id
ORDER BY dividend_roi DESC NULLS LAST, last_date DESC
