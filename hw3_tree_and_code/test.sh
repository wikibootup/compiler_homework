touch result.txt
for idx in 1 2 3 4 5 6 7 8 9 10 11 # no bash verison support {1..11}
do
    echo "in test$idx.c" >> result.txt
    echo '```c' >> result.txt
    cat "test$idx.c" >> result.txt
    echo '```' >> result.txt

    echo "$ ./a.out test$idx.c" >> result.txt
    echo '```sh' >> result.txt
    ./a.out "test$idx.c" >> result.txt
    echo '```' >> result.txt
done
