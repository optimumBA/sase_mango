defmodule SaseMango.Securities.Issuer do
  @moduledoc """
  Issuer Ecto schema. Defines all issuer fields and Ecto changeset function.
  """
  use Ecto.Schema

  import Ecto.Changeset

  schema "issuers" do
    field :company_data, :map
    field :info, :map
    field :symbol, :string
    field :top_10_owners, :map

    has_many :financial_statements, SaseMango.Securities.FinancialStatement

    timestamps()
  end

  @doc """
  Issuer changeset for validation.

  """
  def changeset(%__MODULE__{} = issuer, attrs \\ %{}) do
    issuer
    |> cast(attrs, [:company_data, :info, :symbol, :top_10_owners])
    |> validate_required([:company_data, :info, :symbol, :top_10_owners])
    |> unique_constraint(:symbol)
  end
end
