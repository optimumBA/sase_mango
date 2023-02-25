defmodule SaseMango.Securities do
  @moduledoc """
  Securities context module.
  Implements functions related to work with issuers, financial statements and lists for securities.
  """

  import Ecto.Query, warn: false

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
    |> convert_company_data()
  end

  defp convert_company_data(data) do
    symbol_data = %{
      isin: data.info["ISIN"],
      short_name: data.symbol_data["RegistrationNumber"],
      company: data.info["SymbolDescription"],
      address: data.symbol_data["Address"],
      contact: data.symbol_data["Contact"],
      email: data.symbol_data["Email"],
      web_page: data.symbol_data["WebPage"],
      activity: data.symbol_data["Activity"],
      external_auditor: data.symbol_data["ExternalAuditor"],
      audit_committee: data.symbol_data["AuditCommittee"],
      number_of_employees: data.symbol_data["NumberOfEmployees"],
      number_of_bussines_units: data.symbol_data["NumberOfBussinesUnits"]
    }

    supervisory_board =
      filter_management_and_supervisory_board(data.symbol_data["SupervisoryBoard"])

    management_board =
      filter_management_and_supervisory_board(data.symbol_data["ManagementBoard"])

    number_of_shares_nominal_price =
      data.symbol_data["NumberOfSharesNominalPrice"]
      |> String.split(~r/<\/a>/)
      |> List.last()

    securities_and_shareholders_data = %{
      total_number_of_shareholders: data.symbol_data["TotalNumberOfShareholders"],
      number_of_shares_nominal_price: number_of_shares_nominal_price,
      sase_url: "http://www.sase.ba/v1/Tržište/Emitenti/Profil-emitenta/symbol/#{data.symbol}"
    }

    top_10_owners =
      if is_list(data.top_10_owners),
        do: data.top_10_owners,
        else: [data.top_10_owners]

    %{}
    |> Map.merge(%{symbol: data.symbol, name: data.name})
    |> Map.merge(%{symbol_data: symbol_data})
    |> Map.merge(%{top_10_owners: top_10_owners})
    |> Map.merge(%{supervisory_board: supervisory_board})
    |> Map.merge(%{management_board: management_board})
    |> Map.merge(%{management_shares: data.symbol_data["ManagementShares"]})
    |> Map.merge(%{securities_and_shareholders_data: securities_and_shareholders_data})
    |> Map.new()
  end

  defp filter_management_and_supervisory_board(data) do
    board_data_list = String.split(data, ~r/(\s)*(,|-)(\s)*/, trim: true)

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
            {item, elem(next_el, 0)}

          is_name? ->
            {item, ""}

          true ->
            nil
        end
      end)
      |> Stream.reject(&is_nil/1)
      |> Enum.map(& &1)
    else
      board_data_list
      |> Enum.chunk_every(2)
      |> Enum.map(fn [k, v] -> {k, v} end)
    end
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
end
