//
//  Mac_Wave.swift
//  Maelstrom
//
//  Created by C.W. Betts on 11/1/15.
//
//

import Foundation

//MARK: - Define values for Macintosh SND format
//MARK: Different sound header formats 
private let FORMAT_1: UInt16 = 0x0001
private let FORMAT_2: UInt16 = 0x0002

//MARK: The different types of sound data
private let SAMPLED_SND: UInt16 = 0x0005

//MARK: Initialization commands
private let MONO_SOUND: UInt32 = 0x00000080
private let STEREO_SOUND: UInt32 = 0x000000A0

//MARK: The different sound commands; we only support BUFFER_CMD
//Different from `BUFFER_CMD`?
private let SOUND_CMD: UInt16 = 0x8050
private let BUFFER_CMD: UInt16 = 0x8051

//MARK: Different original sampling rates -- rate = (#define)>>16
///44100.0
private let rate44khz: UInt32 = 0xAC440000
///22254.5
private let rate22khz: UInt32 = 0x56EE8BA3
///11127.3
private let rate11khz: UInt32 = 0x2B7745D0
///11127.3 (?)
private let rate11khz2: UInt32 = 0x2B7745D1

private let stdSH: UInt8 = 0x00
private let extSH: UInt8 = 0xFF
private let cmpSH: UInt8 = 0xFE

//MARK: -

private protocol ByteSwappable {
	var bigEndian: Self { get }
	var littleEndian: Self { get }
	var byteSwapped: Self { get }
}

extension Int16: ByteSwappable { }
extension UInt16: ByteSwappable { }
extension Int32: ByteSwappable { }
extension UInt32: ByteSwappable { }

private func sndCopy<X where X: ByteSwappable>(inout V: X, inout _ D: UnsafeMutablePointer<UInt8>) {
	V = UnsafeMutablePointer<X>(D).memory
	D += sizeof(X)
	V = V.bigEndian
}

private func sndCopy<X where X: ByteSwappable>(inout V: X, inout _ D: UnsafePointer<UInt8>) {
	V = UnsafeMutablePointer<X>(D).memory
	D += sizeof(X)
	V = V.bigEndian
}


final class Wave {
	///The SDL-ready audio specification
	var spec = SDL_AudioSpec()
	private var soundData: UnsafeMutablePointer<UInt8> = nil
	private var soundDataLen: UInt32 = 0
	
	///Current position of the WAVE file
	private var soundptr: UnsafeMutablePointer<UInt8> = nil
	private var soundlen: Int32 = 0
	
	init() {
		Init()
	}
	
	convenience init(waveURL wavefile: NSURL, desiredRate: Int32? = nil) {
		self.init()
		load(waveURL: wavefile, desiredRate: desiredRate)
	}
	
	convenience init(snd: NSData, desiredRate: Int32? = nil) {
		self.init()
		load(sndData: snd, desiredRate: desiredRate)
	}
	
	///Load WAVE resources, converting to the desired sample rate
	func load(waveURL wavefile: NSURL, desiredRate: Int32? = nil) -> Bool {
		var samples: UnsafeMutablePointer<UInt8> = nil
		
		/* Free any existing WAVE data */
		Free();
		Init();
		
		/* Load the WAVE file */
		if ( SDL_LoadWAV(wavefile.fileSystemRepresentation, &spec, &samples, &soundDataLen) == nil ) {
			error = String(SDL_GetError())
			return false
		}
		/* Copy malloc()'d data to new'd data */
		soundData = UnsafeMutablePointer<UInt8>(malloc(Int(soundDataLen)))
		memcpy(soundData, samples, Int(soundDataLen));
		SDL_FreeWAV(samples);
		
		/* Set the desired sample frequency */
		frequency = desiredRate ?? 0
		
		/* Rewind and go! */
		rewind();
		return true;
	}
	
