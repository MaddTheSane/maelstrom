//
//  Mac_Wave.swift
//  Maelstrom
//
//  Created by C.W. Betts on 11/1/15.
//
//

import Foundation

/*
/* Different sound header formats */
#define FORMAT_1	0x0001
#define FORMAT_2	0x0002

/* The different types of sound data */
#define SAMPLED_SND	0x0005

/* Initialization commands */
#define MONO_SOUND	0x00000080
#define STEREO_SOUND	0x000000A0

/* The different sound commands; we only support BUFFER_CMD */
#define SOUND_CMD	0x8050		/* Different from BUFFER_CMD? */
#define BUFFER_CMD	0x8051
*/

/* Different original sampling rates -- rate = (#define)>>16 */
///44100.0
private let rate44khz: UInt32 = 0xAC440000
///22254.5
private let rate22khz: UInt32 = 0x56EE8BA3
///11127.3
private let rate11khz: UInt32 = 0x2B7745D0
///11127.3 (?)
private let rate11khz2: UInt32 = 0x2B7745D1
/*
#define stdSH		0x00
#define extSH		0xFF
#define cmpSH		0xFE

/*******************************************/

#define snd_copy16(V, D)						\
{									\
V = *((Uint16 *)D);						\
D += 2;								\
V = snd_sex16(V);						\
}
#define snd_copy32(V, D)						\
{									\
memcpy(&V, D, sizeof(Uint32));					\
D += 4;								\
V = snd_sex32(V);						\
}

*/