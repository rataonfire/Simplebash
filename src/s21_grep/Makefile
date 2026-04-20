FLAGS = -Wall -Wextra -Werror

all: clean s21_grep

s21_grep: grep.c grep.h
	gcc $(FLAGS) grep.c -o s21_grep

clean:
	rm -f s21_grep