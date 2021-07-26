defmodule SaseMango.Securities.FinancialStatement do
  use Ecto.Schema

  import Ecto.Changeset

  schema "financial_statements" do
    belongs_to :issuer, SaseMango.Securities.Issuer
    field :semi_annual, :boolean
    field :statement, :map
    field :year, :integer
    timestamps()
  end

  def changeset(financial_statement, attrs \\ %{}) do
    financial_statement
    |> cast(attrs, [:semi_annual, :statement, :year])
    |> validate_required([:semi_annual, :statement, :year])
    |> unique_constraint([:issuer_id, :semi_annual, :year])
  end
end
