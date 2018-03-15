defmodule Refraner.Repo.Migrations.CreateRefranes do
  use Ecto.Migration

  def change do
    create table(:refranes) do
      add(:refran, :string)
      add(:significado, :string)
      add(:ideas_clave, :string)
      add(:tipo, :string)
      add(:marcador_de_uso, :string)
    end
  end
end
