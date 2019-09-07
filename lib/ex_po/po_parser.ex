defmodule ExPo.PoParser do
  @moduledoc false
  import NimbleParsec
  alias ExPo.Translations.PoTranslation

  #  The format of an entry in a `.po` file is the following:
  #
  #     white-space
  #     #  translator-comments
  #     #. extracted-comments
  #     #: reference…
  #     #, flag…
  #     #| msgid previous-untranslated-string
  #     msgid untranslated-string
  #     msgstr translated-string
  #
  def merge_lines(lines) do
    lines
    |> Enum.intersperse("\n")
    |> List.to_string()
  end

  def make_string(parts) do
    List.to_string(parts)
  end

  def maybe_unwrap({key, [value]}) when is_list(value), do: {key, value}
  def maybe_unwrap(pair), do: pair

  def to_translation(keywords) do
    case Keyword.has_key?(keywords, :msgid_plural) do
      true ->
        PoPluralTranslation.new(keywords)

      false ->
        PoTranslation.new(keywords)
    end
  end

  def make_translation(_rest, parts, context, {line, _what?}, _offset) do
    translation =
      parts
      |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
      |> Enum.map(&maybe_unwrap/1)
      |> Keyword.put(:po_source_line, line)
      |> to_translation()

    {[translation], context}
  end

  newline =
    choice([
      ascii_char([?\n]),
      eos()
    ])

  line = times(utf8_char(not: ?\n), min: 1) |> ignore(newline)

  whitespace_chars = [?\s, ?\t, ?\f]

  whitespace = repeat(ascii_char(whitespace_chars))

  # TODO: extend to multiline strings
  text =
    ignore(ascii_char([?"]))
    |> repeat(
      choice([
        replace(string(~S[\"]), ?"),
        utf8_char(not: ?")
      ])
    )
    |> ignore(ascii_char([?"]))
    |> reduce(:make_string)

  line_comment = fn marker, tag ->
    marker
    |> optional(ascii_char([?\s]))
    |> ignore()
    |> wrap(line)
    |> times(min: 1)
    |> tag(tag)
  end

  text_field = fn marker, tag ->
    marker
    |> concat(whitespace)
    |> ignore()
    |> times(text |> ignore(whitespace) |> ignore(newline), min: 1)
    |> tag(tag)
  end

  blank_line = whitespace |> concat(ascii_char([?\n]))
  blank_lines = repeat(blank_line)

  integer =
    ascii_string([?0..?9], min: 1)
    |> map({String, :to_integer, []})

  reference =
    string("#:")
    |> concat(whitespace)
    |> ignore()
    # Won't be ignored:
    |> utf8_string([not: ?:, not: ?\n], min: 1)
    |> ignore(string(":"))
    # Won't be ignored:
    |> concat(integer)
    |> ignore(whitespace |> concat(newline))
    |> reduce({List, :to_tuple, []})
    |> unwrap_and_tag(:references)

  extracted_comments = line_comment.(string("#."), :comments)
  msgid_untranslated_string = line_comment.(string("#|"), :msgid_untranslated)
  flag = line_comment.(string("#,"), :flags)

  msgid = text_field.(string("msgid"), :msgid)
  msgstr = text_field.(string("msgstr"), :msgtr)
  msgctxt = text_field.(string("msgctxt"), :msgctxt)

  specific_comments = [
    reference,
    extracted_comments,
    msgid_untranslated_string,
    flag
  ]

  translator_comments_marker =
    choice([
      string("#:"),
      string("#."),
      string("#,"),
      string("#|")
    ])
    |> lookahead_not()
    |> string("#")

  translator_comments = line_comment.(translator_comments_marker, :translator_comments)

  comment = choice([translator_comments | specific_comments])

  text_fields =
    optional(msgctxt)
    |> concat(msgid)
    |> concat(msgstr)

  translation =
    repeat(comment)
    |> concat(text_fields)
    |> ignore(blank_lines)
    # We need `pre_traverse` because we need the location
    # at the beginning of the translation and not at the end
    |> pre_traverse(:make_translation)

  translations =
    blank_lines
    |> optional()
    |> ignore()
    |> repeat(translation)

  defparsecp(:translation, translation)
  defparsecp(:reference, reference)
  defparsecp(:translations, translations)

  @doc false
  def parse_reference(text) do
    {:ok, reference, _, _, _, _} = reference(text)
    reference
  end

  @doc false
  def parse_single_translation(text) do
    {:ok, [translation], _, _, _, _} = translation(text)
    translation
  end

  @doc false
  def parse_translations(text) do
    {:ok, translations, _, _, _, _} = translations(text)
    translations
  end
end
