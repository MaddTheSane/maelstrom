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

#include "Mac_Sound.h"
#include "Mac_Wave.h"
#include "../sounds.h"

#include <iostream>
#include <string>


Sound::Sound(const char *soundfile, Uint8 vol)
	:chunks(36), priorities(MIXER_CHANNELS)
{
#ifdef DEBUG
	std::cerr << "Mix_OpenAudio with sampling rate of " <<  OUTPUT_RATE << std::endl;
#endif

	/* Load the sounds from the resource files */
	Mac_Resource soundres(soundfile);
	if (Mix_OpenAudio(OUTPUT_RATE, OUTPUT_FORMAT, OUTPUT_CHANNELS, OUTPUT_CHUNK_SIZE) == -1) {
		throw Mix_GetError();
	}
	Mix_AllocateChannels(MIXER_CHANNELS);

	Wave wave;
	for ( auto id : soundres.ResourceIDs("snd ") ) {
		Mac_ResData *snd = soundres.Resource("snd ", id);
		if ( snd == NULL )
			throw "soundres was NULL";

		wave.Load(snd, OUTPUT_FORMAT, OUTPUT_CHANNELS, OUTPUT_RATE);
		if ( wave.Error() ) {
			throw std::string(wave.Error());
			continue;
		}

		if ( Mix_Chunk *chunk = wave.Chunk() )
			chunks[id-100] = chunk;
		/* drop the  ^ hundred so ids are in the range of 0-36 */
	}

	Mix_Volume(-1, vol*16);
}

Sound::~Sound()
{
	Mix_HaltChannel(-1);
	for ( Mix_Chunk *c : chunks) {
		if ( c == nullptr )
			continue;
		Mix_FreeChunk(c);
	}
	Mix_CloseAudio();
}

int Sound::PlaySound(Uint16 sndID, Uint8 priority)
{
	Mix_Chunk *chunk = chunks[sndID];
	if ( chunk == nullptr )
		return -1;
	int i;
	/* find an empty channel */
	for ( i=0; i<MIXER_CHANNELS; ++i ) {
		if ( Mix_Playing(i) )
			continue;

		priorities[i] = priority;
		return Mix_PlayChannel(i, chunk, 0);
	}

	/* or stop a currently playing one */
	for ( i=0; i<MIXER_CHANNELS; ++i ) {
		if ( priorities[i] < priority ) {
			Mix_HaltChannel(i);
			priorities[i] = priority;
			return Mix_PlayChannel(i, chunk, 0);
		}
	}
	return -1;
}

int Sound::PlayThruster()
{
	if ( Mix_Playing(THRUST_CHANNEL) ) {
		if ( priorities[THRUST_CHANNEL] > 1 )
			return -1;

		Mix_HaltChannel(THRUST_CHANNEL);
		priorities[THRUST_CHANNEL] = 1;
	}
	return Mix_PlayChannel(THRUST_CHANNEL, chunks[gThrusterSound], -1);
}

void Sound::HaltThruster() {
	/* This might stop other sounds than thrust,
	 * but if it does there is probably alot of stuff going on anyway.
	 */
	Mix_HaltChannel(THRUST_CHANNEL); 
}
