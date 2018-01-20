//
//  Mac_Wave.swift
//  Maelstrom
//
//  Created by C.W. Betts on 11/1/15.
//
//

import Foundation
import SDL2

//MARK: Define values for Macintosh SND format
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

private func sndCopy<X>(_ V: inout X, _ D: inout UnsafeMutablePointer<UInt8>) where X: ByteSwappable {
	V = D.withMemoryRebound(to: X.self, capacity: 1) { (aPtr) -> X in
		return aPtr.pointee
	}
	D = D.advanced(by: MemoryLayout<X>.size)
	V = V.bigEndian
}

private func sndCopy<X>(_ V: inout X, _ D: inout UnsafePointer<UInt8>) where X: ByteSwappable {
	V = D.withMemoryRebound(to: X.self, capacity: 1) { (aPtr) -> X in
		return aPtr.pointee
	}
	D = D.advanced(by: MemoryLayout<X>.size)
	V = V.bigEndian
}


final class Wave {
	///The SDL-ready audio specification
	fileprivate(set) var spec = SDL_AudioSpec()
	fileprivate var soundData: UnsafeMutablePointer<UInt8>? = nil
	fileprivate var soundDataLen: UInt32 = 0
	
	///Current position of the WAVE file
	fileprivate var soundptr: UnsafeMutablePointer<UInt8>? = nil
	fileprivate var soundlen: Int32 = 0
	
	enum Errors: Error {
		case sdlError(String)
		case multiTypeSound
		case unknownSoundFormat(UInt16)
		case unknownSoundCommand(UInt16)
		case offsetTooLarge
		case nonStandardSoundEncoding(UInt8)
		case truncatedSoundResource
		case notSampledSound
		case samplesDoNotFollowHeader
		case multiCommandNotSupported
	}
	
	init() {
		Init()
	}
	
	convenience init(waveURL wavefile: URL, desiredRate: Int32? = nil) throws {
		self.init()
		try load(waveURL: wavefile, desiredRate: desiredRate)
	}
	
	convenience init(snd: Data, desiredRate: Int32? = nil) throws {
		self.init()
		try load(sndData: snd, desiredRate: desiredRate)
	}
	
	///Load WAVE resources, converting to the desired sample rate
	func load(waveURL wavefile: URL, desiredRate: Int32? = nil) throws {
		var samples: UnsafeMutablePointer<UInt8>? = nil
		
		/* Free any existing WAVE data */
		Free();
		Init();
		
		/* Load the WAVE file */
		if SDL_LoadWAV((wavefile as NSURL).fileSystemRepresentation, &spec, &samples, &soundDataLen) == nil {
			throw Errors.sdlError(String(cString: SDL_GetError()))
		}
		/* Copy malloc()'d data to new'd data */
		soundData = malloc(Int(soundDataLen)).assumingMemoryBound(to: UInt8.self)
		memcpy(soundData, samples, Int(soundDataLen));
		SDL_FreeWAV(samples);
		
		/* Set the desired sample frequency */
		frequency = desiredRate ?? 0
		
		/* Rewind and go! */
		rewind();
	}
	
