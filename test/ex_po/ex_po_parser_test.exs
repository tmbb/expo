defmodule ExPo.PoParserTest do
  use ExUnit.Case, async: true
  alias ExPo.PoParser
  alias ExPo.Translations.PoTranslation
  alias ExPo.Translations.PoPluralTranslation

  test "parses references correctly" do
    po_contents = """
    #: lib/filename.ex:14
    """

    assert PoParser.parse_reference(po_contents) == [
             references: {"lib/filename.ex", 14}
           ]
  end

  test "parses a single plural translation from a PO file" do
    po_contents = """
    msgid "untranslated-string-line"
    msgid_plural "untranslated-string-lines"
    msgstr[0] "plural-0"
    msgstr[1] "plural-1"
    msgstr[2] "plural-2"
    """

    expected = %PoPluralTranslation{
      comments: [],
      extracted_comments: [],
      flags: MapSet.new(),
      msgctxt: nil,
      msgid: ["untranslated-string-line"],
      msgid_plural: ["untranslated-string-lines"],
      msgstr: %{0 => "plural-0", 1 => "plural-1", 2 => "plural-2"},
      po_source_line: 1,
      references: []
    }

    assert PoParser.parse_single_translation(po_contents) == expected
  end

  test "parses a single translation from a PO file" do
    po_contents = """
    # translator-comments...
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

    expected = %PoTranslation{
      comments: ["translator-comments..."],
      extracted_comments: ["extracted-comments..."],
      flags: MapSet.new(["flag-1...", "flag-2...", "flag-3...", "flag-4..."]),
      msgctxt: ["context-for-message"],
      msgid: ["", "untranslated-string-line1", "untranslated-string-line3"],
      msgstr: nil,
      po_source_line: 1,
      references: [{"lib/my_file.ex", 45}]
    }

    assert PoParser.parse_single_translation(po_contents) == expected
  end

  # @tag skip: true
  test "parses a multiple translations from a PO file" do
    po_contents = """
    # translator-comments1
    #. extracted-comments1
    #: lib/my_file1.ex:1
    #, flag1
    #| msgid previous-untranslated-string1
    msgctxt "context-for-message1"
    msgid "untranslated-string1"
    msgstr "translated-string1"

    # translator-comments2
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

    expected = [
      %PoTranslation{
        comments: ["translator-comments1"],
        extracted_comments: ["extracted-comments1"],
        flags: MapSet.new(["flag1"]),
        msgctxt: ["context-for-message1"],
        msgid: ["untranslated-string1"],
        msgstr: nil,
        po_source_line: 1,
        references: [{"lib/my_file1.ex", 1}]
      },
      %PoTranslation{
        comments: ["translator-comments2"],
        extracted_comments: ["extracted-comments2"],
        flags: MapSet.new(["flag2"]),
        msgctxt: ["context-for-message2"],
        msgid: ["", "untranslated-string2-line1", "untranslated-string3-line3"],
        msgstr: nil,
        po_source_line: 10,
        references: [{"lib/my_file2.ex", 2}]
      }
    ]

    assert PoParser.parse_translations(po_contents) == expected
  end
end
