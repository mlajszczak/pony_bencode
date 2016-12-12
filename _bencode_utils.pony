use "json"

primitive _BencodeUtils
  fun _string(data: box->BencodeType, buf': String iso): String iso^ =>
    """
    Generate string representation of the given data
    """
    var buf = consume buf'

    match data
    | let data': I64 =>
      buf.push('i')
      buf.append(data'.string())
      buf.push('e')

    | let data': String =>
      buf.append(data'.size().string())
      buf.push(':')
      buf.append(data')

    | let data': box->BencodeDict =>
      buf = data'._show(consume buf)

    | let data': box->BencodeList =>
      buf = data'._show(consume buf)
    end

    buf

  fun _to_json(data: box->BencodeType): (None | I64 | String | JsonArray iso^ | JsonObject iso^) =>
    """
    Convert the given data to json
    """
    match data
    | let data': I64 => data'
    | let data': String => data'
    | let data': box->BencodeDict => data'.to_json()
    | let data': box->BencodeList => data'.to_json()
    end
