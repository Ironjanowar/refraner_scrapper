defmodule Refraner do
  require Logger

  alias Refraner.Model.Refran

  # Helpers
  defp letters,
    do: [
      "A",
      "B",
      "C",
      "D",
      "E",
      "F",
      "G",
      "H",
      "I",
      "J",
      "L",
      "M",
      "N",
      "O",
      "P",
      "Q",
      "R",
      "S",
      "T",
      "U",
      "V",
      "Y",
      "Z"
    ]

  defp listado_url, do: "https://cvc.cervantes.es/lengua/refranero/listado.aspx?letra="
  defp url, do: "https://cvc.cervantes.es/lengua/refranero/"

  ## Client API ##
  def get_lis() do
    letters()
    |> Enum.map(fn letter ->
         HTTPoison.get!(listado_url() <> letter).body
       end)
    |> Enum.map(fn x -> Floki.find(x, "li") end)
    |> List.flatten()
  end

  def get_as(lis) do
    lis
    |> Enum.map(fn {_, _, inner_tags} ->
         Enum.find(inner_tags, fn {tag_name, _, _} -> tag_name == "a" end)
       end)
  end

  def extract_endpoint({_, inner_tags, _}) do
    {_, endpoint} = Enum.find(inner_tags, fn {tag, _} -> tag == "href" end)
    endpoint
  end

  def is_enunciado?(text), do: String.starts_with?(text, "Enunciado:")
  def is_not_enunciado?(text), do: not is_enunciado?(text)

  def format_metadata(metadata) do
    metadata =
      Enum.map(metadata, fn text -> String.split(text, ":") end)
      |> Enum.map(fn l -> Enum.map(l, &String.trim/1) end)

    recursive_format(metadata, %Refran{})
  end

  defp recursive_format([["Tipo", tipo] | rest], formatted) do
    formatted = Map.put(formatted, :tipo, tipo)
    recursive_format(rest, formatted)
  end

  defp recursive_format([["Ideas clave", ideas_clave] | rest], formatted) do
    formatted = Map.put(formatted, :ideas_clave, ideas_clave)
    recursive_format(rest, formatted)
  end

  defp recursive_format([["Significado", significado] | rest], formatted) do
    formatted = Map.put(formatted, :significado, significado)
    recursive_format(rest, formatted)
  end

  defp recursive_format([["Marcador de uso", marcador_de_uso] | rest], formatted) do
    formatted = Map.put(formatted, :marcador_de_uso, marcador_de_uso)
    recursive_format(rest, formatted)
  end

  defp recursive_format([["Enunciado", refran] | rest], formatted) do
    formatted = Map.put(formatted, :refran, refran)
    recursive_format(rest, formatted)
  end

  defp recursive_format([_ | rest], formatted) do
    recursive_format(rest, formatted)
  end

  defp recursive_format([], formatted), do: formatted

  defp insert_refran(%Refran{} = refran) do
    {:ok, refran} = Refraner.Repo.insert(refran)

    refran
  end

  def get_refran_by_endpoint("/" <> endpoint), do: get_refran_by_endpoint(endpoint)

  def get_refran_by_endpoint(endpoint) do
    Logger.info("Scrapping endpoint #{endpoint}")

    case HTTPoison.get(url() <> endpoint) do
      {:ok, %{body: body}} ->
        body
        |> Floki.find("div.tabbertab")
        |> Enum.filter(fn tag -> Floki.text(tag) =~ "Paremia" end)
        |> Floki.find("p")
        |> Enum.map(&Floki.text/1)
        |> format_metadata()
        |> insert_refran()

      {:error, _} ->
        Logger.info("Error with endpoint #{endpoint} waiting 20 seconds...")
        # Sleep 20 seconds
        Process.sleep(20_000)
        get_refran_by_endpoint(endpoint)
    end
  end

  def get_all_refranes() do
    get_lis()
    |> get_as()
    |> Enum.map(&extract_endpoint/1)
    |> Enum.filter(fn x -> not (x =~ "listado.aspx?letra=") end)
    |> Enum.each(fn endpoint ->
         # Sleep 5 seconds
         Process.sleep(5000)
         get_refran_by_endpoint(endpoint)
       end)
  end
end
