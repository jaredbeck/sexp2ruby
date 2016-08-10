# sexp2ruby

[![Build Status][5]][6] [![Code Climate][7]][8]

`sexp2ruby` generates ruby from [ruby_parser][10] S-expressions.
It is a [fork][9] of [ruby2ruby][1] with different goals and tools.

- Follows [ruby-style-guide][3] where possible
- Prefers OO design over performance
- Drops support for ruby 1.8.7
- Uses bundler instead of hoe
- Uses rspec instead of minitest
- Depends on (a small subset of) [activesupport][4]

## When to Use ruby2ruby Instead

If you want to use the latest version of [ruby_parser][10], please use
[ruby2ruby][1] instead. Ryan does not often make breaking changes to his
S-expression format, but when he does, ruby2ruby is more likely to keep up
to date. Following the [ruby-style-guide][3] is not a goal of ruby2ruby, so
you may want to use a tool like `rubocop --auto-correct`. In fact, rubocop's
auto-correct is getting so good that it may not make sense to continue working
on this project.

## Example

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

## Configuration

Configure output by passing options to `Sexp2Ruby::Processor.new`:

```ruby
hash = s(:hash, s(:lit, :a), s(:lit, 1))
Sexp2Ruby::Processor.new(hash_syntax: :ruby18).process
# => "{ :a => 1 }"
Sexp2Ruby::Processor.new(hash_syntax: :ruby19).process
# => "{ a: 1 }"
```

- `:hash_syntax` - either `:ruby18` or `:ruby19`. Default is `:ruby19`.
- `:no_paren_methods` - an array of symbols, these methods
  will omit argument parentheses. Default is `[]`.

[1]: https://github.com/seattlerb/ruby2ruby
[2]: http://docs.seattlerb.org/ruby2ruby
[3]: https://github.com/bbatsov/ruby-style-guide
[4]: https://rubygems.org/gems/activesupport
[5]: https://travis-ci.org/jaredbeck/sexp2ruby.svg
[6]: https://travis-ci.org/jaredbeck/sexp2ruby
[7]: https://codeclimate.com/github/jaredbeck/sexp2ruby/badges/gpa.svg
[8]: https://codeclimate.com/github/jaredbeck/sexp2ruby
[9]: https://guides.github.com/activities/forking/
[10]: https://github.com/seattlerb/ruby_parser
