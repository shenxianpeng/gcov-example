CC	= gcc
CFLAG = -fPIC -fprofile-arcs -ftest-coverage
RM	= rm -rf


main : main.o foo.o
	$(CC) $(CFLAG) -o main main.o foo.o

main.o : main.c
	$(CC) $(CFLAG) -c -Wall -Werror main.c

foo.o : foo.c
	$(CC) $(CFLAG) -c -Wall -Werror foo.c

gcov: main.c foo.c
	gcov main.c foo.c

coverage.info: gcov
	lcov --capture --directory . --output-file coverage.info

report : coverage.info
	genhtml coverage.info --output-directory out

clean:
	$(RM) main *.o *.so *.gcno *.gcda *.gcov coverage.info out
