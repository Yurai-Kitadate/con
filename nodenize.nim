import global

proc memcmp(str: string, op: string): bool =
  var res = true
  var i = 0
  for s in op:
    if s != str[i]:
      res = false
    i += 1
  return res

proc consume(op: string): bool =
  if token == nil or token[].kind != TK_RESERVED or op.len != token[].len or (
      not memcmp(token[].str, op)):
    return false
  token = token[].next
  return true

proc consume_keyword_t(kind: TokenKind): ref Token =
  if token == nil or token[].kind != kind:
    return nil
  var tok = token
  token = token[].next
  return tok

proc consume_keyword(kind: TokenKind): bool =
  if token == nil or token[].kind != kind:
    return false
  token = token[].next
  return true

proc expect(op: string) =
  if token == nil or token[].kind != TK_RESERVED or op.len != token[].len or (
      not memcmp(token[].str, op)):
    raiseAssert("unexpected character")
  token = token.next

proc expect_number(): int =
  if token[].kind != TK_NUM:
    raiseAssert("not number!!")
  var val = token[].val
  token = token[].next
  return val

#prototype
proc mul(): ref Node
proc expr*(): ref Node
proc primary(): ref Node
proc unary(): ref Node
proc equality(): ref Node
proc relational(): ref Node
proc add(): ref Node
proc stmt(): ref Node
proc program*()
proc assign(): ref Node
proc find_lvar(tok: ref Token): ref LVar
proc fun(): ref Node
proc def_variable(tok: ref Token): ref Node
proc val_variable(tok: ref Token): ref Node

proc new_node(kind: NodeKind, lhs: ref Node, rhs: ref Node): ref Node =
  var node = Node.new
  node[].kind = kind
  node[].lhs = lhs
  node[].rhs = rhs
  return node

proc new_node_num(val: int): ref Node =
  var node = Node.new
  node[].kind = ND_NUM
  node[].val = val
  return node

proc program*() =
  var i = 0
  while token != nil:
    code[i] = fun()
    i += 1
  code[i] = nil


proc fun(): ref Node =
  if consume_keyword_t(TK_DEFUN) == nil:
    raiseAssert("defun not found")
  fun_count += 1
  var tok = consume_keyword_t(TK_IDENT)
  if tok == nil:
    raiseAssert("not fun!")
  var node = Node.new
  node[].kind = ND_DEF_FUN
  node[].fun_name = tok[].str
  expect("(")
  var i = 0
  while not consume(")"):
    var tok = consume_keyword_t(TK_IDENT)
    if tok != nil:
      node[].args[i] = def_variable(tok)
    if consume(")"):
      break
    expect(",")
    i += 1
  if consume(":"):
    if consume_keyword_t(TK_TYPE) == nil:
      raiseAssert("type not found")
  node[].lhs = stmt()
  return node

proc def_variable(tok: ref Token): ref Node =
  #tokに変数名が入ってる
  var node = Node.new
  node[].kind = ND_ASSIGN
  var lvar_node = Node.new
  var lvar = find_lvar(tok)
  if lvar != nil:
    raiseAssert("redefinition of variable")
  lvar = LVar.new
  lvar[].next = local_variables[fun_count]
  lvar[].name = tok[].str
  lvar[].len = tok[].len
  if local_variables[fun_count] == nil:
    lvar[].offset = 8
  else:
    lvar[].offset = local_variables[fun_count][].offset + 8
  lvar_node[].kind = ND_LVAR
  lvar_node[].offset = lvar[].offset
  node[].lhs = lvar_node
  expect(":")
  if consume_keyword_t(TK_TYPE) == nil:
    raiseAssert("type not found")
  if consume("="):
    node[].rhs = expr()

  local_variables[fun_count] = lvar
  return node

proc val_variable(tok: ref Token): ref Node =
  var node = Node.new
  node[].kind = ND_LVAR
  var lvar = find_lvar(tok)
  if lvar == nil:
    raiseAssert("undefined variable")
  node[].offset = lvar[].offset
  return node

proc add(): ref Node =
  var node = mul()
  while true:
    if consume("+"):
      node = new_node(ND_ADD, node, mul())
    elif consume("-"):
      node = new_node(ND_SUB, node, mul())
    else:
      return node

proc mul(): ref Node =
  var node = unary()
  while true:
    if consume("*"):
      node = new_node(ND_MUL, node, unary())
    elif consume("/"):
      node = new_node(ND_DIV, node, unary())
    else:
      return node

proc expr(): ref Node =
  return assign()

proc stmt(): ref Node =
  var node = Node.new
  if consume_keyword_t(TK_DEF) != nil:
    var tok = consume_keyword_t(TK_IDENT)
    node = def_variable(tok) #LVAR
    expect(";")
    return node
  if consume("{"):
    var stmts: array[0..100, ref Node]
    var i = 0
    while not consume("}"):
      stmts[i] = stmt()
      i += 1
    node[].stmts = stmts
    node[].kind = ND_BLOCK
    return node
  if consume_keyword(TK_FOR):
    expect("(")
    var lhs = Node.new
    var rhs = Node.new
    if not consume(";"):
      lhs[].lhs = expr()
      expect(";")
    if not consume(";"):
      lhs[].rhs = expr()
      expect(";")
    if not consume(")"):
      rhs[].lhs = expr()
      expect(")")
    rhs[].rhs = stmt()
    node[].kind = ND_FOR
    node[].lhs = lhs
    node[].rhs = rhs
    return node

  if consume_keyword(TK_IF):
    node[].kind = ND_IF
    expect("(")
    node[].lhs = expr()
    expect(")")
    node[].rhs = stmt()
    if consume_keyword(TK_ELSE):
      var node_else = Node.new
      node_else[].kind = ND_ELSE
      node_else[].lhs = node[].rhs
      node_else[].rhs = stmt()
      node[].rhs = node_else
    return node

  if consume_keyword(TK_RETURN):
    node[].kind = ND_RETURN
    node[].lhs = expr()
  else:
    node = expr()
  expect(";")
  return node

proc primary(): ref Node =
  if consume("("):
    var node = expr()
    expect(")")
    return node
  var tok = consume_keyword_t(TK_IDENT)
  if tok != nil:
    if consume("("):
      var node = Node.new
      node[].kind = ND_CALL_FUN
      node[].fun_name = tok[].str
      var i = 0
      while not consume(")"):
        node[].stmts[i] = expr()
        if consume(")"):
          break
        expect(",")
        i += 1
      return node
    return val_variable(tok)
  return new_node_num(expect_number())

proc equality(): ref Node =
  var node = relational()

  while true:
    if consume("=="):
      node = new_node(ND_EQ, node, relational())
    elif consume("!="):
      node = new_node(ND_NE, node, relational())
    else:
      return node

proc relational(): ref Node =
  var node = add()

  while true:
    if consume("<"):
      node = new_node(ND_LT, node, add())
    elif consume("<="):
      node = new_node(ND_LE, node, add())
    elif consume(">"):
      node = new_node(ND_LT, add(), node)
    elif consume(">="):
      node = new_node(ND_LE, add(), node)
    else:
      return node

proc unary(): ref Node =
  if consume("+"):
    return primary()
  if consume("-"):
    return new_node(ND_SUB, new_node_num(0), primary())
  return primary()

proc assign(): ref Node =
  var node = equality()
  if consume("="):
    node = new_node(ND_ASSIGN, node, assign())
  return node

proc find_lvar(tok: ref Token): ref LVar =
  var val = local_variables[fun_count]
  while val != nil:
    if val[].len == tok[].len and memcmp(tok[].str, val[].name):
      return val
    val = val[].next
  return nil
