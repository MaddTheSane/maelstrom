/*
    PLAYWAVE:  A WAVE file player using the maclib and SDL libraries
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

/* Very simple WAVE player */

#include <csignal>

#include "SDL.h"
#include <SDL_mixer.h>
#include "Mac_Wave.h"

static SDL_sem *sem;
static Mix_Chunk *chunk;

void finished(int channel) { SDL_SemPost(sem); }

void CleanUp(int status)
{
	Mix_CloseAudio();
	Mix_FreeChunk(chunk);
	Mix_Quit();
	SDL_DestroySemaphore(sem);
	SDL_Quit();
	exit(status);
}

int main(int argc, char *argv[])
{
	Wave        *wave;
	{
		Mac_ResData *snd;
		Uint16      rate;

		rate = MIX_DEFAULT_FREQUENCY;
		if ( (argc >= 3) && (strcmp(argv[1], "-rate") == 0) ) {
			int i;
			rate = (Uint16)atoi(argv[2]);
			for ( i=3; argv[i]; ++i ) {
				argv[i-2] = argv[i];
			}
			argv[i-2] = NULL;
			argc -= 2;
		}
		if ( argc == 2 ) {
			/* Load the wave file into memory */
			wave = new Wave(argv[1], rate);
			if ( wave->Error() ) {
				fprintf(stderr, "%s\n", wave->Error());
				exit(255);
			}
		} else if ( argc == 3) {
			Mac_Resource macx(argv[1]);
			if ( (argv[2][0] >= '0') && (argv[2][0] <= '9') )
				snd = macx.Resource("snd ", atoi(argv[2]));
			else
				snd = macx.Resource("snd ", argv[2]);
			if ( snd == NULL ) {
				fprintf(stderr, "%s\n", macx.Error());
				exit(255);
			}
			wave = new Wave(snd, rate);
			if ( wave->Error() ) {
				fprintf(stderr, "%s\n", wave->Error());
				exit(255);
			}
		} else {
			fprintf(stderr, "Usage: %s [-rate <rate>] <wavefile>\n", argv[0]);
			fprintf(stderr, "or..\n");
			fprintf(stderr, "       %s [-rate <rate>] <snd_fork> [soundnum]\n",
				argv[0]);
			exit(1);
		}

		/* Show what audio format we're playing */
		printf("Playing %#.2f seconds (%d bit %s) at %u Hz\n",
		       (double)(wave->DataLeft()/wave->SampleSize())/wave->Frequency(),
		       wave->BitsPerSample(),
		       wave->Stereo() ? "stereo" : "mono", wave->Frequency());

		if ( SDL_Init(SDL_INIT_AUDIO) < 0 ) {
			fprintf(stderr, "Couldn't initialize SDL: %s\n",SDL_GetError());
			exit(1);
		}

#ifdef SAVE_THE_WAVES
		if ( wave->Save("save.wav") < 0 )
			fprintf(stderr, "Warning: %s\n", wave->Error());
#endif

		if (Mix_OpenAudio(MIX_DEFAULT_FREQUENCY, MIX_DEFAULT_FORMAT, wave->Channels(), 4096) == -1) {
			fprintf(stderr, "Couldn't initialize SDL mixer: %s\n", Mix_GetError());
			exit(1);
		}

		/* export the wave to a mixer chunk */
		chunk = wave->Chunk();
	}

	/* prime semaphore */
	sem = SDL_CreateSemaphore(0);
	Mix_ChannelFinished(finished);

	/* Create a semaphore to wait for end of play */

	/* Set the signals */
#ifdef SIGHUP
	signal(SIGHUP, CleanUp);
#endif
	signal(SIGINT, CleanUp);
#ifdef SIGQUIT
	signal(SIGQUIT, CleanUp);
#endif
	signal(SIGTERM, CleanUp);

	/* Let the audio run, waiting until finished */
	if ( Mix_PlayChannel(-1, chunk, 0) == -1 ) {
		printf("Mix_PlayChannel: %s\n",Mix_GetError());
	}

	/* wait until playback has finished */
	SDL_SemWait(sem);

	/* We're done! */
	CleanUp(0);
}
