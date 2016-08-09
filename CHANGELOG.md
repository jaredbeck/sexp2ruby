Change Log
==========

This project follows [semver 2.0.0][1] and the recommendations
of [keepachangelog.com][2].

## 0.0.4

### Breaking Changes

None

### Added

None

### Fixed

- Iter whitespace: an empty body should render as `{}`, not `{ }`.
- A bug where a one-line iter whose call matches no_paren_methods produced
  invalid output. Example: `a B {}` is now `a B do\nend`

## 0.0.3

### Breaking Changes
- Configuration
  - Changed default of `:hash_syntax` from `:ruby18` to `:ruby19`

### Added
- Do not wrap subhash in parentheses
- Configuration
  - Added `:no_paren_methods` omit argument parentheses

## 0.0.2

### Changed
- Normalize block arguments.  See [ruby_parser PR 189][3] (Ryan Davis)

## 0.0.1

Initial version.  Just claiming the gem name.

[1]: http://semver.org/spec/v2.0.0.html
[2]: http://keepachangelog.com/
[3]: https://github.com/seattlerb/ruby_parser/pull/189
