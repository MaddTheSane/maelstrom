//
//  SwiftLoad.cpp
//  Maelstrom
//
//  Created by C.W. Betts on 11/11/15.
//
//

#include <stdlib.h>
#include <string.h>

#include <SDL2/SDL_surface.h>

extern "C" SDL_Surface *Load_Icon(char **xpm);

SDL_Surface *Load_Icon(char **xpm)
{
	SDL_Surface *icon;
	int width, height, num_colors, chars_per_pixel;
	int index, i;
	char *buf;
	int b, p;
	Uint8 rgb[3];
	
	/* Figure out the size of the picture */
	index = 0;
	if ( sscanf(xpm[index++], "%d %d %d %d", &width, &height, &num_colors,
				&chars_per_pixel) != 4 ) {
		SDL_SetError("Can't read XPM format");
		return(NULL);
	}
	
	/* We only support 8-bit images, we punt here */
	if ( chars_per_pixel != 1 ) {
		SDL_SetError("Can't read XPM colors");
		return(NULL);
	}
	
	/* Allocate a surface of the appropriate type */
	icon = SDL_CreateRGBSurface(SDL_SWSURFACE, width, height, 8, 0,0,0,0);
	if ( icon == NULL ) {
		return(NULL);
	}
	
	/* Fill in the palette */
	for ( i=0; i<num_colors; ++i ) {
		buf = xpm[index++];
		p = *buf;
		memset(rgb, 0, 3);
		buf += 5;
		for ( b=0; b<6; ++b ) {
			rgb[b/2] *= 16;
			if ( (*buf >= 'a') && (*buf <='f') ) {
				rgb[b/2] += 10+*buf-'a';
			} else
				if ( (*buf >= 'A') && (*buf <='F') ) {
					rgb[b/2] += 10+*buf-'A';
				} else
					if ( (*buf >= '0') && (*buf <='9') ) {
						rgb[b/2] += *buf-'0';
					}
			++buf;
		}
		icon->format->palette->colors[p].r = rgb[0];
		icon->format->palette->colors[p].g = rgb[1];
		icon->format->palette->colors[p].b = rgb[2];
	}
	
	/* Fill in the pixels */
	buf = (char *)icon->pixels;
	for ( i=0; i<height; ++i ) {
		memcpy(buf, xpm[index++], width);
		buf += icon->pitch;
	}
	return(icon);
}
