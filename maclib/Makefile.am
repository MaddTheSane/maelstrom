AM_CXXFLAGS = -std=c++11 $(SDL2_CFLAGS) $(SDL2_MIXER_CFLAGS)
AM_LDFLAGS  = $(SDL2_LIBS) $(SDL2_MIXER_LIBS)

noinst_LIBRARIES = libSDLmac.a

libSDLmac_a_SOURCES =		\
	../Maelstrom_Globals.h	\
	Mac_Compat.h		\
	Mac_FontServ.cpp	\
	Mac_FontServ.h		\
	Mac_Resource.cpp	\
	Mac_Resource.h		\
	Mac_Wave.cpp		\
	Mac_Wave.h		\
	applefile.h		\
	macbinary.h		\
	bitesex.h

noinst_PROGRAMS = macres snd2wav

macres_SOURCES = macres.cpp
macres_LDADD   = libSDLmac.a

snd2wav_SOURCES = snd2wav.cpp
snd2wav_LDADD   = libSDLmac.a
