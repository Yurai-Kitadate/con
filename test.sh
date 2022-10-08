assert() {
    expected="$1"
    input="$2"
    echo "$input" >input_file
    nim c -r -w:off --hints:off --opt:size -d:release --threads:on --stackTrace:on --lineTrace:on main.nim <input_file >tmp.s
    docker exec -i ubuntu_compiler /bin/bash -c "cd /home/con && cc -o tmp tmp.s && ./tmp"
    actual=$(echo $?)

    if [ "$actual" = "$expected" ]; then
        echo "$input => $actual"
    else
        echo "$input => $expected expected, but got $actual"
        exit 1
    fi
}
assert 25 'defun seki(a : int,b : int){return a*b;} defun main(){if (1 == 1){def a : int = 0;a = 5;return seki(a,a);}}'
echo OK
