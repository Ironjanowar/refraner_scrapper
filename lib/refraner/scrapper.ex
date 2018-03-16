defmodule Refraner.Scrapper do
  require Logger
  alias Refraner.Model.Refran

  @downloader Refraner.Downloader

  @listado_base "https://cvc.cervantes.es/lengua/refranero/listado.aspx?letra="
  @refran_base "https://cvc.cervantes.es/lengua/refranero/"

  def main() do
    ?A..?Z
    |> Enum.take(1)
    |> Enum.map(fn letter ->
         url = listado_url(letter)
         @downloader.queue(:list, url)
       end)
  end

  def scrap(:list, body, _) do
    Floki.find(body, "li")
    |> Refraner.get_as()
    |> Enum.map(&Refraner.extract_endpoint/1)
    |> Enum.filter(fn x -> not (x =~ "listado.aspx?letra=") end)
    |> Enum.map(&refran_url/1)
    |> Enum.take(1)
    |> Enum.each(fn url ->
         @downloader.queue(:refran, url, :main)
       end)
  end

  def scrap(:refran, body, :main) do
    more_languages = extract_more_languages(body) |> Enum.take(1)
    extract_and_save_refran_info(body, more_languages)
  end

  def scrap(:refran, body, {:language, parent_id, language}) do
    extract_and_save_refran_info(body, [], language)
  end

  defp extract_more_languages(body) do
    body
    |> Floki.find("#idiomas")
    |> Floki.find("li>a")
    |> Enum.map(&language_to_data/1)
  end

  defp extract_and_save_refran_info(body, other_languages, language_code \\ "ES") do
    [basic_info | more_info] = body |> Floki.find("div.tabbertab")

    refran = extract_basic_info(basic_info, language_code)

    Logger.info("Refran information: #{inspect(refran)}")

    # Insert basic info and extract ID

    refran_id = 1

    extras =
      more_info
      |> Stream.map(&childs/1)
      |> Stream.map(&extract_extra_info/1)
      |> Stream.filter(& &1)
      |> Enum.into(%{})

    Logger.info("Extra refran information: #{inspect(extras)}")

    # Insert all the extra info

    # Queue all the other languages
    Logger.info("Queueing #{length(other_languages)} languages")

    Enum.each(other_languages, fn {language, url} ->
      @downloader.queue(:refran, url, {:language, refran_id, language})
    end)
  end

  defp extract_basic_info(body, language_code) do
    raw_data = body |> Floki.find("p") |> Enum.map(fn {_, _, data} -> data end)
    recursive_basic_format(raw_data, %Refran{idioma_codigo: language_code})
  end

  defp extract_extra_info([{"h2", _, ["Variantes"]} | data]) do
    {:variants, recursive_statements(data)}
  end

  defp extract_extra_info([{"h2", _, ["Sinónimos"]} | data]) do
    {:sinonims, recursive_statements(data)}
  end

  defp extract_extra_info([{"h2", _, ["Antónimos"]} | data]) do
    {:antonims, recursive_statements(data)}
  end

  defp extract_extra_info([{"h2", _, ["Contextos"]} | data]) do
    {:contexts, recursive_contexts(data)}
  end

  defp extract_extra_info(unknown) do
    Logger.info("Unknown extra info: #{inspect(unknown)}")
    nil
  end

  defp language_to_data({"a", [{"href", href} | _], [{"acronym", _, [language]}]}) do
    {language, refran_url(href)}
  end

  defp recursive_basic_format([], refran), do: refran

  defp recursive_basic_format([[{_, _, ["Tipo:" <> _]} | data] | rest], refran) do
    tipo = html_text(data)
    refran = %{refran | tipo: tipo}
    recursive_basic_format(rest, refran)
  end

  defp recursive_basic_format([[{_, _, ["Idioma:" <> _]} | data] | rest], refran) do
    tipo = html_text(data)
    refran = %{refran | idioma: tipo}
    recursive_basic_format(rest, refran)
  end

  defp recursive_basic_format([[{_, _, ["Observaciones léxicas:" <> _]} | data] | rest], refran) do
    tipo = html_text(data)
    refran = %{refran | observaciones_lexicas: tipo}
    recursive_basic_format(rest, refran)
  end

  defp recursive_basic_format([[{_, _, ["Traducción literal:" <> _]} | data] | rest], refran) do
    tipo = html_text(data)
    refran = %{refran | traduccion_literal: tipo}
    recursive_basic_format(rest, refran)
  end

  defp recursive_basic_format([[{_, _, ["Ideas clave:" <> _]} | data] | rest], refran) do
    tipo = html_text(data)
    refran = %{refran | ideas_clave: tipo}
    recursive_basic_format(rest, refran)
  end

  defp recursive_basic_format([[{_, _, ["Significado:" <> _]} | data] | rest], refran) do
    tipo = html_text(data)
    refran = %{refran | significado: tipo}
    recursive_basic_format(rest, refran)
  end

  defp recursive_basic_format([[{_, _, ["Marcador de uso:" <> _]} | data] | rest], refran) do
    tipo = html_text(data)
    refran = %{refran | marcador_de_uso: tipo}
    recursive_basic_format(rest, refran)
  end

  defp recursive_basic_format(
         [[{_, _, ["Comentario al marcador de uso:" <> _]} | data] | rest],
         refran
       ) do
    tipo = html_text(data)
    refran = %{refran | comentario_marcador_de_uso: tipo}
    recursive_basic_format(rest, refran)
  end

  defp recursive_basic_format([[{_, _, ["Enunciado:" <> _]} | data] | rest], refran) do
    tipo = html_text(data)
    refran = %{refran | refran: tipo}
    recursive_basic_format(rest, refran)
  end

  defp recursive_basic_format([[{_, _, ["Observaciones:" <> _]} | data] | rest], refran) do
    tipo = html_text(data)
    refran = %{refran | observaciones: tipo}
    recursive_basic_format(rest, refran)
  end

  defp recursive_basic_format([o | rest], refran) do
    Logger.info("Unknown/ignored basic information: #{inspect(o)}")
    recursive_basic_format(rest, refran)
  end

  # PARSE STATEMENTS

  defp recursive_statements(data), do: data |> extract_all_match("Enunciado:")
  defp recursive_contexts(data), do: extract_all_match(data, "Contexto:")

  defp extract_all_match(data, match) do
    data
    |> Stream.map(&childs/1)
    |> Stream.filter(fn [{_, _, [text]} | _] -> text =~ match end)
    |> Enum.map(fn [_ | data] ->
         html_text(data)
       end)
  end

  defp childs({_, _, data}), do: data

  defp html_text(text), do: text |> Floki.text() |> String.trim()

  defp refran_url("/" <> endpoint), do: refran_url(endpoint)
  defp refran_url(endpoint), do: @refran_base <> endpoint

  defp listado_url(codepoint) when is_number(codepoint), do: <<codepoint::utf8>> |> listado_url
  defp listado_url(letter), do: @listado_base <> letter
end
