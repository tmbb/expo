defmodule ExPo.PoParserTest do
  use ExUnit.Case, async: true
  alias ExPo.PoParser
  alias ExPo.Translations.PoTranslation
  # alias ExPo.Translations.PoPluralTranslation

  test "parses references correctly" do
    po_contents = """
    #: lib/filename.ex:14
    """

    # assert PoParser.parse_reference(po_contents) == [
    #          file: "lib/filename.ex",
    #          line: 14
    #        ]
  end

  test "parses a single translation from a PO file" do
    po_contents = """
    #  translator-comments...
    #. extracted-comments...
    #: lib/my_file.ex:45
    #, flag-1...
    #, flag-2...
    #, flag-3...
    #, flag-4...
    #| msgid previous-untranslated-string
    msgctxt "context-for-message"
    msgid ""
    "untranslated-string-line1"
    "untranslated-string-line3"
    msgstr "translated-string"
    """

    # _expected = %PoTranslation{
    #   comment: "extracted-comments…",
    #   context: "context-for-message",
    #   domain: nil,
    #   file: "lib/my_file.ex",
    #   flag: "flag…",
    #   line: 45,
    #   module: nil,
    #   string: "untranslated-string",
    #   translated: "translated-string",
    #   plurals: nil
    # }

    PoParser.parse_translations(po_contents) |> IO.inspect()
  end

  # @tag skip: true
  test "parses a multiple translations from a PO file" do
    po_contents = """
    #  translator-comments1
    #. extracted-comments1
    #: lib/my_file1.ex:1
    #, flag1
    #| msgid previous-untranslated-string1
    msgctxt "context-for-message1"
    msgid "untranslated-string1"
    msgstr "translated-string1"

    #  translator-comments2
    #. extracted-comments2
    #: lib/my_file2.ex:2
    #, flag2
    #| msgid previous-untranslated-string2
    msgctxt "context-for-message2"
    msgid ""
      "untranslated-string2-line1"
      "untranslated-string3-line3"
    msgstr "translated-string2"
    """

    # _expected = [
    #   %PoTranslation{
    #     comment: "extracted-comments1",
    #     context: "context-for-message1",
    #     domain: nil,
    #     file: "lib/my_file1.ex",
    #     flag: "flag1",
    #     line: 1,
    #     module: nil,
    #     string: "untranslated-string1",
    #     translated: "translated-string1",
    #     plurals: nil
    #   },
    #   %PoTranslation{
    #     comment: "extracted-comments2",
    #     context: "context-for-message2",
    #     domain: nil,
    #     file: "lib/my_file2.ex",
    #     flag: "flag2",
    #     line: 2,
    #     module: nil,
    #     string: "untranslated-string2",
    #     translated: "translated-string2",
    #     plurals: nil
    #   }
    # ]

    # assert PoParser.parse_translations(po_contents) |> IO.inspect()
  end
end
