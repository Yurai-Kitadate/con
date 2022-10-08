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

#condegen
proc gen_lval(node: ref Node) =
  if node[].kind != ND_LVAR:
    raiseAssert("left is not variable")
  printf("  mov rax, rbp\n")
  printf("  sub rax, %d\n", node[].offset)
  printf("  push rax\n")

proc gen*(node: ref Node) =
  if node == nil:
    return
  jmp_count += 1
  var jmp_id = jmp_count
  var arg_count = 0
  if node[].kind == ND_CALL_FUN:
    var i = 0
    while node[].stmts[i] != nil:
      gen(node[].stmts[i])
      arg_count += 1
      i += 1
    i = arg_count - 1
    while i >= 0:
      printf("  pop %s\n", arg_register[i])
      i -= 1
    printf("  mov rax, rsp\n")
    printf("  and rax, 15\n")
    printf("  jnz .L.call.%d\n", jmp_id)
    printf("  mov rax, 0\n")
    printf("  call %s\n", node[].fun_name)
    printf("  jmp .L.end.%d\n", jmp_id)
    printf(".L.call.%d:\n", jmp_id);
    printf("  sub rsp, 8\n");
    printf("  mov rax, 0\n")
    printf("  call %s\n", node[].fun_name)
    printf("  add rsp, 8\n")
    printf(".L.end.%d:\n", jmp_id)
    printf("  push rax\n")
    return
  if node[].kind == ND_DEF_FUN:
    printf("%s:\n", node[].fun_name)
    printf("  push rbp\n")
    printf("  mov rbp, rsp\n")
    var i = 0
    while node[].args[i] != nil:
      printf("  push %s\n", arg_register[i])
      arg_count += 1
      i += 1
    if local_variables[fun_count] != nil:
      var offset = local_variables[fun_count].offset
      offset -= arg_count * 8
      printf("  sub rsp, %d\n", offset)

    gen(node[].lhs)
    printf("  mov rax, 0\n")
    printf("  mov rsp, rbp\n")
    printf("  pop rbp\n")
    printf("  ret\n")
    return
  if node[].kind == ND_BLOCK:
    var i = 0
    while node[].stmts[i] != nil:
      gen(node[].stmts[i])
      i += 1
    return
  if node[].kind == ND_FOR:
    if node[].lhs.lhs != nil:
      gen(node[].lhs.lhs)
    printf(".Lbegin%d:\n", jmp_id)
    if node[].lhs.rhs != nil:
      gen(node[].lhs.rhs)
    printf("  pop rax\n")
    printf("  cmp rax, 0\n")
    printf("  je  .Lend%d\n", jmp_id)
    gen(node[].rhs.rhs)
    if node[].rhs.lhs != nil:
      gen(node[].rhs.lhs)
    printf("  jmp .Lbegin%d\n", jmp_id)
    printf(".Lend%d:\n", jmp_id)
    return
  if node[].kind == ND_IF:
    gen(node[].lhs)
    printf("  pop rax\n")
    printf("  cmp rax, 0\n")
    if node[].rhs.kind == ND_ELSE:
      printf("  je .Lelse%d\n", jmp_id)
      gen(node[].rhs[].lhs)
      printf("  jmp .Lend%d\n", jmp_id)
      printf(".Lelse%d:\n", jmp_id)
      gen(node[].rhs[].rhs)
      printf(".Lend%d:\n", jmp_id)
      return
    else:
      printf("  je .Lend%d\n", jmp_id)
      gen(node[].rhs)
      printf(".Lend%d:\n", jmp_id)
      return
  if node[].kind == ND_RETURN:
    gen(node[].lhs)
    printf("  pop rax\n")
    printf("  mov rsp, rbp\n")
    printf("  pop rbp\n")
    printf("  ret\n")
    return
  if node[].kind == ND_NUM:
    printf("  push %d\n", node[].val)
    return
  if node[].kind == ND_LVAR:
    gen_lval(node)
    printf("  pop rax\n")
    printf("  mov rax, [rax]\n")
    printf("  push rax\n")
    return
  if node[].kind == ND_ASSIGN:
    gen_lval(node[].lhs)
    gen(node[].rhs)
    printf("  pop rdi\n")
    printf("  pop rax\n")
    printf("  mov [rax], rdi\n")
    printf("  push rdi\n")
    return
  gen(node[].lhs)
  gen(node[].rhs)
  printf("  pop rdi\n")
  printf("  pop rax\n")
  case node[].kind
  of ND_NUM:
    return
  of ND_ADD:
    printf("  add rax, rdi\n")
  of ND_SUB:
    printf("  sub rax, rdi\n")
  of ND_MUL:
    printf("  imul rax, rdi\n")
  of ND_DIV:
    printf("  cqo\n")
    printf("  idiv rdi\n")
  of ND_EQ:
    printf("  cmp rax, rdi\n")
    printf("  sete al\n")
    printf("  movzb rax, al\n")
  of ND_NE:
    printf("  cmp rax, rdi\n")
    printf("  setne al\n")
    printf("  movzb rax, al\n")
  of ND_LT:
    printf("  cmp rax, rdi\n")
    printf("  setl al\n")
    printf("  movzb rax, al\n")
  of ND_LE:
    printf("  cmp rax, rdi\n")
    printf("  setle al\n")
    printf("  movzb rax, al\n")
  of ND_LVAR:
    return
  of ND_ASSIGN:
    return
  of ND_RETURN:
    return
  of ND_IF:
    return
  of ND_ELSE:
    return
  of ND_FOR:
    return
  of ND_BLOCK:
    return
  of ND_DEF_FUN:
    return
  of ND_CALL_FUN:
    return
  printf("  push rax\n")
