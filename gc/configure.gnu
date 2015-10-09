#!/bin/sh

# "--enable-threads=..."
#   [SK] Original Boehm GC checks gcc for the default thread support.
#   In our case we need the thread config in sync with the main Gauche
#   source tree.  The Gauche's configure leaves its thread settings in
#   'config.threads' so we just read it.
#   config.threads is created in the build directory instead of $srcdir,
#   so we directly refer it.
#
# "-DDONT_ADD_BYTE_AT_END", "--enable-large-config"
#   [SK] this is _required_ to make Gauche work correctly.
#
# "--enable-handle-fork"
#   [SK] this supposed to make GC in forked children work on OSX; it did
#   work on OSX 10.7.3, but caused various failures on 10.7.4, so I disable
#   it again.

${CONFIG_SHELL} ./configure "${@}" \
		--enable-threads=$(cat ../config.threads) \
		--enable-large-config \
		CPPFLAGS="${CPPFLAGS} -DDONT_ADD_BYTE_AT_END"