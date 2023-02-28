defmodule SaseMango.Repo.Migrations.AddCompanyDataForIssuers do
  use Ecto.Migration

  def change do
    alter table(:issuers) do
      add :company_data, :map
      add :top_10_owners, :map
    end
  end
end
