defmodule SaseMango.Repo.Migrations.CreateFinancialStatements do
  use Ecto.Migration

  def change do
    create table(:financial_statements) do
      add :issuer_id, references(:issuers), null: false
      add :semi_annual, :boolean, default: false, null: false
      add :statement, :map, null: false
      add :year, :integer, null: false
      timestamps()
    end

    create index(:financial_statements, :issuer_id)
    create unique_index(:financial_statements, [:issuer_id, :semi_annual, :year])
  end
end
