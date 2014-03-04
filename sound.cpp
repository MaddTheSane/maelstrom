/*************************************************************************
 * Maelstrom                                                             *
 * Copyright (C) 2014       Emery Hemingway                              *
 * Copyright (C) 1995-1999  Sam Lantiga                                  *
 * Copyright (C) 1992       Ambrosia Software                            *
 *                                                                       *
 * This program is free software: you can redistribute it and/or modify  *
 * it under the terms of the GNU General Public License as published by  *
 * the Free Software Foundation, either version 3 of the License, or     *
 * (at your option) any later version.                                   *
 *                                                                       *
 * This program is distributed in the hope that it will be useful,       *
 * but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 * GNU General Public License for more details.                          *
 *                                                                       *
 * You should have received a copy of the GNU General Public License     *
 * along with this program.  If not, see <http://www.gnu.org/licenses/>. *
 *************************************************************************/

#include "sound.h"

#include "path.h"

#include <stdint.h>
#include <string>

namespace Maelstrom {

Sound::Sound(uint8_t vol)
	:chunks(34), priorities(MIXER_CHANNELS)
{
	if (Mix_OpenAudio(OUTPUT_RATE, OUTPUT_FORMAT, 
			  OUTPUT_CHANNELS, OUTPUT_CHUNK_SIZE) == -1) {
		throw Sound_Error(Mix_GetError());
	}
	Mix_AllocateChannels(MIXER_CHANNELS);

	std::string filename;
	Mix_Chunk *chunk;
	for ( auto i=0; i < 34; ++i ) {
		filename = DATADIR "/sounds/" + filenames[i] + ".ogg";
		chunk = Mix_LoadWAV(filename.c_str());
		if (chunk == NULL)
			throw Sound_Error(Mix_GetError());

		chunks[i] = chunk;
	}
	//delete[] filename;
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
	return Mix_PlayChannel(THRUST_CHANNEL, chunks[ThrusterSound], -1);
}

void Sound::HaltThruster() {
	/* This might stop other sounds than thrust,
	 * but if it does there is probably alot of stuff going on anyway.
	 */
	Mix_HaltChannel(THRUST_CHANNEL); 
}

}
