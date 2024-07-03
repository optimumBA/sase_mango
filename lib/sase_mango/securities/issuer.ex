defmodule SaseMango.Securities.Issuer do
  @moduledoc """
  Issuer Ecto schema. Defines all issuer fields and Ecto changeset function.
  """
  use Ecto.Schema

  import Ecto.Changeset

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type t :: %__MODULE__{
          company_data: map() | nil,
          info: map() | nil,
          symbol: String.t() | nil,
          top_10_owners: map() | nil
        }

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
  @spec changeset(t(), attrs()) :: changeset()
  def changeset(%__MODULE__{} = issuer, attrs \\ %{}) do
    issuer
    |> cast(attrs, [:company_data, :info, :symbol, :top_10_owners])
    |> validate_required([:company_data, :info, :symbol, :top_10_owners])
    |> unique_constraint(:symbol)
  end
end
