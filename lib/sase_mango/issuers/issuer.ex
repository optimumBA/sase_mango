defmodule SaseMango.Issuers.Issuer do
  use Ecto.Schema

  import Ecto.Changeset

  schema "issuers" do
    field :info, :map
    has_many :financial_statements, SaseMango.Issuers.FinancialStatement
    field :symbol
    timestamps()
  end

  def changeset(issuer, attrs \\ %{}) do
    issuer
    |> cast(attrs, [:info, :symbol])
    |> validate_required([:info, :symbol])
    |> unique_constraint(:symbol)
  end
end
