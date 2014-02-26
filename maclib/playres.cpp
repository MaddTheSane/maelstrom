/*
 * playres: a utility for testing res file loading and playback.
 */


#include "Mac_Sound.h"
#include "Mac_Wave.h"

#include <SDL.h>

#include <iostream>

static SDL_sem *sem;

void finished(int channel) { SDL_SemPost(sem); }

int main(int argc, char *argv[])
{
	if ( argc != 2 )
	{
		std::cerr << argv[0] << " RES_FILE" << std::endl;
		exit(1);
	}

	if ( SDL_Init(SDL_INIT_AUDIO) < 0 ) {
		std::cerr << "Failed to init SDL" << SDL_GetError() << std::endl;
		exit(1);
	}

	Sound sound(argv[1], 4);

	sem = SDL_CreateSemaphore(0);
	Mix_ChannelFinished(finished);

	for (auto i=0; i < 36; ++i) {
		sound.PlaySound(i, 1);
		SDL_SemWait(sem);
	}
	SDL_Quit();
}
