defmodule Refraner.Downloader do
  use GenServer

  require Logger

  @normal_delay 5_000
  @timeout_delay 20_000

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:ok, []}
  end

  def queue(kind, url, extra_info \\ nil, pid \\ __MODULE__) do
    GenServer.cast(pid, {:queue, {kind, url, extra_info}})
  end

  def handle_cast({:queue, data}, state) do
    Logger.info("QUEUEING DATA: #{inspect(data)}")

    new_data = state ++ [data]

    {:noreply, new_data, @normal_delay}
  end

  def handle_info(:timeout, []) do
    {:noreply, [], @normal_delay}
  end

  def handle_info(:timeout, [{kind, url, info} | urls]) do
    Logger.info("Downloading url #{url}")

    with {:ok, data} <- HTTPoison.get(url) do
      spawn(fn -> Refraner.Scrapper.scrap(kind, data.body, info) end)

      {:noreply, urls, @normal_delay}
    else
      _ ->
        Logger.warn("Error with url #{url} waiting 20 seconds...")
        {:noreply, [{kind, url} | urls], @timeout_delay}
    end
  end
end
