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
assert 3 'int fib(int n){if (n == 0){return 1;} if (n == 1){return 1;} return fib(n - 1) + fib(n - 2);} int main(){return fib(3);}'
assert 8 'int fib(int n){if (n == 0){return 1;} if (n == 1){return 1;} return fib(n - 1) + fib(n - 2);} int main(){return fib(5);}'
#assert 10 'int main(){return a;}'
echo OK
