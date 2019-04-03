defmodule Plug.Parsers.XML do

  @behaviour Plug.Parsers
  import Plug.Conn
  # import SweetXml

  def init(options), do: options

  def parse(conn, _, "xml", _headers, opts) do
    decoder = Keyword.get(opts, :xml_decoder) || raise ArgumentError, "XML parser expects a :xml_decoder option"
    conn
    |> read_body(opts)
    |> decode(decoder)
  end

  def parse(conn, _type, _subtype, _headers, _opts) do
    {:next, conn}
  end


  # defp decode({:ok, body, conn}, _decoder) do
  #   try do
  #     parsed = parse(body, namespace_conformant: true)
  #     {:ok, %{xml: parsed}, conn}
  #   catch
  #     :exit, e -> raise Plug.Parsers.ParseError, exception: e
  #   end
  # end

  defp decode({:ok, body, conn}, decoder) do
    case decoder.string(String.to_charlist(body)) do
      {parsed, []} ->
        {:ok, %{xml: parsed}, conn}
      error ->
        raise "Malformed XML #{error}"
    end
  rescue
    e -> raise Plug.Parsers.ParseError, exception: e
  end

end
