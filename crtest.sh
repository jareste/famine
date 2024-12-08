#!/bin/bash

setup_test_dir() {
    local dir=$1
    mkdir -p "$dir/folder222"
    touch "$dir/fooooooo"
    cp tests/hello_c "$dir/."
    cp /bin/ls "$dir/."
    cp /bin/cat "$dir/."
    cp /bin/touch "$dir/."
    cp /bin/mkdir "$dir/."
    cp /bin/rm "$dir/."
    cp /bin/cp "$dir/."
    cp /bin/mv "$dir/."
    cp /bin/echo "$dir/."
    cp /bin/ln "$dir/."
    cp /bin/ps "$dir/."
    cp /bin/pwd "$dir/."
    cp /bin/kill "$dir/."
    cp /bin/hostname "$dir/."
}

cc tests/hello.c -o tests/hello

rm -rf "/tmp/test"
mkdir "/tmp/test"
setup_test_dir "/tmp/test"
echo "Created /tmp/test"

for i in $(seq 2 4); do
    rm -rf "/tmp/test$i"
    mkdir "/tmp/test$i"
    setup_test_dir "/tmp/test$i"
    echo "Created /tmp/test$i"
done
