assert() {
    expected="$1"
    input="$2"
    echo "$input" >input_file
    nim c -r -w:off --hints:off --opt:size -d:release main.nim <input_file >tmp.s
    docker exec -i ubuntu_compiler /bin/bash -c "cd /home/con && cc -o tmp tmp.s && ./tmp"
    actual=$(echo $?)

    if [ "$actual" = "$expected" ]; then
        echo "$input => $actual"
    else
        echo "$input => $expected expected, but got $actual"
        exit 1
    fi
}
assert 1 '1 <= 3'
assert 0 '1 > 3'
assert 1 '1 < 3'
assert 1 '1 == 1'
assert 1 '1 <= 1'
assert 3 '- 2 + 3 - 5 + 7'
assert 4 '4'
assert 32 '32'
assert 3 '1+2'
assert 1 '3-2'
assert 26 '2 + 3*(3 + 15/3)'
echo OK
