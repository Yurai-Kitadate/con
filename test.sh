assert() {
    expected="$1"
    input="$2"
    echo "$input" >input_file
    nim c -r -w:off --hints:off --opt:size -d:release --gc:none --stackTrace:on main.nim <input_file >tmp.s
    docker exec -i ubuntu_compiler /bin/bash -c "cd /home/con && cc -o tmp tmp.s && ./tmp"
    actual=$(echo $?)

    if [ "$actual" = "$expected" ]; then
        echo "$input => $actual"
    else
        echo "$input => $expected expected, but got $actual"
        exit 1
    fi
}

assert 57 'a = 2;for (i = 0;i < 10;i = i + 1){a = a + i;a = a + 1;}return a;'
assert 4 'a = 0;for (i = 0;i < 10;i = i + 1) if (i < 5) a = a + 1;return 4;'
assert 47 'b = 2;for (i = 0;i < 10;i = i + 1) b = b + i;return b;'
assert 52 'a = 2;if(a == 3)return 1;else return 52;'
assert 52 'a = 2;if(a == 3)return 1;else if (a == 3) return 2;else return 52;'
assert 8 'a = 3;b = 3;c = 8;return c;a = a + 1;abc = a*b*c;abc;'
assert 12 'a = 1;b = 2;c = 3;if(a*b*c == 6)a = a + 1;return a*b*c;'
echo OK
