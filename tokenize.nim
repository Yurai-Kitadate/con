import global
import sequtils
import strutils
import strformat
proc new_token(kind : TokenKind,cur : var ref Token,str : string) : ref Token = 
  var tok = Token.new
  tok[].kind = kind
  tok[].str = str
  tok[].len = len(str)
  cur[].next = tok
  return tok

proc isspace(c : char) : bool = 
  return c == ' '

proc strtol(p : string) : int = 
  var res = ""
  while now_reading < len(p) and '1' <= p[now_reading] and p[now_reading] <= '9':
    res &= p[now_reading]
    now_reading += 1
  return res.parseInt

proc startWith(op : string,p:string) : bool =
  var res = ""
  var now = now_reading
  while now < len(p) and len(res) < len(op):
    if isspace(p[now]):
      now += 1
      continue
    res &= p[now]
    now += 1
  return res == op
proc isIn(p: string,op : char):bool = 
  return op in p

proc tokenize*(p : string) : ref Token = 
  var head = Token.new
  head[].next = nil
  var cur = head
  while now_reading < len(p):
    if isspace(p[now_reading]):
      now_reading += 1
      continue
    if startWith("==",p) or startWith("<=",p) or startWith(">=",p) or startWith("!=",p):
      cur = new_token(TK_RESERVED,cur,p[now_reading] & p[now_reading + 1])
      now_reading += 2
      continue
    if isIn("+-*/()<>",p[now_reading]):
      cur = new_token(TK_RESERVED,cur,$p[now_reading])
      now_reading += 1
      continue
    if isdigit(p[now_reading]):
      cur = new_token(TK_NUM,cur,$p[now_reading])
      cur[].val = strtol(p)
      continue
    raiseAssert("cannot tokenize")
  return head[].next

