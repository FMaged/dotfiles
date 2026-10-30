;; extends

((plain_scalar
  (string_scalar) @injection.content)
  (#match? @injection.content "\\{[{%]")
  (#set! injection.language "jinja"))

((double_quote_scalar) @injection.content
  (#match? @injection.content "\\{[{%]")
  (#set! injection.language "jinja"))

((single_quote_scalar) @injection.content
  (#match? @injection.content "\\{[{%]")
  (#set! injection.language "jinja"))
