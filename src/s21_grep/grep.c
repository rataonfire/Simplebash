#include "grep.h"

int main(int argc, char *argv[]) {
  bool any_match = false;
  bool any_error = false;
  if (argc > 1) {
    options opts = parse_options(argc, argv);
    int argv_patterns = opts.e_count;
    load_f_patterns(&opts, &any_error);
    for (int i = 0; i < opts.files_count; i++) {
      process_file(opts.files[i], &opts, &any_match, &any_error);
    }

    for (int i = argv_patterns; i < opts.e_count; i++) {
      free(opts.e_patterns[i]);
    }
  } else {
    help();
  }
  if (any_error) return 2;
  return any_match ? 0 : 1;
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

bool match_line(char *line, regex_t *regex, regmatch_t *match) {
  return !regexec(regex, line, 1, match, 0);
}

void print_result(char *line, const char *filename, int line_num, options *opts,
                  regmatch_t match) {
  if (opts->c || opts->l) {
    return;
  }
  if (!opts->h && opts->files_count > 1) {
    printf("%s:", filename);
  }
  if (opts->n) {
    printf("%d:", line_num);
  }
  if (opts->o) {
    printf("%.*s\n", (int)(match.rm_eo - match.rm_so), line + match.rm_so);
    return;
  }
  printf("%s", line);
}

static void process_line(char *line, const char *filename, int line_num,
                         options *opts, regex_t *compiled, int compiled_count,
                         int *counter) {
  if (opts->o && !opts->v) {
    char *cursor = line;
    while (1) {
      regmatch_t best = {-1, -1};
      for (int i = 0; i < compiled_count; i++) {
        regmatch_t m;
        if (!regexec(&compiled[i], cursor, 1, &m, 0)) {
          if (best.rm_so == -1 || m.rm_so < best.rm_so) {
            best = m;
          }
        }
      }
      if (best.rm_so == -1) break;
      (*counter)++;
      print_result(cursor, filename, line_num, opts, best);
      if (best.rm_so == best.rm_eo) {
        if (*cursor == '\0') break;
        cursor++;
      } else {
        cursor += best.rm_eo;
      }
    }
  } else {
    regmatch_t match;
    bool line_matched = false;
    for (int i = 0; i < compiled_count; i++) {
      if (!regexec(&compiled[i], line, 1, &match, 0)) {
        line_matched = true;
        break;
      }
    }
    if (line_matched ^ opts->v) {
      (*counter)++;
      if (!opts->o) print_result(line, filename, line_num, opts, match);
    }
  }
}

void process_file(const char *filename, options *opts, bool *any_match,
                  bool *any_error) {
  FILE *file = fopen(filename, "r");
  if (file == NULL) {
    if (!opts->s)
      fprintf(stderr, "./s21_grep: %s: %s\n", filename, strerror(errno));
    *any_error = true;
    return;
  }

  regex_t *compiled = malloc(sizeof(regex_t) * opts->e_count);
  if (compiled == NULL) {
    *any_error = true;
    fclose(file);
    return;
  }
  int compiled_count = 0;
  int flags = REG_NEWLINE | (opts->i ? REG_ICASE : 0);
  for (int i = 0; i < opts->e_count; i++) {
    if (regcomp(&compiled[compiled_count], opts->e_patterns[i], flags) == 0) {
      compiled_count++;
    } else {
      *any_error = true;
    }
  }

  char *line = NULL;
  size_t len = 0;
  int line_num = 1;
  int counter = 0;

  while (getline(&line, &len, file) != -1) {
    process_line(line, filename, line_num, opts, compiled, compiled_count,
                 &counter);
    line_num++;
    if (opts->l && counter > 0) break;
  }
  if (opts->c) {
    if (!opts->h && opts->files_count > 1) printf("%s:", filename);
    printf("%d\n", counter);
  }
  if (opts->l && counter) {
    printf("%s\n", filename);
  }
  if (counter > 0) *any_match = true;

  for (int i = 0; i < compiled_count; i++) {
    regfree(&compiled[i]);
  }
  free(compiled);
  free(line);
  fclose(file);
}

void load_f_patterns(options *opts, bool *any_error) {
  for (int i = 0; i < opts->f_count; i++) {
    FILE *file = fopen(opts->f_files[i], "r");
    if (file == NULL) {
      if (!opts->s)
        fprintf(stderr, "./s21_grep: %s: %s\n", opts->f_files[i],
                strerror(errno));
      *any_error = true;
      continue;
    }
    while (opts->e_count < MAX_FILES) {
      char *buf = NULL;
      size_t cap = 0;
      ssize_t read = getline(&buf, &cap, file);
      if (read == -1) {
        free(buf);
        break;
      }
      if (read > 0 && buf[read - 1] == '\n') buf[read - 1] = '\0';
      opts->e_patterns[opts->e_count++] = buf;
    }
    fclose(file);
  }
}

options parse_options(int argc, char *argv[]) {
  options opts = {0};
  int opt;
  static struct option const long_options[] = {
      {"regexp", required_argument, NULL, 'e'},
      {"ignore-case", no_argument, NULL, 'i'},
      {"invert-match", no_argument, NULL, 'v'},
      {"count", no_argument, NULL, 'c'},
      {"files-with-matches", no_argument, NULL, 'l'},
      {"line-number", no_argument, NULL, 'n'},
      {"no-filename", no_argument, NULL, 'h'},
      {"no-messages", no_argument, NULL, 's'},
      {"file", required_argument, NULL, 'f'},
      {"only-matching", no_argument, NULL, 'o'},
      {NULL, 0, NULL, 0}};
  while ((opt = getopt_long(argc, argv, "e:ivclnhsf:o", long_options, NULL)) !=
         -1) {
    switch (opt) {
      case 'e':
        opts.e = true;
        if (opts.e_count < MAX_FILES) opts.e_patterns[opts.e_count++] = optarg;
        break;
      case 'i':
        opts.i = true;
        break;
      case 'v':
        opts.v = true;
        break;
      case 'c':
        opts.c = true;
        break;
      case 'l':
        opts.l = true;
        break;
      case 'n':
        opts.n = true;
        break;
      case 'h':
        opts.h = true;
        break;
      case 's':
        opts.s = true;
        break;
      case 'f':
        opts.f = true;
        if (opts.f_count < MAX_FILES) opts.f_files[opts.f_count++] = optarg;
        break;
      case 'o':
        opts.o = true;
        break;
    }
  }
  if (!opts.e && !opts.f) {
    if (optind < argc && opts.e_count < MAX_FILES) {
      opts.e_patterns[opts.e_count++] = argv[optind];
      optind++;
    }
  }
  while (optind < argc && opts.files_count < MAX_FILES) {
    opts.files[opts.files_count++] = argv[optind++];
  }
  return opts;
}