defmodule SaseMango.HandleTable.SearchFilter do
  @moduledoc """
  SearchFilter module with Ecto schemaless changeset for searching/filtering the table.
  """
  import Ecto.Changeset

  defstruct [:q]

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type t :: %__MODULE__{
          q: String.t() | nil
        }

  @types %{q: :string}

  @doc """
  SearchFilter changeset for validation.
  """
  @spec changeset(t(), attrs()) :: changeset()
  def changeset(%__MODULE__{} = search_filter, attrs \\ %{}) do
    cast({search_filter, @types}, attrs, [:q])
  end
end
