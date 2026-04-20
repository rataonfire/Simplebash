#include "cat.h"

int main(int argc, char *argv[]) {
  int rc = 0;
  if (argc > 1) {
    options opts = parse_options(argc, argv);
    rc = print_files(argc, argv, opts);
  } else {
    help();
  }
  return rc;
}

void apply_flags(FILE *file, options opts, int *line_counter, int *prev_ch,
                 bool *track_empt) {
  int ch;
  while ((ch = fgetc(file)) != EOF) {
    bool skip_char = false;
    if (opts.s) {
      if (*prev_ch == '\n' && ch == '\n') {
        if (*track_empt) {
          skip_char = true;
        } else {
          *track_empt = true;
        }
      } else {
        *track_empt = false;
      }
    }
    if (skip_char) {
      *prev_ch = ch;
      continue;
    }

    if (!opts.b && opts.n) {
      if (*prev_ch == '\n') {
        *line_counter += 1;
        printf("%6d\t", *line_counter);
      }
    }
    if (opts.b) {
      if (*prev_ch == '\n' && ch != '\n') {
        *line_counter += 1;
        printf("%6d\t", *line_counter);
      }
    }
    if (opts.E) {
      if (ch == '\n') {
        putchar('$');
      }
    }
    if (opts.T) {
      if (ch == '\t') {
        printf("^I");
        *prev_ch = ch;
        continue;
      }
    }
    if (opts.v) {
      if ((ch >= 0 && ch <= 31) && (ch != 10) && (ch != 9)) {
        printf("^%c", ch + 64);
        *prev_ch = ch;
        continue;
      } else if (ch == 127) {
        printf("^?");
        *prev_ch = ch;
        continue;
      }
    }
    putchar(ch);
    *prev_ch = ch;
  }
}

int print_files(int argc, char *argv[], options opts) {
  int prev_ch = '\n';
  int line_counter = 0;
  int rc = 0;
  bool track_empt = false;
  for (int i = optind; i < argc; i++) {
    FILE *file = fopen(argv[i], "r");
    if (file == NULL) {
      fprintf(stderr, "%s: %s: %s\n", argv[0], argv[i], strerror(errno));
      rc = 1;
      continue;
    }
    apply_flags(file, opts, &line_counter, &prev_ch, &track_empt);
    fclose(file);
  }
  return rc;
}

void help() {
  FILE *help_text = fopen("help.txt", "r");
  if (help_text == NULL) return;
  int ch;
  while ((ch = fgetc(help_text)) != EOF) {
    putchar(ch);
  }
  fclose(help_text);
}

options parse_options(int argc, char *argv[]) {
  options opts = {0};
  int opt;
  static struct option const long_options[] = {
      {"number-nonblank", no_argument, NULL, 'b'},
      {"number", no_argument, NULL, 'n'},
      {"squeeze-blank", no_argument, NULL, 's'},
      {"show-ends", no_argument, NULL, 'E'},
      {"show-tabs", no_argument, NULL, 'T'},
      {"show-nonprinting", no_argument, NULL, 'v'},
      {NULL, 0, NULL, 0}};
  while ((opt = getopt_long(argc, argv, "vbenstET", long_options, NULL)) !=
         -1) {
    switch (opt) {
      case 'n':
        opts.n = true;
        break;
      case 'b':
        opts.b = true;
        break;
      case 's':
        opts.s = true;
        break;
      case 'E':
        opts.E = true;
        break;
      case 'T':
        opts.T = true;
        break;
      case 'v':
        opts.v = true;
        break;
      case 'e':
        opts.v = true;
        opts.E = true;
        break;
      case 't':
        opts.v = true;
        opts.T = true;
        break;
    }
  }
  if (opts.b) {
    opts.n = false;
  }
  return opts;
}
