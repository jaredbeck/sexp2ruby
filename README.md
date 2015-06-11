sexp2ruby
=========

[![Build Status][5]][6] [![Code Climate][7]][8]

`sexp2ruby` generates ruby from RubyParser S-expressions.
It is a fork of [ruby2ruby][1] with slightly different goals.

- Follows [ruby-style-guide][3] where possible
- Prefers OO design over performance
- Drops support for ruby 1.8.7
- Depends on (a small subset of) [activesupport][4]
- Uses bundler instead of hoe
- Uses rspec instead of minitest

Example
-------

```ruby
require 'ruby_parser'
require 'sexp2ruby'

ruby = "def a\n  puts 'A'\nend\n\ndef b\n  a\nend"
sexp = RubyParser.new.process(ruby)
# => s(:block, s(:defn, .. etc.

Sexp2Ruby::Processor.new.process(sexp.deep_clone)
# => "def a\n  puts(\"A\")\nend\ndef b\n  a\nend\n"
```

As with all `SexpProcessor`s, `Sexp2Ruby#process` destroys its input,
so `deep_clone` as shown above if you need to preserve it.

[1]: https://github.com/seattlerb/ruby2ruby
[2]: http://docs.seattlerb.org/ruby2ruby
[3]: https://github.com/bbatsov/ruby-style-guide
[4]: https://rubygems.org/gems/activesupport
[5]: https://travis-ci.org/jaredbeck/sexp2ruby.svg
[6]: https://travis-ci.org/jaredbeck/sexp2ruby
[7]: https://codeclimate.com/github/jaredbeck/sexp2ruby/badges/gpa.svg
[8]: https://codeclimate.com/github/jaredbeck/sexp2ruby
