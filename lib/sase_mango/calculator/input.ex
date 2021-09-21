defmodule SaseMango.Calculator.Input do
  import Ecto.Changeset

  @types %{amount: :decimal, fee: :decimal}

  defstruct [:amount, :fee]

  def changeset(input, attrs \\ %{}) do
    {input, @types}
    |> cast(attrs, Map.keys(@types))
    |> validate_required([:amount, :fee])
    |> validate_number(:amount, greater_than: 0.0)
    |> validate_number(:fee, greater_than: 0.0, less_than: 100.0)
  end
end
