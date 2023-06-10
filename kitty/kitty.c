#include <assert.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <alloca.h>
#include <poll.h>
#include <termios.h>
#include <unistd.h>

void kitty_set_position(int x, int y) {
  printf("\x1B[%d;%dH", y, x);
  fflush(stdout);
}

void kitty_hide_cursor() { puts("\x1B[?25l"); }

void kitty_show_cursor() { puts("\x1B[?25h"); }
