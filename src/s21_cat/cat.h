#ifndef SIMPLEBASH_CAT_H
#define SIMPLEBASH_CAT_H
#include <errno.h>
#include <getopt.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>
typedef struct {
  bool n;
  bool b;
  bool s;
  bool E;
  bool T;
  bool v;
} options;
int print_files(int argc, char *argv[], options opts);
void help();
options parse_options(int argc, char *argv[]);
void apply_flags(FILE *file, options opts, int *line_counter, int *prev_ch,
                 bool *track_empt);
#endif
