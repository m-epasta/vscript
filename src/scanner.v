// Scanner/Lexer for vscript
module main

struct Scanner {
mut:
	source  string
	tokens  []Token
	start   int
	current int
	line    int
}

fn new_scanner(source string) Scanner {
	return Scanner{
		source:  source
		tokens:  []Token{}
		start:   0
		current: 0
		line:    1
	}
}

fn (mut s Scanner) scan_tokens() []Token {
	for !s.is_at_end() {
		s.start = s.current
		s.scan_token()
	}

	s.tokens << Token{
		type_:   .eof
		lexeme:  ''
		literal: ''
		line:    s.line
	}

	return s.tokens
}

fn (mut s Scanner) scan_token() {
	c := s.advance()

	match c {
		`(` {
			s.add_token(.left_paren)
		}
		`)` {
			s.add_token(.right_paren)
		}
		`{` {
			s.add_token(.left_brace)
		}
		`}` {
			s.add_token(.right_brace)
		}
		`[` {
			s.add_token(.left_bracket)
		}
		`]` {
			s.add_token(.right_bracket)
		}
		`,` {
			s.add_token(.comma)
		}
		`.` {
			s.add_token(.dot)
		}
		`-` {
			s.add_token(.minus)
		}
		`+` {
			s.add_token(.plus)
		}
		`;` {
			s.add_token(.semicolon)
		}
		`*` {
			s.add_token(.star)
		}
		`%` {
			s.add_token(.percent)
		}
		`:` {
			s.add_token(.colon)
		}
		`!` {
			s.add_token(if s.match_char(`=`) { .bang_equal } else { .bang })
		}
		`=` {
			s.add_token(if s.match_char(`=`) { .equal_equal } else { .equal })
		}
		`<` {
			s.add_token(if s.match_char(`=`) { .less_equal } else { .less })
		}
		`>` {
			s.add_token(if s.match_char(`=`) { .greater_equal } else { .greater })
		}
		`/` {
			if s.match_char(`/`) {
				// Single-line comment
				for s.peek() != `\n` && !s.is_at_end() {
					s.advance()
				}
			} else if s.match_char(`*`) {
				// Multi-line comment
				s.block_comment()
			} else {
				s.add_token(.slash)
			}
		}
		` `, `\r`, `\t` {
			// Ignore whitespace
		}
		`\n` {
			// Newline acts as statement separator - insert virtual semicolon
			// Only if the previous token could end a statement
			if s.tokens.len > 0 {
				last_type := s.tokens[s.tokens.len - 1].type_
				if last_type in [.identifier, .number, .string, .right_paren, .right_brace,
					.right_bracket, .true_keyword, .false_keyword, .nil_keyword, .return_keyword] {
					s.add_token(.semicolon)
				}
			}
			s.line++
		}
		`"` {
			s.string()
		}
		else {
			if s.is_digit(c) {
				s.number()
			} else if s.is_alpha(c) {
				s.identifier()
			} else {
				s.error('Unexpected character')
			}
		}
	}
}

fn (mut s Scanner) block_comment() {
	for !s.is_at_end() {
		if s.peek() == `\n` {
			s.line++
		}
		if s.peek() == `*` && s.peek_next() == `/` {
			s.advance() // consume *
			s.advance() // consume /
			return
		}
		s.advance()
	}
	s.error('Unterminated block comment')
}

fn (mut s Scanner) identifier() {
	for s.is_alpha_numeric(s.peek()) {
		s.advance()
	}

	text := s.source[s.start..s.current]
	type_ := s.keyword_type(text)
	s.add_token(type_)
}

fn (s &Scanner) keyword_type(text string) TokenType {
	return match text {
		'fn' { .fn_keyword }
		'if' { .if_keyword }
		'else' { .else_keyword }
		'while' { .while_keyword }
		'for' { .for_keyword }
		'return' { .return_keyword }
		'nil' { .nil_keyword }
		'true' { .true_keyword }
		'false' { .false_keyword }
		'var' { .var_keyword }
		else { .identifier }
	}
}

fn (mut s Scanner) number() {
	for s.is_digit(s.peek()) {
		s.advance()
	}

	// Look for fractional part
	if s.peek() == `.` && s.is_digit(s.peek_next()) {
		s.advance() // consume .

		for s.is_digit(s.peek()) {
			s.advance()
		}
	}

	value := s.source[s.start..s.current]
	s.add_token_literal(.number, value)
}

fn (mut s Scanner) string() {
	mut value := ''
	for s.peek() != `"` && !s.is_at_end() {
		if s.peek() == `\n` {
			s.line++
		}

		if s.peek() == `\\` {
			s.advance() // consume \
			match s.advance() {
				`n` { value += '\n' }
				`t` { value += '\t' }
				`r` { value += '\r' }
				`\\` { value += '\\' }
				`"` { value += '"' }
				else { s.error('Invalid escape sequence') }
			}
		} else {
			value += s.advance().ascii_str()
		}
	}

	if s.is_at_end() {
		s.error('Unterminated string')
		return
	}

	s.advance() // closing "
	s.add_token_literal(.string, value)
}

fn (mut s Scanner) match_char(expected u8) bool {
	if s.is_at_end() {
		return false
	}
	if s.source[s.current] != expected {
		return false
	}
	s.current++
	return true
}

fn (s &Scanner) peek() u8 {
	if s.is_at_end() {
		return 0
	}
	return s.source[s.current]
}

fn (s &Scanner) peek_next() u8 {
	if s.current + 1 >= s.source.len {
		return 0
	}
	return s.source[s.current + 1]
}

fn (s &Scanner) is_alpha(c u8) bool {
	return (c >= `a` && c <= `z`) || (c >= `A` && c <= `Z`) || c == `_`
}

fn (s &Scanner) is_digit(c u8) bool {
	return c >= `0` && c <= `9`
}

fn (s &Scanner) is_alpha_numeric(c u8) bool {
	return s.is_alpha(c) || s.is_digit(c)
}

fn (s &Scanner) is_at_end() bool {
	return s.current >= s.source.len
}

fn (mut s Scanner) advance() u8 {
	c := s.source[s.current]
	s.current++
	return c
}

fn (mut s Scanner) add_token(type_ TokenType) {
	s.add_token_literal(type_, '')
}

fn (mut s Scanner) add_token_literal(type_ TokenType, literal string) {
	text := s.source[s.start..s.current]
	s.tokens << Token{
		type_:   type_
		lexeme:  text
		literal: literal
		line:    s.line
	}
}

fn (mut s Scanner) error(message string) {
	eprintln('[line ${s.line}] Error: ${message}')
}
