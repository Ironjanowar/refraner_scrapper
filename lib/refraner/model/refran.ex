defmodule Refraner.Model.Refran do
  use Ecto.Schema

  schema "refranes" do
    field(:refran, :string)
    field(:significado, :string)
    field(:ideas_clave, :string)
    field(:tipo, :string)
    field(:marcador_de_uso, :string)
  end
end
