#ifndef WS_F3_DESCRIPTOR_VFS_H
#define WS_F3_DESCRIPTOR_VFS_H

#include "sqlite3.h"
#include <stdbool.h>
#include <stddef.h>

#define WSF3_FIXTURE_LIMIT (1024 * 1024)

enum wsf3_phase {
  WSF3_CONSTRUCTION,
  WSF3_BINDING,
  WSF3_KEY_APPLIED,
  WSF3_AUTHENTICATING,
  WSF3_READY,
  WSF3_FRESH_INITIALIZATION
};

struct wsf3_vfs {
  sqlite3_vfs vfs;
  sqlite3_vfs *system;
  int descriptor;
  enum wsf3_phase phase;
  bool fresh;
  bool violated;
  unsigned char scratch[WSF3_FIXTURE_LIMIT];
  size_t scratch_size;
  unsigned requests;
  unsigned forwarded_pre_key_reads;
};

int wsf3_register(struct wsf3_vfs *scope, int descriptor, bool fresh);
void wsf3_transition(struct wsf3_vfs *scope, enum wsf3_phase next);

#endif
