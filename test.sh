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
assert 7 '2 + 3 - 5 + 7;'
assert 26 '2 + 3*(3 + 15/3);'
assert 105 'a = 2;if (a == 2){a = a + 3;if (a ==4){return 4;}else{a = a + 100;return a;}}'
echo OK
