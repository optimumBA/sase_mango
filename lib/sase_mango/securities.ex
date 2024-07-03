defmodule SaseMango.Securities do
  @moduledoc """
  Securities context module.
  Implements functions related to work with issuers, financial statements and lists for securities.
  """

  import Ecto.Query, warn: false

  alias SaseMango.Repo
  alias SaseMango.Securities.FinancialStatement
  alias SaseMango.Securities.Issuer
  alias SaseMango.SecuritiesHelper

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type financial_statement :: FinancialStatement.t()
  @type issuer :: Issuer.t()
  @type semi_annual :: boolean()
  @type symbol :: String.t()
  @type year :: integer()

  @doc """
  Returns the list of issuers.

  ## Examples

      iex> list_issuers()
      [%Issuer{}, ...]

  """
  @spec list_issuers() :: [issuer()]
  def list_issuers, do: Repo.all(Issuer)

  @doc """
  Gets single issuer from db.
  Returns the issuer if exists, nil otherwise.

  ## Examples

      iex> get_issuer("BSNLR")
      %Issuer{}

      iex> get_issuer("NON-EXISTENT")
      nil

  """
  @spec get_issuer(symbol) :: issuer() | nil
  def get_issuer(symbol), do: Repo.get_by(Issuer, symbol: symbol)

  @doc """
  Gets company data for issuer.
  Returns all relevant company information and facts owned by the Issuer.

   ## Examples

      iex> get_comapny_data("BSNLR")
      %{symbol: "BSNLR", ...}

      iex> get_comapny_data("NON-EXISTENT")
      nil

  """
  @spec get_company_data(symbol) :: map() | nil
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
  @spec create_issuer(attrs()) :: {:ok, issuer()} | {:error, changeset()}
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
  @spec update_issuer(issuer(), attrs()) :: {:ok, issuer()} | {:error, changeset()}
  def update_issuer(issuer, attrs) do
    issuer
    |> Issuer.changeset(attrs)
    |> Repo.update()
  end

  @doc """
    Gets the financial statement for issuer by semiannual status and year.

     ## Examples

      iex> get_financial_statement(issuer, true, 2023)
      %FinancialStatement{semi_annual: true, ...}

      iex> get_financial_statement(non_existent_issuer, true, 2023)
      nil

  """
  @spec get_financial_statement(issuer(), semi_annual(), year()) :: financial_statement() | nil
  def get_financial_statement(%Issuer{} = issuer, semi_annual, year) do
    Repo.get_by(FinancialStatement, issuer_id: issuer.id, semi_annual: semi_annual, year: year)
  end

  @doc """
  Creates the financial statement for current issuer.
  """
  @spec create_financial_statement(issuer(), attrs()) ::
          {:ok, financial_statement()} | {:error, any()}
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
  @spec segment(String.t()) :: String.t()
  def segment("Free market - Subsegment 1"), do: "ST1"
  def segment("Free market - Subsegment 2"), do: "ST2"
  def segment("Free market - Subsegment 3"), do: "ST3"
  def segment("The Official market - The Official market of companies"), do: "Companies"
  def segment("The Official market - The Official market of funds"), do: "Funds"

  @spec list_securities(atom(), map()) :: Enumerable.t()
  def list_securities(type_atom, params \\ %{})
      when type_atom in [:securities, :bargains] do
    SecuritiesHelper.list_securities(type_atom, params)
  end
end
