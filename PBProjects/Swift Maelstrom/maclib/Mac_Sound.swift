//
//  Mac_Sound.swift
//  Maelstrom
//
//  Created by C.W. Betts on 11/2/15.
//
//

import Foundation
import SDL2

///Software volume ranges from `0 - 8`
let MAX_VOLUME: UInt8 = 8
///4 sound mixing channels, limit 128
let NUM_CHANNELS = 4
///Convert the SNDs to this frequency
let DSP_FREQUENCY:Int32 = 11025

private var bogus_running = false

private func fillAudio(_ selfPtr: UnsafeMutableRawPointer?, bytes: UnsafeMutablePointer<Uint8>?, length: Int32) -> Void {
	//ugly hack to get ourself back
	let ourself: Sound = {
		return Unmanaged<Sound>.fromOpaque(selfPtr!).takeUnretainedValue()
	}()
	
	ourself.fillAudioU8(bytes!, length)
}

private func bogusAudioThread(_ data: UnsafeMutableRawPointer?) -> Int32 {
	//void (*fill)(void *userdata, Uint8 *stream, int len);
	var then: UInt32 = 0
	var playticks: UInt32 = 0
	var ticksleft: Int32 = 0
	var stream: [UInt8]
	
	/* Clear out any signal handlers */
	for i in 0..<NSIG {
		signal(i, SIG_DFL)
	}
	
	/* Get ready to roll.. */
	let spec = data!.assumingMemoryBound(to: SDL_AudioSpec.self)
	if spec.pointee.callback == nil {
		//for ( ; ; ) {
		Delay(60*60*60);	/* Delay 1 hour */
		//}
	}
	let fill: SDL_AudioCallback? = spec.pointee.callback
	playticks = (UInt32(spec.pointee.samples) * 1000) / UInt32(spec.pointee.freq)
	/* Fill in the spec */
	spec.pointee.size = UInt32(spec.pointee.format&0xFF) / 8;
	spec.pointee.size *= UInt32(spec.pointee.channels)
	spec.pointee.size *= UInt32(spec.pointee.samples)
	stream = [UInt8](repeating: 0, count: Int(spec.pointee.size))
	
	while bogus_running {
		then = SDL_GetTicks();
		
		/* Fill buffer */
		if let fill = fill {
			fill(spec.pointee.userdata, &stream, Int32(spec.pointee.size))
		}
		
		/* Calculate time left, and sleep */
		ticksleft = Int32(playticks) - Int32( SDL_GetTicks() - then);
		if ticksleft > 0 {
			SDL_Delay(UInt32(ticksleft))
		}
	}
	
	return 0
}

final class Sound {
	
	enum Errors: Error {
		case noSoundResources
		case resourceLoadError(String)
	}
	
	fileprivate struct Channel {
		var ID: UInt16 = 0
		var priority: Int16 = 0
		///Signed, so race conditions can make it < 0
		var len: Int = 0
		var src: UnsafePointer<UInt8>? = nil
		var callback: ((_ channel: UInt8) -> Void)? = nil
	} //channels[NUM_CHANNELS];
	
	fileprivate var bogusAudio: SDL_ThreadPtr? = nil
	
	fileprivate var channels = [Channel](repeating: Channel(), count: NUM_CHANNELS)
	
	fileprivate var intVol: UInt8 = 0
	var volume: UInt8 {
		get {
			return intVol
		}
		set(aVol) {
			var vol = aVol
			
			var active = aPlaying;
			if volume == 0 && vol > 0 {
				/* Kill bogus sound thread */
				if bogusAudio != nil {
					bogus_running = false
					SDL_WaitThread(bogusAudio, nil);
					bogusAudio = nil;
				}
				
				/* Try to open the audio */
				if SDL_OpenAudio(&spec, nil) < 0 {
					vol = 0;		/* Fake sound */
				}
				active = true
				SDL_PauseAudio(0);		/* Go! */
			}
			if vol > MAX_VOLUME {
				vol = MAX_VOLUME;
			}
			intVol = vol;
			
			if active && (volume == 0) {
				if aPlaying {
					SDL_CloseAudio();
				}
				active = false
				
				/* Run bogus sound thread */
				bogus_running = true
				bogusAudio = SDL_CreateThread(bogusAudioThread, "BogusAudioThread", &spec);
				if bogusAudio == nil {
					/* Oh well... :-) */
				}
			}
			aPlaying = active;
		}
	}
	
	fileprivate var spec: SDL_AudioSpec = SDL_AudioSpec()
	fileprivate var aPlaying = false
	fileprivate(set) var waves = [UInt16: Wave]()
	
	///Stop mixing on all channels
	func haltAllSound() {
		for i in 0 ..< NUM_CHANNELS {
			haltSound(channel: i)
		}
	}
	
	///Stop mixing on the requested channel
	func haltSound(channel: Int) {
		channels[channel].len = 0
	}
	
	var playing: Bool {
		var unusedChannel: UInt8 = 0
		return playing(channel: &unusedChannel)
	}
	
