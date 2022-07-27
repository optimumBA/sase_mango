defmodule SaseMango.Securities do
  @moduledoc """
    Securities context module.

    Implements functions related to work with issuers, financial statements
    and lists fo securities.

  """

  # import Ecto.Query

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
    Gets single issuer from db

    Returns the issuer if exists, nil otherwise

  """
  def get_issuer(symbol), do: Repo.get_by(Issuer, symbol: symbol)

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
    Gets the financial statement for issuer by semiannual status and year
  """
  def get_financial_statement(%Issuer{} = issuer, semi_annual, year) do
    Repo.get_by(FinancialStatement, issuer_id: issuer.id, semi_annual: semi_annual, year: year)
  end

  @doc """
    Creates the financial statement for current issuer
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

  def list_securities(type_atom, filter_params \\ %{})
      when type_atom in [:securities, :bargains] do
    SecuritiesHelper.list_securities(type_atom, filter_params)
  end
end
