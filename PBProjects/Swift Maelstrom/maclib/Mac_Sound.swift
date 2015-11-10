//
//  Mac_Sound.swift
//  Maelstrom
//
//  Created by C.W. Betts on 11/2/15.
//
//

import Foundation

///Software volume ranges from `0 - 8`
let MAX_VOLUME: UInt8 = 8
///4 sound mixing channels, limit 128
let NUM_CHANNELS = 4
///Convert the SNDs to this frequency
let DSP_FREQUENCY:Int32 = 11025

private var bogus_running = false

private func fillAudio(selfPtr: UnsafeMutablePointer<Void>, bytes: UnsafeMutablePointer<Uint8>, length: Int32) -> Void {
	//ugly hack to get ourself back
	let ourself: Sound = {
		let cOpPtr = COpaquePointer(selfPtr)
		
		return Unmanaged.fromOpaque(cOpPtr).takeUnretainedValue()
	}()
	
	ourself.fillAudioU8(bytes, length)
}

private func bogusAudioThread(data: UnsafeMutablePointer<Void>) -> Int32 {
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
	let spec = UnsafeMutablePointer<SDL_AudioSpec>(data)
	if spec.memory.callback == nil {
		for ( ; ; ) {
		Delay(60*60*60);	/* Delay 1 hour */
		}
	}
	let fill: SDL_AudioCallback? = spec.memory.callback
	playticks = (UInt32(spec.memory.samples) * 1000) / UInt32(spec.memory.freq)
	/* Fill in the spec */
	spec.memory.size = UInt32(spec.memory.format&0xFF) / 8;
	spec.memory.size *= UInt32(spec.memory.channels)
	spec.memory.size *= UInt32(spec.memory.samples)
	stream = [UInt8](count: Int(spec.memory.size), repeatedValue: 0)
	
	while bogus_running {
		then = SDL_GetTicks();
		
		/* Fill buffer */
		if let fill = fill {
			fill(spec.memory.userdata, &stream, Int32(spec.memory.size))
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
	
	enum Errors: ErrorType {
		case NoSoundResources
		case ResourceLoadError(String)
	}
	
	private struct Channel {
		var ID: UInt16 = 0
		var priority: Int16 = 0
		///Signed, so race conditions can make it < 0
		var len: Int = 0
		var src: UnsafeMutablePointer<UInt8> = nil
		var callback: ((channel: UInt8) -> Void)? = nil
	} //channels[NUM_CHANNELS];
	
	private var bogusAudio: SDL_ThreadPtr = nil
	
	private var channels = [Channel](count: NUM_CHANNELS, repeatedValue: Channel())
	
	private var intVol: UInt8 = 0
	var volume: UInt8 {
		get {
			return intVol
		}
		set(aVol) {
			var vol = aVol
			
			var active = playing;
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
			if ( vol > MAX_VOLUME ) {
				vol = MAX_VOLUME;
			}
			intVol = vol;
			
			if active && (volume == 0) {
				if ( playing ) {
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
			playing = active;
		}
	}
	
	private var spec: SDL_AudioSpec = SDL_AudioSpec()
	private var playing = false
	private(set) var waves = [UInt16: Wave]()
	
	///Stop mixing on all channels
	func haltAllSound() {
		for i in 0 ..< NUM_CHANNELS {
			haltSound(channel: i)
		}
	}
	
	///Stop mixing on the requested channel
	func haltSound(channel channel: Int) {
		channels[channel].len = 0
	}
	
	/// Find out if a sound is playing on a channel 
	func playing(sndID: UInt16 = 0, inout channel: UInt8) -> Bool {
		for i in 0..<NUM_CHANNELS {
			guard channels[i].len > 0 else {
				continue
			}
			
			if ( (sndID == 0) || (sndID == channels[i].ID) ) {
				channel = UInt8(i)
				return true;
			}
		}
		
		return false
	}

	init(soundFileURL soundfile: NSURL, volume vol: UInt8 = 4) throws {
		let sndResType = MaelOSType(stringValue: "snd ")!
		let soundres = try Mac_Resource(fileURL: soundfile)
		var p = 0
		if soundres.countOfResources(type: sndResType) == 0 {
			throw Errors.NoSoundResources
		}
		
		let ids = try! soundres.resourceIDs(type: sndResType)
		
		var wave: Wave!
		
		for id in ids {
			let snd = try soundres.resource(type: sndResType, id: id)
			wave = try Wave(snd: snd, desiredRate: DSP_FREQUENCY)
			waves[id] = wave
		}
		
		spec = wave.spec
		
		/* Allow ~ 1/30 second time-lag in audio buffer -- samples is x^2  */
		spec.samples = UInt16(Int(wave.frequency) * Int(wave.sampleSize) / 30)
		for ( p = 0; spec.samples > 1; ++p ) {
			spec.samples /= 2;
		}
		++p;
		for _ in 0..<p {
			spec.samples *= 2;
		}
		spec.callback = fillAudio;
		//ugly hack to get to pass ourself as a parameter
		let unMan = Unmanaged.passUnretained(self)
		spec.userdata = UnsafeMutablePointer(unMan.toOpaque())
		
		/* Empty the channels and start the music :-) */
		haltAllSound()
		if ( vol == 0 ) {
			bogus_running = true
			bogusAudio = SDL_CreateThread(bogusAudioThread, "BogusAudioThread", &spec);
		} else {
			volume = vol
		}
	}

	func priorityOfChannel(channel: UInt8) -> Int16 {
		if channels[Int(channel)].len > 0 {
			return channels[Int(channel)].priority
		}
		
		return -1
	}

	/// Play the requested sound
	func playSound(sndID: UInt16, priority: UInt8 = 0, callback: ((channel: UInt8) -> ())? = nil) -> Bool {
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
	func playSound(sndID: UInt16, priority: UInt8, channel: UInt8, callback: ((channel: UInt8) -> ())? = nil) -> Bool {
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
			printf("Playing sound %hu on channel %d\n", sndID, channel);
		#endif
		return true;
	}
	
	///This has to be a very fast routine, otherwise sound will lag and crackle
	private func fillAudioU8(var stream: UnsafeMutablePointer<UInt8>, var _ length: Int32) {
		//int i, s;
		
		/* Mix in each of the channels, assuming 8-bit unsigned audio data */
		while length-- != 0 {
			var s = 0;
			for i in 0..<NUM_CHANNELS {
				if channels[i].len > 0 {
					/*
					Possible race condition:
					If the channel is halted here,
					len = 0 then we do '--len'
					len = -1, but that's okay.
					*/
					--channels[i].len;
					s += Int(channels[i].src.memory &- 0x80)
					++channels[i].src;
					/*
					Possible race condition:
					If a sound is played here,
					len > 0, then we do 'if len <= 0'
					We never call back on channel.. bad.
					*/
					if channels[i].len <= 0 {
						#if DEBUG_SOUND
							printf("Channel %d finished\n", i);
						#endif
						/* This is critical */
						if let callback = channels[i].callback {
							callback(channel: UInt8(i))
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
				stream.memory = 0xFE
				stream++
			} else if s < 0x00 {
				stream.memory = 0
				stream++
			} else {
				stream.memory = UInt8(s)
				stream++
			}
		}
	}

	private(set) var error: String? = nil
	
	deinit {
		if playing {
			SDL_CloseAudio();
		} else if bogusAudio != nil {
			bogus_running = false
			SDL_WaitThread(bogusAudio, nil);
			bogusAudio = nil
		}
	}
}