	/// Find out if a sound is playing on a channel 
	func playing(_ sndID: UInt16 = 0, channel: inout UInt8) -> Bool {
		for i in 0..<NUM_CHANNELS {
			guard channels[i].len > 0 else {
				continue
			}
			
			if (sndID == 0) || (sndID == channels[i].ID) {
				channel = UInt8(i)
				return true;
			}
		}
		
		return false
	}

	init(soundFileURL soundfile: URL, volume vol: UInt8 = 4) throws {
		let sndResType = MaelOSType(stringValue: "snd ")!
		let soundres = try MacResource(fileURL: soundfile)
		var p = 0
		if soundres.countOfResources(type: sndResType) == 0 {
			throw Errors.noSoundResources
		}
		
		let ids = try soundres.resourceIDs(type: sndResType)
		
		var wave: Wave!
		
		for id in ids {
			let snd = try soundres.resource(type: sndResType, id: id)
			wave = try Wave(snd: snd, desiredRate: DSP_FREQUENCY)
			waves[id] = wave
		}
		
		spec = wave.spec
		
		/* Allow ~ 1/30 second time-lag in audio buffer -- samples is x^2  */
		spec.samples = UInt16(Int(wave.frequency) * Int(wave.sampleSize) / 30)
		while spec.samples > 1 {
			spec.samples /= 2
			p += 1
		}
		p += 1;
		for _ in 0..<p {
			spec.samples *= 2;
		}
		spec.callback = fillAudio
		//ugly hack to get to pass ourself as a parameter
		let unMan = Unmanaged.passUnretained(self)
		spec.userdata = unMan.toOpaque()
		
		/* Empty the channels and start the music :-) */
		haltAllSound()
		if ( vol == 0 ) {
			bogus_running = true
			bogusAudio = SDL_CreateThread(bogusAudioThread, "BogusAudioThread", &spec);
		} else {
			volume = vol
		}
	}

	func priorityOfChannel(_ channel: UInt8) -> Int16 {
		if channels[Int(channel)].len > 0 {
			return channels[Int(channel)].priority
		}
		
		return -1
	}

	/// Play the requested sound
	func playSound(_ sndID: UInt16, priority: UInt8 = 0, callback: ((_ channel: UInt8) -> ())? = nil) -> Bool {
		for i in 0..<NUM_CHANNELS {
			if channels[i].len <= 0 {
				return playSound(sndID, priority: priority, channel: UInt8(i), callback: callback)
			}
		}
		
		for i in 0..<NUM_CHANNELS {
			if Int16(priority) > self.priorityOfChannel(UInt8(i)) {
				return playSound(sndID, priority: priority, channel: UInt8(i), callback: callback)
			}
		}
		
		return false
	}
	
	/// Play the requested sound
	func playSound(_ sndID: UInt16, priority: UInt8, channel: UInt8, callback: ((_ channel: UInt8) -> ())? = nil) -> Bool {
		if Int16(priority) <= self.priorityOfChannel(channel) {
			return false
		}
		
		guard let wave = waves[sndID] else {
			return false
		}
		
		channels[Int(channel)].ID = sndID;
		channels[Int(channel)].priority = Int16(priority)
		channels[Int(channel)].len = Int(wave.dataLeft)
		channels[Int(channel)].src = wave.data
		channels[Int(channel)].callback = callback;
		#if DEBUG_SOUND
			print(String(format:"Playing sound %hu on channel %d", sndID, channel))
		#endif
		return true;
	}
	
	///This has to be a very fast routine, otherwise sound will lag and crackle
	fileprivate func fillAudioU8(_ stream2: UnsafeMutablePointer<UInt8>, _ length2: Int32) {
		var length = length2
		var stream = stream2
		//int i, s;
		
		/* Mix in each of the channels, assuming 8-bit unsigned audio data */
		while length != 0 {
			length -= 1
			var s = 0;
			for i in 0..<NUM_CHANNELS {
				if channels[i].len > 0 {
					/*
					Possible race condition:
					If the channel is halted here,
					len = 0 then we do '--len'
					len = -1, but that's okay.
					*/
					channels[i].len -= 1;
					s += Int((channels[i].src?.pointee)! &- 0x80)
					channels[i].src = channels[i].src?.successor();
					/*
					Possible race condition:
					If a sound is played here,
					len > 0, then we do 'if len <= 0'
					We never call back on channel.. bad.
					*/
					if channels[i].len <= 0 {
						#if DEBUG_SOUND
							print(String(format:"Channel %d finished", i))
						#endif
						/* This is critical */
						if let callback = channels[i].callback {
							callback(UInt8(i))
						}
					}
				}
			}
			/* handle volume */
			s = (s * Int(volume)) / Int(MAX_VOLUME)
			
			/* convert to 8-bit unsigned */
			s += 0x80;
			
			/* clip */
			if s > 0xFE {/* 0xFF causes static on some audio systems */
				stream.pointee = 0xFE
			} else if s < 0x00 {
				stream.pointee = 0
			} else {
				stream.pointee = UInt8(s)
			}
			stream = stream.successor()
		}
	}

	fileprivate(set) var error: String? = nil
	
	deinit {
		if aPlaying {
			SDL_CloseAudio();
		} else if bogusAudio != nil {
			bogus_running = false
			SDL_WaitThread(bogusAudio, nil);
			bogusAudio = nil
		}
	}
}
