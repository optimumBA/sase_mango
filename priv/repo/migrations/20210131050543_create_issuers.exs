defmodule SaseMango.Repo.Migrations.CreateIssuers do
  use Ecto.Migration

  def change do
    create table(:issuers) do
      add :info, :map, null: false
      add :symbol, :string, null: false
      timestamps()
    end

    create unique_index(:issuers, [:symbol])
  end
end
