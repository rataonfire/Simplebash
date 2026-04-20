#ifndef SIMPLEBASH_GREP_H
#define SIMPLEBASH_GREP_H
#define MAX_FILES 100
#include <errno.h>
#include <getopt.h>
#include <regex.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
typedef struct {
  bool e;
  bool i;
  bool v;
  bool c;
  bool l;
  bool n;
  bool h;
  bool s;
  bool f;
  bool o;
  char *f_files[MAX_FILES];
  int f_count;
  char *e_patterns[MAX_FILES];
  int e_count;
  char *files[MAX_FILES];
  int files_count;
} options;
void help();
bool match_line(char *line, regex_t *regex, regmatch_t *match);
void print_result(char *line, const char *filename, int line_num, options *opts,
                  regmatch_t match);
options parse_options(int argc, char *argv[]);
void load_f_patterns(options *opts, bool *any_error);
void process_file(const char *filename, options *opts, bool *any_match,
                  bool *any_error);
#endif
