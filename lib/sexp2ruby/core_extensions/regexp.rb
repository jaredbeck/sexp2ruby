# Original comment from Ryan:
#
# > REFACTOR: stolen from ruby_parser
#
# Maybe there's an explanation in ruby_parser?
#
class Regexp
  unless defined? ENC_NONE then
    ENC_NONE = /x/n.options
    ENC_EUC  = /x/e.options
    ENC_SJIS = /x/s.options
    ENC_UTF8 = /x/u.options
  end

  unless defined? CODES then
    CODES = {
      EXTENDED   => 'x',
      IGNORECASE => 'i',
      MULTILINE  => 'm',
      ENC_NONE   => 'n',
      ENC_EUC    => 'e',
      ENC_SJIS   => 's',
      ENC_UTF8   => 'u',
    }
  end
end
