use "ponytest"
use "collections"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)
  new make() => None

  fun tag tests(test: PonyTest) =>
    test(_TestParseNumber)
    test(_TestParseString)
    test(_TestParseList)
    test(_TestParseDict)

    test(_TestPrintNumber)
    test(_TestPrintString)
    test(_TestPrintList)
    test(_TestPrintDict)

    test(_TestParsePrint)
    test(_TestConvertToJson)
    test(_TestMalformed)


class iso _TestParseNumber is UnitTest
  fun name(): String => "Bencode/parse.number"

  fun apply(h: TestHelper) ? =>
    let doc: BencodeDoc = BencodeDoc

    doc.parse("i0e")
    h.assert_eq[I64](0, doc.data as I64)

    doc.parse("i13e")
    h.assert_eq[I64](13, doc.data as I64)

    doc.parse("i-13e")
    h.assert_eq[I64](-13, doc.data as I64)


class iso _TestParseString is UnitTest
  fun name(): String => "Bencode/parse.string"

  fun apply(h: TestHelper) ? =>
    let doc: BencodeDoc = BencodeDoc

    doc.parse("0:")
    h.assert_eq[String]("", doc.data as String)

    doc.parse("4:spam")
    h.assert_eq[String]("spam", doc.data as String)

    doc.parse("12:i1234567890e")
    h.assert_eq[String]("i1234567890e", doc.data as String)


class iso _TestParseList is UnitTest
  fun name(): String => "Bencode/parse.list"

  fun apply(h: TestHelper) ? =>
    let doc: BencodeDoc = BencodeDoc

    doc.parse("le")
    h.assert_eq[USize](0, (doc.data as BencodeList).data.size())

    doc.parse("li10e3:foo6:foobari0ee")
    h.assert_eq[USize](4, (doc.data as BencodeList).data.size())
    h.assert_eq[I64](10, (doc.data as BencodeList).data(0) as I64)
    h.assert_eq[String]("foo", (doc.data as BencodeList).data(1) as String)
    h.assert_eq[String]("foobar", (doc.data as BencodeList).data(2) as String)
    h.assert_eq[I64](0, (doc.data as BencodeList).data(3) as I64)

    doc.parse("li0el3:foo3:baree")
    h.assert_eq[USize](2, (doc.data as BencodeList).data.size())
    h.assert_eq[I64](0, (doc.data as BencodeList).data(0) as I64)
    h.assert_eq[USize](2,
      ((doc.data as BencodeList).data(1) as BencodeList).data.size())
    h.assert_eq[String]("foo",
      ((doc.data as BencodeList).data(1) as BencodeList).data(0) as String)
    h.assert_eq[String]("bar",
      ((doc.data as BencodeList).data(1) as BencodeList).data(1) as String)


class iso _TestParseDict is UnitTest
  fun name(): String => "Bencode/parse.dict"

  fun apply(h: TestHelper) ? =>
    let doc: BencodeDoc = BencodeDoc

    doc.parse("de")
    h.assert_eq[USize](0, (doc.data as BencodeDict).data.size())

    doc.parse("d3:fooi0e3:bari1ee")
    h.assert_eq[USize](2, (doc.data as BencodeDict).data.size())
    h.assert_eq[I64](0, (doc.data as BencodeDict).data("foo") as I64)
    h.assert_eq[I64](1, (doc.data as BencodeDict).data("bar") as I64)

    doc.parse("d1:ai7e1:bd0:3:fooee")
    h.assert_eq[USize](2, (doc.data as BencodeDict).data.size())
    h.assert_eq[I64](7, (doc.data as BencodeDict).data("a") as I64)
    h.assert_eq[USize](1,
      ((doc.data as BencodeDict).data("b") as BencodeDict).data.size())
    h.assert_eq[String]("foo",
      ((doc.data as BencodeDict).data("b") as BencodeDict).data("") as String)


class iso _TestPrintNumber is UnitTest
  fun name(): String => "Bencode/print.number"

  fun apply(h: TestHelper) =>
    let doc: BencodeDoc = BencodeDoc

    doc.data = I64(0)
    h.assert_eq[String]("i0e", doc.string())

    doc.data = I64(13)
    h.assert_eq[String]("i13e", doc.string())

    doc.data = I64(-13)
    h.assert_eq[String]("i-13e", doc.string())


