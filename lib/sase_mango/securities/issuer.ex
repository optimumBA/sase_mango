defmodule SaseMango.Securities.Issuer do
  @moduledoc """
    Issuer Ecto schema.

    Defines all issuer fileds and Ecto changeset function.
  """
  use Ecto.Schema

  import Ecto.Changeset

  schema "issuers" do
    field :info, :map
    has_many :financial_statements, SaseMango.Securities.FinancialStatement
    field :symbol

    timestamps()
  end

  @doc """
    Issuer changeset for validation.

  """
  def changeset(issuer, attrs \\ %{}) do
    issuer
    |> cast(attrs, [:info, :symbol])
    |> validate_required([:info, :symbol])
    |> unique_constraint(:symbol)
  end
end
