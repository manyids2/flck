#include "kitty.h"
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int luaopen_kitty(lua_State *L) {
  /* Create the table to return from 'require' */
  lua_newtable(L);
  lua_pushliteral(L, "_NAME");
  lua_pushliteral(L, "kitty");
  lua_rawset(L, -3);
  lua_pushliteral(L, "_VERSION");
  lua_pushliteral(L, "v0.0");
  lua_rawset(L, -3);
  return 1;
}
