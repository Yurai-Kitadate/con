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

assert 18 'int add(int a,int b){return a + b;} int seki(int a,int b){return a*b;} int main(){return add(1,2)*seki(2,3);}'
#assert 10 'int main(){return a;}'
echo OK
