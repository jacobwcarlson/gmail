# -*- ruby -*-

$:.unshift(File.expand_path('../lib', __FILE__))
require 'gmail/version'

Gem::Specification.new do |s|
  s.name = 'gmail'
  s.version = Gmail.version
  s.homepage = 'http://github.com/jacobwcarlson/gmail'
  s.email = ['the.real.jacobwcarlson@gmail.com']
  s.authors = ['BehindLogic', 'Chris Kowalik', 'Jacob W Carlson']
  s.summary = %q{A Rubyesque interface to Gmail, with all the tools you will need.}
  s.description = %q{A Rubyesque interface to Gmail, with all the tools you will need. Search, read and send multipart emails; archive, mark as read/unread, delete emails; and manage labels.}
  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {spec}/*`.split("\n")
  s.require_paths = %w[lib]
  s.extra_rdoc_files = %w[LICENSE README.md CHANGELOG.md TODO.md]

  s.add_runtime_dependency 'mime', ['>= 0.1']
  s.add_runtime_dependency 'mail', ['>= 2.2.1']
  s.add_runtime_dependency 'gmail_xoauth', ['>= 0.3.0']
end
