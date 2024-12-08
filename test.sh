#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

sh crtest.sh
make release
./Famine

cp /tmp/test/ls .

sh crtest.sh

./ls

sleep 2


echo "\n################## TEST 1 ##################\n"

for binary in /tmp/test/*; do
    if [ -x "$binary" ]; then
        
        if strings "$binary" | grep -q 'Famine version 1.0 (c)oded dec-2024 by gemartin-jareste'; then
            echo -e "${GREEN}OK${NC} - $binary"
        else
            echo -e "${RED}KO${NC} - $binary"
        fi
    fi
done

echo "\n################## TEST 2 ##################\n"

for binary in /tmp/test2/*; do
    if [ -x "$binary" ]; then
        
        if strings "$binary" | grep -q 'Famine version 1.0 (c)oded dec-2024 by gemartin-jareste'; then
            echo -e "${GREEN}OK${NC} - $binary"
        else
            echo -e "${RED}KO${NC} - $binary"
        fi
    fi
done

# echo "\n################## TEST 3 ##################\n"

# for binary in /tmp/test3/*; do
#     if [ -x "$binary" ]; then
#       
#         if strings "$binary" | grep -q 'Famine version 1.0 (c)oded dec-2024 by gemartin-jareste'; then
#             echo -e "${GREEN}OK${NC} - $binary"
#         else
#             echo -e "${RED}KO${NC} - $binary"
#         fi
#     fi
# done

# echo "\n################## TEST 4 ##################\n"

# for binary in /tmp/test4/*; do
#     if [ -x "$binary" ]; then
#       
#         if strings "$binary" | grep -q 'Famine version 1.0 (c)oded dec-2024 by gemartin-jareste'; then
#             echo -e "${GREEN}OK${NC} - $binary"
#         else
#             echo -e "${RED}KO${NC} - $binary"
#         fi
#     fi
# done
