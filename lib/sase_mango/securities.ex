defmodule SaseMango.Securities do
  @moduledoc """
  Securities context module.
  Implements functions related to work with issuers, financial statements and lists for securities.
  """

  import Ecto.Query, warn: false

  alias SaseMango.HandleTable
  alias SaseMango.Securities.FinancialStatement
  alias SaseMango.Securities.Issuer
  alias SaseMango.SecuritiesHelper
  alias SaseMango.Repo

  @doc """
  Returns the list of issuers.

  ## Examples

      iex> list_issuers()
      [%Issuer{}, ...]

  """
  def list_issuers(), do: Repo.all(Issuer)

  @doc """
  Gets single issuer from db.
  Returns the issuer if exists, nil otherwise.
  """
  def get_issuer(symbol), do: Repo.get_by(Issuer, symbol: symbol)

  @doc """
  Gets company data for issuer.
  Returns all relevant company information and facts owned by the Issuer.
  """
  def get_company_data(symbol) do
    Issuer
    |> where([is], is.symbol == ^symbol)
    |> select([is], %{
      symbol: is.symbol,
      info: is.info,
      name: is.info["SymbolDescription"],
      symbol_data: is.company_data,
      top_10_owners: is.top_10_owners["top_10"]
    })
    |> Repo.one()
    |> format_company_data()
  end

  defp format_company_data(nil), do: nil

  defp format_company_data(data) do
    # For some issuers we get useless map instead of string
    maybe_audit_committee =
      if(is_binary(data.symbol_data["AuditCommittee"]),
        do: data.symbol_data["AuditCommittee"],
        else: nil
      )

    symbol_data = %{
      isin: data.info["ISIN"],
      short_name: data.symbol_data["RegistrationNumber"],
      company: data.symbol_data["Company"],
      address: data.symbol_data["Address"],
      contact: data.symbol_data["Contact"],
      email: data.symbol_data["Email"],
      web_page: data.symbol_data["WebPage"],
      activity: data.symbol_data["Activity"],
      external_auditor: data.symbol_data["ExternalAuditor"],
      audit_committee: maybe_audit_committee,
      number_of_employees: data.symbol_data["NumberOfEmployees"],
      number_of_bussines_units: data.symbol_data["NumberOfBussinesUnits"]
    }

    supervisory_board =
      SecuritiesHelper.filter_management_and_supervisory_data(
        data.symbol_data["SupervisoryBoard"]
      )

    management_board =
      SecuritiesHelper.filter_management_and_supervisory_data(data.symbol_data["ManagementBoard"])

    parsed_number_of_shares_nominal_price =
      SecuritiesHelper.parse_shares_and_nominal_price(
        data.symbol_data["NumberOfSharesNominalPrice"]
      )

    securities_and_shareholders_data = %{
      total_number_of_shareholders: data.symbol_data["TotalNumberOfShareholders"],
      shares_nominal_price: parsed_number_of_shares_nominal_price,
      sase_url: "http://www.sase.ba/v1/Tržište/Emitenti/Profil-emitenta/symbol/#{data.symbol}"
    }

    top_10_owners =
      cond do
        data.top_10_owners && is_list(data.top_10_owners) -> data.top_10_owners
        data.top_10_owners && is_map(data.top_10_owners) -> [data.top_10_owners]
        true -> []
      end

    maybe_management_shares =
      if is_binary(data.symbol_data["ManagementShares"]) do
        data.symbol_data["ManagementShares"]
      else
        nil
      end

    legal_entities = data.symbol_data["LegalEntityTheIssuerHoldsMoreThan10Percent"]

    %{}
    |> Map.merge(%{symbol: data.symbol, name: data.name})
    |> Map.merge(%{symbol_data: symbol_data})
    |> Map.merge(%{top_10_owners: top_10_owners})
    |> Map.merge(%{supervisory_board: supervisory_board})
    |> Map.merge(%{management_board: management_board})
    |> Map.merge(%{management_shares: maybe_management_shares})
    |> Map.merge(%{securities_and_shareholders_data: securities_and_shareholders_data})
    |> Map.merge(%{legal_entities: legal_entities})
    |> Map.new()
  end

  @doc """
  Creates the issuer.

  ## Examples

      iex> create_issuer(%{field: value})
      {:ok, %Issuer{}}

      iex> create_issuer(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_issuer(attrs) do
    %Issuer{}
    |> Issuer.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates the issuer.

  ## Examples

      iex> update_issuer(issuer, %{field: new_value})
      {:ok, %Issuer{}}

      iex> update_issuer(issuer, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_issuer(issuer, attrs) do
    issuer
    |> Issuer.changeset(attrs)
    |> Repo.update()
  end

  @doc """
    Gets the financial statement for issuer by semiannual status and year.
  """
  def get_financial_statement(%Issuer{} = issuer, semi_annual, year) do
    Repo.get_by(FinancialStatement, issuer_id: issuer.id, semi_annual: semi_annual, year: year)
  end

  @doc """
  Creates the financial statement for current issuer.
  """
  def create_financial_statement(issuer, attrs) do
    %FinancialStatement{}
    |> FinancialStatement.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:issuer, issuer)
    |> Repo.insert()
  rescue
    error ->
      {:error, error}
  end

  @doc """
  Helper function that returns market segment for specific security.
  """
  def segment("Free market - Subsegment 1"), do: "ST1"
  def segment("Free market - Subsegment 2"), do: "ST2"
  def segment("Free market - Subsegment 3"), do: "ST3"
  def segment("The Official market - The Official market of companies"), do: "Companies"
  def segment("The Official market - The Official market of funds"), do: "Funds"

  def list_securities(type_atom, params \\ %{})
      when type_atom in [:securities, :bargains] do
    SecuritiesHelper.list_securities(type_atom, params)
  end

  @doc """
  Returns the list of all investors on market.
  """
  def list_investors() do
    issuers_list = list_issuers()

    get_unique_investors_list()
    |> Stream.map(fn investor ->
      company_stocks = company_stocks(issuers_list, investor)

      Map.merge(
        investor,
        %{
          name_slug: HandleTable.create_slug(investor.name),
          company_number: Enum.count(company_stocks),
          total_capital:
            Enum.reduce(company_stocks, 0, fn %{value: value}, acc ->
              Decimal.add(acc, value)
            end),
          issuers: company_stocks
        }
      )
    end)
    |> Stream.reject(&(&1.company_number == 0))
    |> Enum.to_list()
  end

  defp company_stocks(issuers_list, investor) do
    issuers_list
    |> Enum.reduce([], fn issuer, filtered_list ->
      with %{company_data: company_data, top_10_owners: top_10_owners} <- issuer,
           false <- is_nil(top_10_owners["top_10"]),
           true <- map_size(company_data) > 0,
           investor_from_issuer <- has_stocks_in_company(top_10_owners["top_10"], investor),
           false <- is_nil(investor_from_issuer) do
        shares_number =
          SecuritiesHelper.get_shares_number_for_issuer(
            issuer.company_data["NumberOfSharesNominalPrice"],
            issuer.symbol
          )

        investor_percentage =
          investor_from_issuer["procenti"]
          |> SecuritiesHelper.convert_number_to_decimal()
          |> Decimal.div(100)

        [
          %{
            issuer: issuer,
            value: calculate_stock_value(issuer, investor_from_issuer),
            shares_number: Decimal.mult(shares_number, investor_percentage)
          }
          | filtered_list
        ]
      else
        false ->
          filtered_list

        true ->
          filtered_list
      end
    end)
  end

  defp calculate_stock_value(issuer, investor) do
    number_of_shares =
      SecuritiesHelper.get_shares_number_for_issuer(
        issuer.company_data["NumberOfSharesNominalPrice"],
        issuer.symbol
      )

    price = SecuritiesHelper.convert_number_to_decimal(issuer.info["AvgPrice"])

    investor_percentage = SecuritiesHelper.convert_number_to_decimal(investor["procenti"])

    Decimal.mult(Decimal.mult(number_of_shares, price), Decimal.div(investor_percentage, 100))
  end

  defp get_unique_investors_list() do
    from(i in Issuer, as: :issuer)
    |> select([issuer: is], is.top_10_owners["top_10"])
    |> Repo.all()
    |> Enum.reduce([], fn
      nil, final_list ->
        final_list

      list, final_list when is_map(list) ->
        Enum.concat(final_list, [list])

      list, final_list ->
        Enum.concat(final_list, list)
    end)
    |> Stream.map(&%{name: &1["naziv"]})
    |> Stream.uniq_by(fn %{name: name} = _investor -> name end)
    |> Enum.to_list()
  end

  defp has_stocks_in_company(top_10_owners, investor) when is_list(top_10_owners) do
    Enum.find(top_10_owners, fn %{"naziv" => naziv} -> investor.name == naziv end)
  end

  defp has_stocks_in_company(top_10_owners, investor) when is_map(top_10_owners) do
    Enum.find([top_10_owners], fn %{"naziv" => naziv} -> investor.name == naziv end)
  end
end
