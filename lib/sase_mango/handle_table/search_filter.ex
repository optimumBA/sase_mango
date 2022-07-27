defmodule SaseMango.HandleTable.SearchFilter do
  @moduledoc """
    SearchFilter module with Ecto schemaless changeset for searching/filtering the table.
  """
  import Ecto.Changeset

  defstruct [:q]

  @types %{q: :string}

  def changeset(%__MODULE__{} = search_filter, attrs \\ %{}) do
    cast({search_filter, @types}, attrs, [:q])
  end
end
