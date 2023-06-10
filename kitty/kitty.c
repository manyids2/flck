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

struct line {
  size_t r;
  char buf[256];
};
struct kdata {
  int iid;
  size_t offset;
  struct line data;
};
struct pos {
  int x, y;
};

typedef struct line line;
typedef struct kdata kdata;
typedef struct pos pos;
typedef void (*key_cb)(int k);

line kitty_recv_term(int timeout) {
  line l = {0, {0}};
  int r;
  struct pollfd fds[1];

  memset(fds, 0, sizeof(fds));
  fds[0].fd = fileno(stdin);
  fds[0].events = POLLIN;

  if ((r = poll(fds, 1, timeout)) < 0) {
    return l;
  }
  if ((fds[0].revents & POLLIN) == 0) {
    return l;
  }

  l.r = read(0, l.buf, sizeof(l.buf) - 1);
  if (l.r > 0) {
    l.buf[l.r] = '\0';
  }

  return l;
}

line kitty_send_term(const char *s) {
  fputs(s, stdout);
  fflush(stdout);
  return kitty_recv_term(-1);
}

void kitty_set_position(int x, int y) {
  printf("\x1B[%d;%dH", y, x);
  fflush(stdout);
}

pos kitty_get_position() {
  pos p;
  line l = kitty_send_term("\x1B[6n");
  int r = sscanf(l.buf + 1, "[%d;%dR", &p.y, &p.x);
  return p;
}

void kitty_hide_cursor() { puts("\x1B[?25l"); }

void kitty_show_cursor() { puts("\x1B[?25h"); }

kdata kitty_parse_response(line l) {
  /*
   * parse kitty response of the form: "\x1B_Gi=<image_id>;OK\x1B\\"
   *
   * NOTE: a keypress can be present before or after the data
   */
  if (l.r < 1) {
    return (kdata){-1, 0, l};
  }
  char *esc = strchr(l.buf, '\x1B');
  if (!esc) {
    return (kdata){-1, 0, l};
  }
  ptrdiff_t offset = (esc - l.buf) + 1;
  int iid = 0;
  int r = sscanf(l.buf + offset, "_Gi=%d;OK", &iid);
  if (r != 1) {
    return (kdata){-1, 0, l};
  }
  return (kdata){iid, offset, l};
}

key_cb *_get_key_callback() {
  static key_cb cb;
  return &cb;
}

void kitty_key_callback(key_cb cb) { *_get_key_callback() = cb; }

void kitty_poll_events(int millis) {
  kdata k;

  /*
   * loop until we see the image id from kitty acknowledging
   * the image upload. keypresses can arrive on their own,
   * or before or after the image id response from kitty.
   */
  do {
    k = kitty_parse_response(kitty_recv_term(millis));
    /* handle keypress present at the beginning of the response */
    if (k.offset == 2) {
      (*_get_key_callback())(k.data.buf[0]);
    }
    /* handle keypress present at the end of the response */
    if (k.offset == 1) {
      char *ok = strstr(k.data.buf + k.offset, ";OK\x1B\\");
      ptrdiff_t ko = (ok != NULL) ? ((ok - k.data.buf) + 5) : 0;
      if (k.data.r > ko) {
        (*_get_key_callback())(k.data.buf[ko]);
      }
    }
    /* handle keypress on its own */
    if (k.offset == 0 && k.data.r == 1) {
      (*_get_key_callback())(k.data.buf[0]);
    }
    /* loop once more for a keypress, if we got our image id */
  } while (k.iid > 0);
}

struct termios *_get_termios_backup() {
  static struct termios backup;
  return &backup;
}

struct termios *_get_termios_raw() {
  static struct termios raw;
  cfmakeraw(&raw);
  return &raw;
}

void kitty_setup_termios() {
  /* save termios and set to raw */
  tcgetattr(0, _get_termios_backup());
  tcsetattr(0, TCSANOW, _get_termios_raw());
}

void kitty_restore_termios() {
  /* restore termios */
  tcsetattr(0, TCSANOW, _get_termios_backup());
}
