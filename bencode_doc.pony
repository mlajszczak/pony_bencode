use "collections"
use "files"
use "json"
use "debug"

class val _Token is Equatable[_Token]
  let _token: (U8 | None)

  new val create(token: U8) =>
    _token = token

  new val eof() =>
    _token = None

  fun eq(that: _Token box): Bool =>
    match _token
    | let c: U8 =>
      match that._token
      | let c': U8 => c == c'
      else
        false
      end
    else
      match that._token
      | None => true
      else
        false
      end
    end

  fun is_digit(): Bool =>
    match _token
    | let c: U8 =>
      (c >= '0') and (c <= '9')
    else
      false
    end

  fun get_char(): U8 ? =>
    _token as U8


class BencodeDoc
  """
  Top level bencode type containing an entire document.
  A bencode document consists of exactly 1 value.
  """
  var data: (BencodeType | None)

  var _source: String = ""
  var _index: USize = 0

  new iso create() =>
    """
    Default constructor building a document containing a single none.
    """
    data = None

  fun string(): String =>
    """
    Generate string representation of this document.
    """
    match data
    | let data': box->BencodeType =>
      let buf = _BencodeUtils._string(data', recover String(256) end)
      buf.compact()
      buf
    else
      ""
    end

  fun to_json(): JsonDoc iso^ =>
    """
    Convert to json
    """
    let json_data = match data
    | let data': this->BencodeType => _BencodeUtils._to_json(data')
    end

    let doc = recover JsonDoc end

    doc.data = consume json_data
    doc

  fun ref parse_file(file_path: FilePath) ? =>
    """
    Parse the given bencoded file, building a document.
    Raise error on invalid bencode in given source.
    """
    let file = File(file_path)
    let content: String = file.read_string(file.size())

    match file.errno()
    | FileOK => None
    else
      error
    end

    parse(content)

  fun ref parse(source: String) ? =>
    """
    Parse the given bencoded string, building a document.
    Raise error on invalid bencode in given source.
    """
    _source = source
    _index = 0

    data = _parse_value()

    if _index < _source.size() then
      error
    end

  fun ref _parse_value(): BencodeType ? =>
    match _peek_token()
    | let c: _Token if c.is_digit() => _parse_string()
    | _Token('i') => _parse_number()
    | _Token('l') => _parse_list()
    | _Token('d') => _parse_dict()
    else
      error
    end

  fun ref _parse_natural(): I64 ? =>
    var value: I64 = 0

    while _peek_token().is_digit() do
      value = (value * 10) + (_peek_token().get_char() - '0').i64()
      _consume_token()
    else
      error
    end

    value

  fun ref _parse_number(): I64 ? =>
    _consume_token()

    var minus = false

    if _peek_token() == _Token('-') then
      minus = true
      _consume_token()
    end

    let int = _parse_natural()

    if _consume_token() != _Token('e') then
      error
    end

    if minus then -int else int end

  fun ref _parse_string(): String ? =>
    let length = _parse_natural()

    if _consume_token() != _Token(':') then
      error
    end

    var buf = recover iso String end

    var i = length
    while i > 0 do
      buf.push(_peek_token().get_char())
      _consume_token()
      i = i - 1
    end

    buf

  fun ref _parse_dict(): BencodeDict ? =>
    _consume_token()

    let dict = Map[String, BencodeType]

    while _peek_token() != _Token('e') do
      let key = _parse_string()
      dict.update(key, _parse_value())
    end
    _consume_token()

    BencodeDict.from_map(dict)

  fun ref _parse_list(): BencodeList ? =>
    _consume_token()

    let array = Array[BencodeType]

    while _peek_token() != _Token('e') do
      array.push(_parse_value())
    end
    _consume_token()

    BencodeList.from_array(array)

  fun _peek_token(): _Token =>
    try
      _Token(_source(_index))
    else
      _Token.eof()
    end

  fun ref _consume_token(): _Token =>
    let token = _peek_token()
    _index = _index + 1
    token
