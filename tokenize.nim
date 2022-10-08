import global
import sequtils
import strutils
import strformat
proc new_token(kind: TokenKind, cur: var ref Token, str: string): ref Token =
  var tok = Token.new
  tok[].kind = kind
  tok[].str = str
  tok[].len = str.len
  cur[].next = tok
  cur[].pos = now_reading
  return tok

proc isspace(c: char): bool =
  return c == ' '

proc strtol(): int =
  var res = ""
  while now_reading < p.len and '0' <= p[now_reading] and p[now_reading] <= '9':
    res &= p[now_reading]
    now_reading += 1
    if res == "0":
      return res.parseInt
  return res.parseInt

proc startWith(op: string): bool =
  var res = ""
  var now = now_reading
  while now < p.len and res.len < op.len:
    if isspace(p[now]):
      now += 1
      continue
    res &= p[now]
    now += 1
  return res == op
proc isIn(p: string, op: char): bool =
  return op in p

proc is_alnum(c: char): bool =
  return ('a' <= c and c <= 'z') or ('A' <= c and c <= 'Z') or ('0' <= c and
      c <= '9') or (c == '_')

proc startReserved(op: string, p: string): bool =
  return startWith(op) and now_reading + len(op) + 1 < p.len and (
      not is_alnum(p[now_reading + len(op)]))
proc tokenize*(p: string): ref Token =
  var head = Token.new
  head[].next = nil
  var cur = head
  while now_reading < p.len:
    if isspace(p[now_reading]):
      now_reading += 1
      continue
    if startReserved("int", p):
      cur = new_token(TK_TYPE, cur, "int")
      cur[].len = 3
      now_reading += 3
      continue
    if startReserved("for", p):
      cur = new_token(TK_FOR, cur, "for")
      cur[].len = 3
      now_reading += 3
      continue
    if startReserved("if", p):
      cur = new_token(TK_IF, cur, "if")
      cur[].len = 2
      now_reading += 2
      continue
    if startReserved("else", p):
      cur = new_token(TK_ELSE, cur, "else")
      cur[].len = 4
      now_reading += 4
      continue
    if startReserved("return", p):
      cur = new_token(TK_RETURN, cur, "return")
      cur[].len = 6
      now_reading += 6
      continue
    if 'a' <= p[now_reading] and p[now_reading] <= 'z':
      var abc = ""
      while now_reading < p.len and 'a' <= p[now_reading] and p[now_reading] <= 'z':
        abc &= p[now_reading]
        now_reading += 1
      cur = new_token(TK_IDENT, cur, abc)
      cur[].len = abc.len
      continue
    if startWith("==") or startWith("<=") or startWith(">=") or
        startWith("!="):
      cur = new_token(TK_RESERVED, cur, p[now_reading] & p[now_reading + 1])
      now_reading += 2
      continue
    if isIn("+-*/()<>;={},", p[now_reading]):
      cur = new_token(TK_RESERVED, cur, $p[now_reading])
      now_reading += 1
      continue
    if isdigit(p[now_reading]):
      cur = new_token(TK_NUM, cur, $p[now_reading])
      cur[].val = strtol()
      continue
    var e = "\n\n"
    e &= p & "\n"
    var arrow = ""
    for i in 0..now_reading - 1:
      arrow &= " "
    arrow &= "^" & "\n" & "cannot tokenize: " & p[now_reading] & "\n\n"
    raiseAssert(e & arrow)
  return head[].next