	/// Most of this information came from the "Inside Macintosh" book series
	func load(sndData snd: Data, desiredRate: Int32? = nil) throws {
		var snd_version: UInt16 = 0
		var snd_channels: Int32 = 0
		var samples: UnsafeMutablePointer<UInt8>? = nil
		var desired_rate = desiredRate ?? 0
		
		/* Free any existing WAVE data */
		Free();
		Init();
		
		/* Start loading the WAVE from the SND */
		var data = (snd as NSData).bytes.bindMemory(to: UInt8.self, capacity: snd.count)
		sndCopy(&snd_version, &data);
		
		snd_channels = 1;			/* Is this always true? */
		if snd_version == FORMAT_1 {
			/* Number of sound data types */
			var n_types: UInt16 = 0
			/* First sound data type */
			var f_type: UInt16 = 0
			/* Initialization option (unused) */
			var init_op: UInt32 = 0
			
			sndCopy(&n_types, &data)
			if n_types != 1 {
				throw Errors.multiTypeSound
			}
			sndCopy(&f_type, &data)
			if f_type != SAMPLED_SND {
				throw Errors.notSampledSound
			}
			sndCopy(&init_op, &data);
		} else if snd_version == FORMAT_2 {
			/* (unused) */
			var ref_cnt: UInt16 = 0
			
			sndCopy(&ref_cnt, &data);
		} else {
			throw Errors.unknownSoundFormat(snd_version)
		}
		
		/* Next is the Sound commands section */
		do {
			var num_cmds: UInt16 = 0	/* Number of sound commands */
			var command: UInt16 = 0		/* The first sound command */
			var param1: UInt16 = 0		/* BUFFER_CMD parameter 1 */
			var param2: UInt32 = 0		/* Offset to sampled data */
			
			sndCopy(&num_cmds, &data);
			if num_cmds != 1 {
				throw Errors.multiCommandNotSupported
			}
			sndCopy(&command, &data);
			if command != BUFFER_CMD && command != SOUND_CMD {
				throw Errors.unknownSoundCommand(command)
			}
			sndCopy(&param1, &data);
			/* Param1 is ignored (should be 0x0000) */
			
			sndCopy(&param2, &data);
			/* Set 'data' to the offset of the sampled data */
			if Int(param2) > snd.count {
				throw Errors.offsetTooLarge
			}
			data = (snd as NSData).bytes.bindMemory(to: UInt8.self, capacity: snd.count).advanced(by: Int(param2))
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
			// FIXME: What's the interpretation of this offset?
			if sample_offset != 0 {
				throw Errors.samplesDoNotFollowHeader
			}
			sndCopy(&num_samples, &data);
			sndCopy(&sample_rate, &data);
			/* Sound loops are ignored for now */
			sndCopy(&loop_start, &data);
			sndCopy(&loop_end, &data);
			encoding = data.pointee
			data = data.successor()
			if encoding != stdSH {
				throw Errors.nonStandardSoundEncoding(encoding)
			}
			/* Frequency base might be used later */
			//freq_base = data.memory
			data = data.successor()
			
			/* Now allocate room for the sound */
			if Int(num_samples) > snd.count - data.distance(to: (snd as NSData).bytes.bindMemory(to: UInt8.self, capacity: snd.count)) {
				throw Errors.truncatedSoundResource
			}
			
			/* Convert the audio data to desired sample rates */
			
			samples = UnsafeMutablePointer(mutating: data)
			switch sample_rate {
			case rate11khz, rate11khz2:
				/* Assuming 8-bit mono samples */
				if ( desired_rate == 0 ) {
					desired_rate = 11025;
				}
				num_samples =
					convertRate(sample_rate>>16, rateOut: desired_rate,
						samples: &samples!, countOfSamples: num_samples, sampleSize: 1);
				
			case rate22khz:
				/* Assuming 8-bit mono samples */
				if ( desired_rate == 0 ) {
					desired_rate = 22050;
				}
				num_samples =
				convertRate(sample_rate>>16, rateOut: desired_rate,
				samples: &samples!, countOfSamples: num_samples, sampleSize: 1);
				
			case rate44khz:
				fallthrough
			default:
				if desired_rate == 0 {
					desired_rate = Int32(sample_rate>>16);
					break;
				}
				num_samples =
					convertRate(sample_rate>>16, rateOut: desired_rate,
						samples: &samples!, countOfSamples: num_samples, sampleSize: 1);
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
			if samples == UnsafeMutablePointer(mutating: data) {
				soundData = malloc(Int(soundDataLen)).assumingMemoryBound(to: UInt8.self)
				memcpy(soundData, samples, Int(soundDataLen));
			} else {
				soundData = samples;
			}
		}
		rewind();
	}
	
	func rewind() {
		soundptr = soundData;
		soundlen = Int32(soundDataLen)
	}
	
	func forward(_ distance: UInt32) {
		soundlen -= Int32(distance)
		soundptr = soundptr?.advanced(by: Int(distance))
	}
	
	var dataLeft: UInt32 {
		return UInt32(soundlen > 0 ? soundlen : 0)
	}
	
	var data: UnsafeMutablePointer<UInt8>? {
		if soundlen > 0 {
			return soundptr!
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
				
				datalen = convertRate(UInt32(spec.freq), rateOut: desired_rate,
				samples: &samples!, countOfSamples: soundDataLen/UInt32(samplesize), sampleSize: UInt8(samplesize));
				if samples != soundData {
					/* Create new sound data */
					//free(soundData)
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
	
	fileprivate func Init() {
		soundData = nil;
		soundDataLen = 0
	}
	
	fileprivate func Free() {
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
	
}

///Utility function
private func convertRate(_ rate_in: UInt32, rateOut rate_out: Int32, samples: inout UnsafeMutablePointer<UInt8>, countOfSamples  n_samples: UInt32, sampleSize s_size: UInt8) -> UInt32 {
		var iPos: Double = 0
		var oPos: UInt32 = 0
		
		let nIn = UInt32(n_samples)*UInt32(s_size)
		let input = samples
		let nOut = UInt32((Double(rate_out)/Double(rate_in))*Double(n_samples))+1;
		let output = malloc(Int(nOut) * Int(s_size)).assumingMemoryBound(to: UInt8.self)
		let iSize = Double(rate_in)/Double(rate_out)*Double(s_size)
		#if CONVERTRATE_DEBUG
			print(String(format: "%g seconds of input", Double(n_samples) / Double(rate_in)))
			print(String(format: "Input rate: %hu, Output rate: %hu, Input increment: %g", rate_in, rate_out, iSize/Double(s_size)))
			print(String(format: "%g seconds of output", Double(nOut)/Double(rate_out)))
		#endif
		repeat {
			#if CONVERTRATE_DEBUG
				if oPos >= nOut * UInt32(s_size) {
					print("Warning: buffer output overflow!")
				}
			#endif
			memcpy(output.advanced(by: Int(oPos)), input.advanced(by: Int(iPos)), Int(s_size));
			iPos += iSize;
			oPos += UInt32(s_size);
		} while UInt32(iPos) < nIn
		samples = output;
		return oPos/UInt32(s_size)
}

