primitive _BencodePrint
  fun _string(data: box->BencodeType, buf': String iso): String iso^ =>
    """
    Generate string representation of the given data.
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
