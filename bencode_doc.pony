use "collections"

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

  fun is_char(): Bool =>
    match _token
    | None => false
    else
      true
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
      let buf = _BencodePrint._string(data', recover String(256) end)
      buf.compact()
      buf
    else
      ""
    end

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

  fun ref _parse_decimal(): I64 ? =>
    var value: I64 = 0

    while _peek_token().is_char() and _peek_token().is_digit() do
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

    let int = _parse_decimal()

    if _consume_token() != _Token('e') then
      error
    end

    if minus then -int else int end

  fun ref _parse_string(): String ? =>
    let length = _parse_decimal()

    if _consume_token() != _Token(':') then
      error
    end

    var buf = recover iso String end

    var i = length
    while i > 0 do
      if _peek_token().is_char() then
          buf.push(_peek_token().get_char())
          _consume_token()
          i = i - 1
      else
        error
      end
    end

    buf

  fun ref _parse_dict(): BencodeDict ? =>
    _consume_token()

    let dict = Map[String, BencodeType]

    while true do
      if _peek_token() == _Token('e') then
        _consume_token()
        break
      end
      let key = _parse_string()
      dict.update(key, _parse_value())
    end

    BencodeDict.from_map(dict)

  fun ref _parse_list(): BencodeList ? =>
    _consume_token()

    let array = Array[BencodeType]

    while true do
      if _peek_token() == _Token('e') then
        _consume_token()
        break
      end
      array.push(_parse_value())
    end

    BencodeList.from_array(array)

  fun _peek_token(): _Token =>
    try
      let c = _source(_index)
      _Token(c)
    else
      _Token.eof()
    end

  fun ref _consume_token(): _Token =>
    let token = _peek_token()
    _index = _index + 1
    token