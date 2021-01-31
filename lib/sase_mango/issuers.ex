defmodule SaseMango.Issuers do
  alias SaseMango.Issuers.{Issuer, FinancialStatement}
  alias SaseMango.Repo

  def create_issuer(attrs) do
    %Issuer{}
    |> Issuer.changeset(attrs)
    |> Repo.insert()
  end

  def create_financial_statement(issuer, attrs) do
    %FinancialStatement{}
    |> FinancialStatement.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:issuer, issuer)
    |> Repo.insert()
  end
end
