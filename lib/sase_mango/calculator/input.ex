defmodule SaseMango.Calculator.Input do
  @moduledoc """
  Defines a CalculatorInput struct.
  """

  import Ecto.Changeset

  defstruct [:amount, :fee, :price, :symbol]

  @type t :: %__MODULE__{
          amount: Decimal.t() | nil,
          fee: Decimal.t() | nil,
          price: Decimal.t() | nil,
          symbol: String.t() | nil
        }

  @types %{
    amount: :decimal,
    fee: :decimal,
    price: :decimal,
    symbol: :string
  }

  @doc """
  CalculatorInput changeset for validation.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(input, attrs \\ %{}) do
    {input, @types}
    |> cast(attrs, Map.keys(@types))
    |> validate_required([:amount, :fee, :price, :symbol])
    |> validate_number(:amount, greater_than: 0.0, message: "Amount must be greater than 0.0")
    |> validate_number(:fee,
      greater_than: 0.0,
      less_than: 100.0,
      message: "Fee must be greater than 0% and less that 100%"
    )
    |> validate_number(:price, greater_than: 0.0, message: "Price must be greater than 0.0")
  end
end
