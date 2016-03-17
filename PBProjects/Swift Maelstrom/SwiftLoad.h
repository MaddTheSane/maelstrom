//
//  SwiftLoad.h
//  Maelstrom
//
//  Created by C.W. Betts on 3/16/16.
//
//

#ifndef SwiftLoad_h
#define SwiftLoad_h

#include <SDL2/SDL_surface.h>

#ifdef __cplusplus
extern "C" {
#endif
	SDL_Surface *loadIcon(char **xpm);
#ifdef __cplusplus
}
#endif


#endif /* SwiftLoad_h */
