import global
import tokenize
import codegen
import sequtils
import strutils
import strformat
token = tokenize(input)
var node = expr()

printf(".intel_syntax noprefix\n")
printf(".globl main\n")
printf("main:\n")

gen(node)

printf("  pop rax\n")
printf("  ret\n")
        