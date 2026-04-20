FLAGS = -Wall -Wextra -Werror

all: clean s21_cat

s21_cat: Makefile cat.h cat.c
	gcc $(FLAGS) cat.c -o s21_cat

clean:
	rm -f s21_cat