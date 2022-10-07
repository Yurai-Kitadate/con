con: main.nim

test: con
		./test.sh

clean:
		rm -f tmp* main input*

.PHONY: test clean