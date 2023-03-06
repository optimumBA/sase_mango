defmodule SaseMango.Securities.FinancialStatement do
  @moduledoc """
  Financial statement Ecto schema.

  Defines all table fields, including the reference to the associated
  issuer and Ecto changeset function.
  """
  use Ecto.Schema

  import Ecto.Changeset

  schema "financial_statements" do
    belongs_to :issuer, SaseMango.Securities.Issuer
    field :semi_annual, :boolean
    field :statement, :map
    field :year, :integer
    timestamps()
  end

  @doc """
  Financial statements changeset for validation.

  """
  def changeset(financial_statement, attrs \\ %{}) do
    financial_statement
    |> cast(attrs, [:semi_annual, :statement, :year])
    |> validate_required([:semi_annual, :statement, :year])
    |> unique_constraint([:issuer_id, :semi_annual, :year])
  end
end
