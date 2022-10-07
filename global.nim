type TokenKind* = enum
  TK_NUM
  TK_RESERVED
  TK_EOF

type Token* = object
  kind* : TokenKind
  next* : ref Token
  val*  : int
  str*  : string
  len*  : int
proc printf*(frmt: cstring): cint {.importc: "printf", header: "<stdio.h>", varargs, discardable.}
var token* = Token.new
let input* = stdin.readLine
var now_reading* = 0
var now_reading_token* = 0