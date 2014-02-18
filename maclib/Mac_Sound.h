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

#include <SDL_mixer.h>
#include <vector>

class Sound {
private:
	std::vector<Mix_Chunk*> chunks;
	std::vector<unsigned short int> priorities;

public:
	Sound(const char *soundfile, Uint8 vol = 4);
	~Sound();

	/**
	 * Stop mixing on the requested channels.
	 */
	void HaltSound(int channel = -1) { Mix_HaltChannel(channel); }

	/**
	 * Play the requested sound.
	 */
	int PlaySound(Uint16 sndID, Uint8 priority);

	/**
	 * Find out if a sound is playing on a channel.
	 */
	int Playing() { return Mix_Playing(-1); }

	/**
	 * Set volume in the range 0-8 (by increasing from 0-8 to 0-128).
	 */
	int Volume(Uint8 vol = -1) { return Mix_Volume(-1, vol*16); }

	/**
	 * Start a thruster sound loop.
	 */
	int PlayThruster();

	/**
	 * Sop a thruster sound loop.
	 */
	void HaltThruster();
};
