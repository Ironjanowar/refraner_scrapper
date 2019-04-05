defmodule Refraner.Repo.Migrations.CreateRefranes do
  use Ecto.Migration

  def change do
    create table(:refranes) do
      add(:refran, :string)
      add(:significado, :string)
      add(:ideas_clave, :string)
      add(:tipo, :string)
      add(:marcador_de_uso, :string)
      add(:comentario_marcador_de_uso, :string)
      add(:observaciones, :string)
      add(:observaciones_lexicas, :string)
      add(:idioma, :string)
      add(:idioma_codigo, :string)
      add(:traduccion_literal, :string)
    end
  end
end
