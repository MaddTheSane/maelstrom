dnl Process this file with autoconf to produce a configure script.
AC_INIT([Maelstrom],[4.0.1])
AC_CONFIG_SRCDIR([main.cpp])

dnl Detect the canonical target build environment
AC_CANONICAL_TARGET
AC_CANONICAL_HOST

dnl Setup for automake
AM_INIT_AUTOMAKE

dnl Check for tools

AC_PROG_MAKE_SET
AC_PROG_CC
AC_PROG_CXX
AC_PROG_RANLIB
AC_PROG_INSTALL

dnl Check for SDL
PKG_CHECK_MODULES([SDL], [sdl >= 1.2.0])
PKG_CHECK_MODULES([SDL_NET], [SDL_net])
PKG_CHECK_MODULES([SDL_MIXER], [SDL_mixer])

#dnl Check for RSA checksum authentication
#AC_MSG_CHECKING(for RSA checksum authentication)
#if test -d $HOME/RSA; then
#    CFLAGS="$CFLAGS -DUSE_CHECKSUM -I$HOME/RSA/source"
#    LIBS="$LIBS $HOME/RSA/install/rsaref.a"
#    use_checksum=yes
#else
#    use_checksum=no
#fi
#AC_MSG_RESULT($use_checksum)

# Finally create all the generated files
AC_CONFIG_FILES([
Makefile
netlogic/Makefile
screenlib/Makefile
maclib/Makefile
Maelstrom.spec
])
AC_OUTPUT