class iso _TestPrintString is UnitTest
  fun name(): String => "Bencode/print.string"

  fun apply(h: TestHelper) =>
    let doc: BencodeDoc = BencodeDoc

    doc.data = ""
    h.assert_eq[String]("0:", doc.string())

    doc.data = "foo"
    h.assert_eq[String]("3:foo", doc.string())


class iso _TestPrintList is UnitTest
  fun name(): String => "Bencode/print.list"

  fun apply(h: TestHelper) =>
    let doc: BencodeDoc = BencodeDoc
    let array: BencodeList = BencodeList

    doc.data = array
    h.assert_eq[String]("le", doc.string())

    array.data.clear()
    array.data.push("foo")
    array.data.push(I64(17))
    array.data.push("bar")
    h.assert_eq[String]("l3:fooi17e3:bare", doc.string())

    array.data.clear()
    array.data.push("foo")
    var nested: BencodeList = BencodeList
    nested.data.push(I64(52))
    nested.data.push("foobar")
    array.data.push(nested)
    h.assert_eq[String]("l3:fooli52e6:foobaree", doc.string())


class iso _TestPrintDict is UnitTest
  fun name(): String => "Bencode/print.dict"

  fun apply(h: TestHelper) =>
    let doc: BencodeDoc = BencodeDoc
    let dict: BencodeDict = BencodeDict

    doc.data = dict
    h.assert_eq[String]("de", doc.string())

    dict.data.clear()
    dict.data("foo") = I64(5)
    h.assert_eq[String]("d3:fooi5ee", doc.string())

    dict.data.clear()
    dict.data("a") = "bar"
    dict.data("b") = I64(3)
    h.assert_eq[String]("d1:a3:bar1:bi3ee", doc.string())


class iso _TestParsePrint is UnitTest
  fun name(): String => "Bencode/parseprint"

  fun apply(h: TestHelper) ? =>
    let bencode = "ld9:precision3:ziped4:datalde7:Really?"
      + "3:yesi4eeei47ed3:food3:barld8:aardvarki13eei0eeeee"

    let printed = BencodeDoc
      .>parse(bencode)
      .string()

    h.assert_eq[String](bencode, printed)


class iso _TestConvertToJson is UnitTest
  fun name(): String => "Bencode/converttojson"

  fun apply(h: TestHelper) ? =>
    let bencode = "ld9:precision3:ziped4:datalde7:Really?"
      + "3:yesi4eeei47ed3:food3:barld8:aardvarki13eei0eeeee"
    let json = "[{\"precision\":\"zip\"},{\"data\":[{},"
      + "\"Really?\",\"yes\",4]},47,{\"foo\":{\"bar\":"
      + "[{\"aardvark\":13},0]}}]"

    let printed_json = BencodeDoc
      .>parse(bencode)
      .to_json()
      .string()

    h.assert_eq[String](json, printed_json)


class iso _TestMalformed is UnitTest
  fun name(): String => "Bencode/malformed"

  fun apply(h: TestHelper) =>
    h.assert_error({()? => BencodeDoc.parse("123") })
    h.assert_error({()? => BencodeDoc.parse("abc") })
    h.assert_error({()? => BencodeDoc.parse("ifooe") })
    h.assert_error({()? => BencodeDoc.parse("i123") })
    h.assert_error({()? => BencodeDoc.parse("i--123e") })
    h.assert_error({()? => BencodeDoc.parse("i12abe") })
    h.assert_error({()? => BencodeDoc.parse("4:foo") })
    h.assert_error({()? => BencodeDoc.parse("2:foo") })
    h.assert_error({()? => BencodeDoc.parse("3:bari7e") })
    h.assert_error({()? => BencodeDoc.parse("l3:bar") })
    h.assert_error({()? => BencodeDoc.parse("l3:barei4e") })
    h.assert_error({()? => BencodeDoc.parse("di0e3:fooe") })
    h.assert_error({()? => BencodeDoc.parse("di0ee") })
    h.assert_error({()? => BencodeDoc.parse("d3:fooe") })
