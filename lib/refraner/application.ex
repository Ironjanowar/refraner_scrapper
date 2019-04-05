defmodule Refraner.Application do
  use Application

  def start(_type, _args) do
    children = [
      Refraner.Repo,
      Refraner.Downloader
    ]

    opts = [strategy: :one_for_one]

    Supervisor.start_link(children, opts)
  end
end
