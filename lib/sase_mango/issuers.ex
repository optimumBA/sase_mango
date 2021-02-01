defmodule SaseMango.Issuers do
  alias SaseMango.Issuers.{Issuer, FinancialStatement}
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
end
