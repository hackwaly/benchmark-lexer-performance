///|
let keywords : ReadOnlyArray[StringView] = [
  "as", "else", "extern", "fn", "fnalias", "if", "let", "const", "match", "using",
  "mut", "type", "typealias", "struct", "enum", "trait", "traitalias", "derive",
  "while", "break", "continue", "import", "return", "throw", "raise", "try", "catch",
  "pub", "priv", "readonly", "true", "false", "_", "test", "loop", "for", "in", "impl",
  "with", "guard", "async", "is", "suberror", "and", "letrec", "enumview", "noraise",
  "defer",
]

///|
let keyword_set : Set[StringView] = Set::from_array(keywords)

///|
priv enum Token {
  Keyword(StringView)
  Identifier(StringView)
  Number(StringView)
} derive(Show, ToJson)

///|
fn tokenize_two_pass(input : StringView) -> Array[Token] {
  let mut remaining = input
  let tokens = []
  while !remaining.is_empty() {
    lexmatch remaining with longest {
      ("[a-zA-Z_][a-zA-Z_0-9]*" as tok, r) => {
        let token = if keyword_set.contains(tok) {
          Keyword(tok)
        } else {
          Identifier(tok)
        }
        tokens.push(token)
        remaining = r
      }
      ("\d+" as tok, r) => {
        tokens.push(Number(tok))
        remaining = r
      }
      ("\s+", r) => remaining = r
      _ => remaining = try! remaining[1:]
    }
  }
  tokens
}

///|
fn tokenize_one_pass(input : StringView) -> Array[Token] {
  let mut remaining = input
  let tokens = []
  while !remaining.is_empty() {
    lexmatch remaining with longest {
      ("\\_|as|else|extern|fn|fnalias|if|let|const|match|using|mut|type|typealias|struct|enum|trait|traitalias|derive|while|break|continue|import|return|throw|raise|try|catch|pub|priv|readonly|true|false|test|loop|for|in|impl|with|guard|async|is|suberror|and|letrec|enumview|noraise|defer" as tok, r) => {
        tokens.push(Keyword(tok))
        remaining = r
      }
      ("[a-zA-Z_][a-zA-Z_0-9]*" as tok, r) => {
        tokens.push(Identifier(tok))
        remaining = r
      }
      ("\d+" as tok, r) => {
        tokens.push(Number(tok))
        remaining = r
      }
      ("\s+", r) => remaining = r
      _ => remaining = try! remaining[1:]
    }
  }
  tokens
}

///|
test {
  let input = "let priv pub 1323"
  @json.inspect(tokenize_two_pass(input), content=[
    ["Keyword", "let"],
    ["Keyword", "priv"],
    ["Keyword", "pub"],
    ["Number", "1323"],
  ])
  @json.inspect(tokenize_one_pass(input), content=[
    ["Keyword", "let"],
    ["Keyword", "priv"],
    ["Keyword", "pub"],
    ["Number", "1323"],
  ])
}

///|
test (b : @bench.T) {
  let input = "let priv pub 123 ".repeat(1000)
  b.bench(name="one pass", fn() { b.keep(tokenize_one_pass(input)) })
  b.bench(name="two pass", fn() { b.keep(tokenize_two_pass(input)) })
}
