/*
    MACLIB:  A companion library to SDL for working with Macintosh (tm) data
    Copyright (C) 1997  Sam Lantinga

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

    Sam Lantinga
    5635-34 Springhouse Dr.
    Pleasanton, CA 94588 (USA)
    slouken@devolution.com
*/

/* A WAVE class that can load itself from WAVE files or Mac 'snd ' resources */

#include "SDL_audio.h"
#include "Mac_Resource.h"
#include <SDL_mixer.h>

#include <string>
#include <stdexcept>
#include <iostream>

struct Mac_Wave_Error : public std::runtime_error {
	Mac_Wave_Error(const std::string& p) :runtime_error(p) {}
};

class Wave {
private:
	void Init(void);
	void Free(void);

	/* The SDL-ready audio specification */
	SDL_AudioSpec spec;
	Uint8 *sound_data;
	Uint32 sound_datalen;

	/* Utility functions */
	Uint32 ConvertRate(Uint16 rate_in, Uint16 rate_out,
			   Uint8 **samples, Uint32 n_samples, Uint8 s_size);
	void Convert(uint16_t format, uint8_t channels, uint32_t rate);

	/* Useful for getting error feedback */
	void error(char *fmt, ...) {
		va_list ap;

		va_start(ap, fmt);
		vsnprintf(errbuf, sizeof(errbuf), fmt, ap);
		va_end(ap);
		errstr = errbuf;
	}
	char *errstr;
	char  errbuf[BUFSIZ];

public:
	Wave() {
		Init();
	}
	~Wave() {
		Free();
	}

	/* Load WAVE resources, converting to the desired sample rate */
	int Load(const char *wavefile, uint16_t format, uint8_t channels, uint32_t rate);
	int Load(Mac_ResData *snd, uint16_t format, uint8_t channels, uint32_t rate);
	int Save(char *wavefile);

	int Stereo(void)          { return(spec.channels/2); }
	int Channels(void)        { return spec.channels; }
	int BitsPerSample(void)   { return(spec.format&0xFF); }
	Uint16 SampleSize(void)   { return(((spec.format&0xFF)/8)*spec.channels); }
	SDL_AudioSpec *Spec(void) { return(&spec); }

	char *Error(void) { return(errstr); }

	/* Return a SDL Mixer chunk */
	Mix_Chunk *Chunk();
};
