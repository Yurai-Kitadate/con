# con compiler

## Nimで書かれたコンパイラです。
- https://www.sigbus.info/compilerbook#dynamic-linking を読みながら作ってます。
- Nimの勉強も兼ねて書いています。変な書き方してるかも...
- どんな感じの文法にするかは決めてないです。

## ファイル分割
### main.nim
- 以下のファイルの関数を呼び出します。
### tokenize.nim
- 標準入力を意味のある単位tokenに分割します。
### nodenize.nim
- tokenを構文木nodeに変換します。
### codegen.nim
- 実際に構文木に従ってintel記法のアセンブリを出力します。
### global.nim
- ファイルで用いるグローバル変数や構造体などを宣言しています。
## 勉強メモ