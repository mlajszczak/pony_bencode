use "collections"
use "json"

type BencodeType is (I64 | String | BencodeList | BencodeDict)
  """
  All bencode data types.
  """


class BencodeList
  var data: Array[BencodeType]

  new iso create() =>
    data = Array[BencodeType]

  new from_array(data': Array[BencodeType]) =>
    data = data'

  fun string(): String =>
    """
    Generate string representation of this list.
    """
    let buf = _show(recover String(256) end)
    buf.compact()
    buf

  fun to_json(): JsonArray iso^ =>
    """
    Convert to json
    """
    let array: Array[JsonType] iso = recover Array[JsonType] end

    for v in data.values() do
      array.push(_BencodeUtils._to_json(v))
    end

    recover JsonArray.from_array(consume array) end

  fun _show(buf': String iso): String iso^ =>
    var buf = consume buf'

    buf.push('l')

    for v in data.values() do
      buf = _BencodeUtils._string(v, consume buf)
    end

    buf.push('e')
    buf


class BencodeDict
  var data: Map[String, BencodeType]

  new iso create() =>
    data = Map[String, BencodeType]

  new from_map(data': Map[String, BencodeType]) =>
    data = data'

  fun string(): String =>
    """
    Generate string representation of this dict.
    """
    let buf = _show(recover String(256) end)
    buf.compact()
    buf

  fun to_json(): JsonObject iso^ =>
    """
    Convert to json
    """
    let map = recover Map[String, JsonType] end

    for (k, v) in data.pairs() do
      map(k) = _BencodeUtils._to_json(v)
    end

    recover JsonObject.from_map(consume map) end

  fun _show(buf': String iso): String iso^ =>
    var buf = consume buf'

    buf.push('d')

    let keys = Array[String]
    for key in data.keys() do
      keys.push(key)
    end

    Sort[Array[String], String](keys)

    for key in keys.values() do
      let value = data.get_or_else(key, 0)
      buf = _BencodeUtils._string(key, consume buf)
      buf = _BencodeUtils._string(value, consume buf)
    end

    buf.push('e')
    buf
