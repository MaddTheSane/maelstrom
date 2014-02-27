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

#ifndef SOUND_H_
#define SOUND_H_

#include <SDL_mixer.h>

#include <vector>
#include <stdexcept>


struct Sound_Error : public std::runtime_error {
        Sound_Error(const std::string& p) :runtime_error(p) {}
};

class Sound {
private:
        enum {
                /* 4 sound mixing channels, thrust is mixed on the last channel. */
                MIXER_CHANNELS = 4, THRUST_CHANNEL = 3,

                /* Sound specs */
                OUTPUT_RATE = 11025,
                OUTPUT_FORMAT = AUDIO_U8,
                OUTPUT_CHANNELS = 1,
                OUTPUT_CHUNK_SIZE = 256,
                /* increase the buffer size linearly with the size of the audio,
                 * (double the rate or channels, double the buffer).
                 */
        };

	std::vector<Mix_Chunk*> chunks;
	std::vector<unsigned short int> priorities;

public:
	enum {
		ShotSound, Multiplier, ExplosionSound, ShipHitSound,
		Boom1, Boom2, MultiplierGone, MultShotSound,
		SteelHit, Bonk, Riff, PrizeAppears,
		GotPrize, GameOver, NewLife, BonusAppears,
		BonusShot, NoBonus, GravAppears, HomingAppears,
		ShieldOnSound, NoShieldSound, NovaAppears, NovaBoom,
		LuckySound, DamagedAppears, SavedShipSound, Funk,
		EnemyAppears, PrettyGood, ThrusterSound, EnemyFire,
		FreezeSound, IdiotSound, PauseSound,
	};

	Sound(Uint8 vol = 4);
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

#endif /* SOUND_H_ */
