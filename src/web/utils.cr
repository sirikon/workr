module Workr::Web::Utils
  extend self

  ESC_CODE = 27 # \e , \u001b
  BRACKET_CODE = 91 # [ , \u005b
  FINALIZERS = (['A', 'B', 'C', 'D', 'f', 'J', 'K', 'p', 's', 'u', 'm'] of Char)
    .map { |char| char.bytes[0] }
    .sort

  class AnsiFilter
    property possible_ansi_chunk = [] of UInt8

    def filter(string : String) : String
      String.new(filter(string.to_slice), "utf8")
    end

    def filter(bytes : Bytes) : Bytes
      result = [] of UInt8

      i = 0
      while i < bytes.size
        byte = bytes[i]

        # ESC must be the first character
        # And BRACKET must be the second one
        # Except finalizers, all other chars should be stored
        if (@possible_ansi_chunk.size == 0 && byte == ESC_CODE) ||
            (@possible_ansi_chunk.size == 1 && byte == BRACKET_CODE) ||
            (possible_ansi_chunk.size >= 2 && !FINALIZERS.includes?(byte))
          @possible_ansi_chunk << byte
          i += 1
          next
        end

        # If the possible ansi chunk has both ESC and BRACKET, means
        # that we have an ansi code here, no matter what.
        # If the current byte is a finalizer, clear the possible ansi chunk
        # bytes, as those can be discarded.
        if @possible_ansi_chunk.size >= 2 && FINALIZERS.includes?(byte)
          @possible_ansi_chunk.clear
          i += 1
          next
        end

        # Having the possible ansi chunk with size 1 (ESC)
        # And another character that it's NOT BRACKET, means that
        # we failed the assumption of it being an ANSI escape code,
        # so the possible ansi chunk must be written to the result.
        if @possible_ansi_chunk.size == 1 && byte != BRACKET_CODE
          @possible_ansi_chunk.each do |b|
            result << b
          end
          @possible_ansi_chunk.clear
        end

        result << byte
        i += 1
      end

      final_slice = Slice(UInt8).new(result.size)
      y = 0
      while y < result.size
        final_slice[y] = result[y]
        y += 1
      end
      return final_slice
    end
  end

  def ansi_filter(data)
    AnsiFilter.new.filter(data)
  end
end
