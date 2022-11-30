defmodule SaseMango.Calculator.Input do
  import Ecto.Changeset

  @types %{
    amount: :decimal,
    fee: :decimal,
    price: :decimal,
    symbol: :string
  }

  defstruct [:amount, :fee, :price, :symbol]

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
