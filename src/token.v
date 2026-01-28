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
	plus_plus     // ++
	minus_minus   // --

	// Literals
	identifier
	string
	string_interp_start  // "Hello ${" - opening part before first interpolation
	string_interp_middle // "} world ${" - middle part between interpolations
	string_interp_end    // "}" - closing part after last interpolation
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
	let_keyword
	struct_keyword
	enum_keyword
	match_keyword
	try_keyword
	catch_keyword
	import_keyword
	async_keyword
	await_keyword
	and_keyword
	or_keyword
	ampersand_ampersand // &&
	pipe_pipe           // ||

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
	col     int
}

fn (t Token) str() string {
	return '${t.type_} ${t.lexeme} ${t.literal}'
}