	/// Most of this information came from the "Inside Macintosh" book series
	func load(sndData snd: NSData, desiredRate: Int32? = nil) -> Bool {
		var snd_version: UInt16 = 0
		var snd_channels: Int32 = 0
		var samples: UnsafeMutablePointer<UInt8> = nil
		var desired_rate = desiredRate ?? 0
		
		/* Free any existing WAVE data */
		Free();
		Init();
		
		/* Start loading the WAVE from the SND */
		var data = UnsafePointer<UInt8>(snd.bytes)
		sndCopy(&snd_version, &data);
		
		snd_channels = 1;			/* Is this always true? */
		if ( snd_version == FORMAT_1 ) {
			/* Number of sound data types */
			var n_types: UInt16 = 0
			/* First sound data type */
			var f_type: UInt16 = 0
			/* Initialization option (unused) */
			var init_op: UInt32 = 0
			
			sndCopy(&n_types, &data);
			if ( n_types != 1 ) {
				error = "Multi-type sound not supported"
				return false
			}
			sndCopy(&f_type, &data);
			if ( f_type != SAMPLED_SND ) {
				error = "Not a sampled sound resource"
				return false
			}
			sndCopy(&init_op, &data);
		} else if ( snd_version == FORMAT_2 ) {
			/* (unused) */
			var ref_cnt: UInt16 = 0
			
			sndCopy(&ref_cnt, &data);
		} else {
			error = String(format: "Unknown sound format: 0x%X", snd_version)
			return false;
		}
		
		/* Next is the Sound commands section */
		do {
			var num_cmds: UInt16 = 0	/* Number of sound commands */
			var command: UInt16 = 0		/* The first sound command */
			var param1: UInt16 = 0		/* BUFFER_CMD parameter 1 */
			var param2: UInt32 = 0		/* Offset to sampled data */
			
			sndCopy(&num_cmds, &data);
			if num_cmds != 1 {
				error = "Multi-command sound not supported"
				return false;
			}
			sndCopy(&command, &data);
			if ( (command != BUFFER_CMD) && (command != SOUND_CMD) ) {
				error = String(format: "Unknown sound command: 0x%X\n", command);
				return false;
			}
			sndCopy(&param1, &data);
			/* Param1 is ignored (should be 0x0000) */
			
			sndCopy(&param2, &data);
			/* Set 'data' to the offset of the sampled data */
			if Int(param2) > snd.length {
				error = "Offset too large -- corrupt sound?"
				return false;
			}
			data = UnsafePointer<UInt8>(snd.bytes).advancedBy(Int(param2))
		}
		
		/* Next is the sampled sound header */
		do {
			var sample_offset: UInt32 = 0
			var num_samples: UInt32 = 0
			var sample_rate: UInt32 = 0
			var loop_start: UInt32 = 0
			var loop_end: UInt32 = 0
			var encoding: UInt8 = 0
			//var freq_base: UInt8 = 0
			
			sndCopy(&sample_offset, &data);
			/* FIXME: What's the interpretation of this offset? */
			if sample_offset != 0 {
				error = "Sound samples don't immediately follow header"
				return false
			}
			sndCopy(&num_samples, &data);
			sndCopy(&sample_rate, &data);
			/* Sound loops are ignored for now */
			sndCopy(&loop_start, &data);
			sndCopy(&loop_end, &data);
			encoding = data.memory
			data++
			if ( encoding != stdSH ) {
				error = String(format: "Non-standard sound encoding: 0x%X", encoding)
				return false;
			}
			/* Frequency base might be used later */
			//freq_base = data.memory
			data++
			
			/* Now allocate room for the sound */
			if Int(num_samples) > snd.length - data.distanceTo(UnsafePointer<UInt8>(snd.bytes)) {
				error = "truncated sound resource"
				return false;
			}
			
			/* Convert the audio data to desired sample rates */
			
			samples = UnsafeMutablePointer(data)
			switch ( sample_rate ) {
			case rate11khz, rate11khz2:
				/* Assuming 8-bit mono samples */
				if ( desired_rate == 0 ) {
					desired_rate = 11025;
				}
				num_samples =
				Wave.convertRate(sample_rate>>16, rateOut: desired_rate,
				samples: &samples, countOfSamples: num_samples, sampleSize: 1);
				break;
			case rate22khz:
				/* Assuming 8-bit mono samples */
				if ( desired_rate == 0 ) {
					desired_rate = 22050;
				}
				num_samples =
				Wave.convertRate(sample_rate>>16, rateOut: desired_rate,
				samples: &samples, countOfSamples: num_samples, sampleSize: 1);
				break;
			case rate44khz:
				fallthrough
			default:
				if desired_rate == 0 {
					desired_rate = Int32(sample_rate>>16);
					break;
				}
				num_samples =
					Wave.convertRate(sample_rate>>16, rateOut: desired_rate,
						samples: &samples, countOfSamples: num_samples, sampleSize: 1);
				break;
			}
			sample_rate = UInt32(desired_rate);
			
			/* Fill in the audio spec */
			spec.freq = desired_rate;
			spec.format = SDL_AudioFormat(AUDIO_U8)		/* The only format? */
			spec.channels = UInt8(snd_channels);
			spec.samples = 4096;
			spec.callback = nil;
			spec.userdata = nil;
			
			/* Save the audio data */
			soundDataLen = num_samples*UInt32(snd_channels)
			if samples == UnsafeMutablePointer(data) {
				soundData = UnsafeMutablePointer<UInt8>(malloc(Int(soundDataLen)))
				memcpy(soundData, samples, Int(soundDataLen));
			} else {
				soundData = samples;
			}
		}
		rewind();
		return true
	}
	
