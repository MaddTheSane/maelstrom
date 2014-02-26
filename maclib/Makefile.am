AM_CXXFLAGS = -std=c++11 $(SDL_CFLAGS) $(SDL_MIXER_CFLAGS)
AM_LDFLAGS  = $(SDL_LIBS) $(SDL_MIXER_LIBS)

noinst_LIBRARIES = libSDLmac.a

libSDLmac_a_SOURCES =		\
	../Maelstrom_Globals.h	\
	Mac_Compat.h		\
	Mac_FontServ.cpp	\
	Mac_FontServ.h		\
	Mac_Resource.cpp	\
	Mac_Resource.h		\
	Mac_Sound.cpp		\
	Mac_Sound.h		\
	Mac_Wave.cpp		\
	Mac_Wave.h		\
	applefile.h		\
	macbinary.h		\
	bitesex.h

noinst_PROGRAMS = macres playres playwave snd2wav

macres_SOURCES = macres.cpp
macres_LDADD   = libSDLmac.a

#playres: libSDLmac.a

playres_SOURCES = playres.cpp
playres_LDADD   = libSDLmac.a

playwave_SOURCES = playwave.cpp
playwave_LDADD   = libSDLmac.a

snd2wav_SOURCES = snd2wav.cpp
snd2wav_LDADD   = libSDLmac.a
