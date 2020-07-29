module Workr::Web::Utils
  extend self

  ESC_CODE = 27 # \e || \u001b
  BRACKET_CODE = 91 # [ || \u005b

  def ansi_filter(data)
    result = String::Builder.new
    i = 0
    while i < data.size
      byte = data.byte_at(i)
      if byte == ESC_CODE
        next_byte = data.byte_at(i + 1)
        if !next_byte.nil? && next_byte.not_nil! == BRACKET_CODE
          ansi_code_end = find_ansi_code_end(data, i + 2)
          i += (ansi_code_end - i + 1)
          next
        end
      end
      result.write_byte(byte)
      i += 1
    end
    result.to_s
  end

  private def find_ansi_code_end(data, start_index)
    ansi_code_finalizers = (['A', 'B', 'C', 'D', 'f', 'J', 'K', 'p', 's', 'u', 'm'] of Char)
      .map { |char| char.bytes[0] }
      .sort
    i = start_index
    while i < data.size
      byte = data.byte_at(i)
      if ansi_code_finalizers.includes?(byte)
        break
      end
      i += 1
    end
    return i
  end
end