	func rewind() {
		soundptr = soundData;
		soundlen = Int32(soundDataLen)
	}
	
	func forward(distance: UInt32) {
		soundlen -= Int32(distance)
		soundptr += Int(distance)
	}
	
	var dataLeft: UInt32 {
		return UInt32(soundlen > 0 ? soundlen : 0)
	}
	
	var data: UnsafeMutablePointer<UInt8> {
		if soundlen > 0 {
			return soundptr
		}
		return nil
	}
	
	var frequency: Int32 {
		get {
			return spec.freq
		}
		set(desired_rate) {
			if (desired_rate > 0) && (desired_rate != spec.freq) {
				var samples = soundData
				let samplesize = sampleSize
				let datalen: UInt32
				
				datalen = Wave.convertRate(UInt32(spec.freq), rateOut: desired_rate,
				samples: &samples, countOfSamples: soundDataLen/UInt32(samplesize), sampleSize: UInt8(samplesize));
				if samples != soundData {
					/* Create new sound data */
					free(soundData)
					soundData = samples
					soundDataLen = datalen * UInt32(samplesize)
					
					/* Adjust the format */
					spec.freq = desired_rate;
				}
			}
		}
	}
	
	var sampleSize: UInt16 {
		return (spec.format & UInt16(SDL_AUDIO_MASK_BITSIZE) / 8) * UInt16(spec.channels)
	}
	
	var bitsPerSample: Int {
		return Int(spec.format & UInt16(SDL_AUDIO_MASK_BITSIZE))
	}
	
	var stereo: Bool {
		return spec.channels == 2
	}
	
	private func Init() {
		soundData = nil;
		soundDataLen = 0
		error = nil;
	}
	
	private func Free() {
		if soundData != nil {
			free(soundData)
			soundData = nil
			soundDataLen = 0
		}
	}
	
	deinit {
		if soundData != nil {
			free(soundData)
			soundData = nil
		}
	}
	
	///Utility function
	private class func convertRate(rate_in: UInt32, rateOut rate_out: Int32,
		samples: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>>, countOfSamples  n_samples: UInt32, sampleSize s_size: UInt8) -> UInt32 {
			var iPos: Double = 0
			var iSize = 0.0
			var oPos: UInt32 = 0
			var nIn: UInt32 = 0
			var nOut: UInt32 = 0
			var input: UnsafeMutablePointer<UInt8> = nil
			var output: UnsafeMutablePointer<UInt8> = nil
			
			nIn = UInt32(n_samples)*UInt32(s_size)
			input = samples.memory
			nOut = (UInt32(Double(rate_out)/Double(rate_in))*n_samples)+1;
			output = UnsafeMutablePointer<UInt8>(malloc(Int(nOut) * Int(s_size)))
			iSize = Double(rate_in)/Double(rate_out)*Double(s_size)
			#if CONVERTRATE_DEBUG
				print(String(format: "%g seconds of input", Double(n_samples) / Double(rate_in)))
				print(String(format: "Input rate: %hu, Output rate: %hu, Input increment: %g\n", rate_in, rate_out, i_size/s_size))
				print(String(format: "%g seconds of output\n", Double(nOut)/Double(rate_out)))
			#endif
			for ( iPos = 0, oPos = 0; Uint32(iPos) < nIn; ) {
				#if CONVERTRATE_DEBUG
					if ( opos >= n_out*s_size ) {print("Warning: buffer output overflow!");}
				#endif
				memcpy(&output[Int(oPos)], &input[Int(iPos)], Int(s_size));
				iPos += iSize;
				oPos += UInt32(s_size);
			}
			samples.memory = output;
			return oPos/UInt32(s_size)
	}

	private(set) var error: String? = nil
}
