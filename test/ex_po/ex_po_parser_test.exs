defmodule ExPo.PoParserTest do
  use ExUnit.Case, async: true
  alias ExPo.PoParser
  alias ExPo.PoTranslation

  test "parses references correctly" do
    po_contents = """
    #: lib/filename.ex:14
    """

    assert PoParser.parse_reference(po_contents) == [
             file: "lib/filename.ex",
             line: 14
           ]
  end

  test "parses a single translation from a PO file" do
    po_contents = """
    #  translator-comments…
    #. extracted-comments…
    #: lib/my_file.ex:45
    #, flag…
    #| msgid previous-untranslated-string
    msgctxt "context-for-message"
    msgid "untranslated-string"
    msgstr "translated-string"
    """

    expected = %PoTranslation{
      comment: "extracted-comments…",
      context: "context-for-message",
      domain: nil,
      file: "lib/my_file.ex",
      flag: "flag…",
      line: 45,
      module: nil,
      string: "untranslated-string",
      translated: "translated-string",
      plurals: nil
    }

    assert PoParser.parse_single_translation(po_contents) == expected
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
    msgid "untranslated-string2"
    msgstr "translated-string2"
    """

    expected = [
      %PoTranslation{
        comment: "extracted-comments1",
        context: "context-for-message1",
        domain: nil,
        file: "lib/my_file1.ex",
        flag: "flag1",
        line: 1,
        module: nil,
        string: "untranslated-string1",
        translated: "translated-string1",
        plurals: nil
      },
      %PoTranslation{
        comment: "extracted-comments2",
        context: "context-for-message2",
        domain: nil,
        file: "lib/my_file2.ex",
        flag: "flag2",
        line: 2,
        module: nil,
        string: "untranslated-string2",
        translated: "translated-string2",
        plurals: nil
      }
    ]

    assert PoParser.parse_translations(po_contents) == expected
  end
end
