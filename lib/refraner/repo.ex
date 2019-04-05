defmodule Refraner.Repo do
  use Ecto.Repo, otp_app: :refraner, adapter: Sqlite.Ecto2
end
