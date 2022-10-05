con: con.nim

test: con
		./test.sh

clean:
		rm -f tmp* con input*

.PHONY: test clean