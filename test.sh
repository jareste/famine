make
./famine
cp /tmp/test/ls .
sh crtest.sh
./ls
sleep 1
strings /tmp/test/ls