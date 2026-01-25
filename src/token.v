// Token types for vscript language
module main

enum TokenType {
	// Single-character tokens
	left_paren    // (
	right_paren   // )
	left_brace    // {
	right_brace   // }
	left_bracket  // [
	right_bracket // ]
	comma         // ,
	dot           // .
	minus         // -
	plus          // +
	semicolon     // ;
	slash         // /
	star          // *
	percent       // %
	colon         // :

	// One or two character tokens
	bang          // !
	bang_equal    // !=
	equal         // =
	equal_equal   // ==
	greater       // >
	greater_equal // >=
	less          // <
	less_equal    // <=

	// Literals
	identifier
	string
	number

	// Keywords
	fn_keyword
	class_keyword
	this_keyword
	if_keyword
	else_keyword
	while_keyword
	for_keyword
	return_keyword
	nil_keyword
	true_keyword
	false_keyword
	var_keyword
	struct_keyword
	enum_keyword
	match_keyword

	// Special
	at_bracket // @[
	fat_arrow  // =>
	eof
	error
}

struct Token {
	type_   TokenType
	lexeme  string
	literal string
	line    int
}

fn (t Token) str() string {
	return '${t.type_} ${t.lexeme} ${t.literal}'
}
