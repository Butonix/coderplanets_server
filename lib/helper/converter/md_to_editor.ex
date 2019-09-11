defmodule Helper.Converter.MdToEditor do
  @moduledoc """
  parse markdown ast to editor json data

  see https://editorjs.io/
  """

  @supported_header ["h1", "h2", "h3"]

  @spec parse(binary | [any]) :: any
  def parse(mdstring) do
    {:ok, ast, _opt} = Earmark.as_ast(mdstring)
    # IO.inspect(ast, label: "raw ast")

    editor_blocks =
      Enum.reduce(ast, [], fn ast_item, acc ->
        parsed = parse_block(ast_item)
        acc ++ [parsed]
      end)

    # IO.inspect(editor_blocks, label: "final editor_blocks")
    editor_blocks
  end

  # TODO:  parse h4-6 as h3
  defp parse_block({type, _opt, content})
       when type in @supported_header do
    content_text =
      Enum.reduce(content, [], fn content_item, acc ->
        parsed = parse_content(type, content_item)
        acc ++ parsed
      end)

    # IO.inspect(content_text, label: "h-type content_text")

    [_, level] = String.split(type, "h")
    level = String.to_integer(level)

    %{
      type: "header",
      data: %{
        text: content_text,
        level: level
      }
    }
  end

  defp parse_block({"p", _opt, content}) do
    content_text =
      Enum.reduce(content, [], fn content_item, acc ->
        parsed = parse_content("p", content_item)
        acc ++ parsed
      end)

    %{
      type: "paragraph",
      data: %{
        text: content_text
      }
    }
  end

  defp parse_block({_type, _opt, _content}) do
    # IO.inspect(name, label: "parse block")
    # IO.inspect(content, label: "content")
    %{}
  end

  # 字符串直接返回，作为 editor.js 中的 text/data/code 等字段
  defp parse_content(content) when is_binary(content) do
    content
  end

  #  TODO:  editor.js 暂时不支持 del 标签，所以直接返回字符串内容即可
  defp parse_content({"del", [], [content]}) do
    content
  end

  defp parse_content(_type, content) when is_binary(content) do
    content
  end

  defp parse_content(type, {_type, _opt, [content]})
       when type in @supported_header do
    parse_content(content)
  end

  # defp parse_content({type, _opt, content})
  #      when type == "h1" or type == "h2" or type == "h3" do
  #     content
  # end
end
