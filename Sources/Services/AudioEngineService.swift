import Foundation
import AVFoundation
import AudioToolbox

class AudioEngineService: ObservableObject {
    static let shared = AudioEngineService()
    
    private var audioEngine: AVAudioEngine
    private var synthUnit: AVAudioUnitSampler
    private var sequencer: AVAudioSequencer?
    
    @Published var isPlaying = false
    @Published var currentPlaybackTime: TimeInterval = 0.0
    
    private var timer: Timer?
    
    // Available Instruments (General MIDI Program numbers)
    struct Instrument: Identifiable, Hashable {
        let id: UInt8
        let name: String
        let icon: String
    }
    
    let instruments: [Instrument] = [
        Instrument(id: 4, name: "Warm Rhodes", icon: "pianokeys"),
        Instrument(id: 5, name: "FM Crystal EP", icon: "sparkles"),
        Instrument(id: 11, name: "Vibe Dream", icon: "waveform.path"),
        Instrument(id: 8, name: "Star Celesta", icon: "star.fill"),
        Instrument(id: 10, name: "Nostalgia Box", icon: "music.note"),
        Instrument(id: 14, name: "Tubular Chime", icon: "bell.fill")
    ]
    
    @Published var selectedInstrumentId: UInt8 = 4 {
        didSet {
            changeInstrument(program: selectedInstrumentId)
        }
    }
    
    private init() {
        audioEngine = AVAudioEngine()
        
        // Configure AVAudioSession for playback (ignores the physical Silent/Mute switch)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [])
        try? session.setActive(true)
        
        // Use Apple's AVAudioUnitSampler which supports SoundFont .sf2 files directly on iOS!
        synthUnit = AVAudioUnitSampler()
        audioEngine.attach(synthUnit)
        audioEngine.connect(synthUnit, to: audioEngine.mainMixerNode, format: audioEngine.mainMixerNode.outputFormat(forBus: 0))
        
        try? audioEngine.start()
    }
    
    func playMIDI(trackName: String, tempoMultiplier: Double, startTime: Double, duration: Double) {
        stopMIDI()
        
        guard let fileURL = Bundle.main.url(forResource: trackName, withExtension: "mid") else {
            print("MIDI file not found in bundle: \(trackName)")
            return
        }
        
        let newSequencer = AVAudioSequencer(audioEngine: audioEngine)
        do {
            // Load and sanitize the MIDI file (strips Program Changes on a 100% public, safe C-API sequence)
            try loadAndSanitizeMIDI(from: fileURL, into: newSequencer)
            
            // Route all tracks to our synthUnit explicitly
            for track in newSequencer.tracks {
                track.destinationAudioUnit = synthUnit
            }
            
            newSequencer.prepareToPlay()
            
            // Set current sequencer
            self.sequencer = newSequencer
            
            // Apply tempo rate directly on the sequencer (much safer and enables real-time updates)
            newSequencer.rate = Float(tempoMultiplier)
            
            // Start playing from offset (trimmed start)
            try newSequencer.start()
            newSequencer.currentPositionInSeconds = startTime
            
            // Load the selected instrument SoundBank preset BEFORE playing notes
            changeInstrument(program: selectedInstrumentId)
            
            isPlaying = true
            currentPlaybackTime = startTime
            
            // Start UI update timer
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self, let seq = self.sequencer else { return }
                self.currentPlaybackTime = seq.currentPositionInSeconds
                
                // Handle auto stop at trim duration
                if self.currentPlaybackTime >= (startTime + duration) || self.currentPlaybackTime >= seq.seconds(forBeats: seq.beats(forSeconds: startTime) + 400.0) {
                    self.stopMIDI()
                }
            }
        } catch {
            print("Failed to play MIDI: \(error)")
        }
    }
    
    func stopMIDI() {
        timer?.invalidate()
        timer = nil
        sequencer?.stop()
        sequencer = nil
        isPlaying = false
        currentPlaybackTime = 0.0
    }
    
    // Updates tempo rate in real-time
    func updateTempo(multiplier: Double) {
        sequencer?.rate = Float(multiplier)
    }
    
    private func changeInstrument(program: UInt8) {
        // Load the designated instrument from our bundled high-quality TimGM6mb.sf2 SoundFont!
        guard let bankURL = Bundle.main.url(forResource: "TimGM6mb", withExtension: "sf2") else {
            print("SoundFont TimGM6mb.sf2 not found in bundle!")
            return
        }
        
        do {
            // Load the SoundFont instrument preset into the Sampler Unit (ignores channel overrides)
            try synthUnit.loadSoundBankInstrument(
                at: bankURL,
                program: program,
                bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                bankLSB: UInt8(kAUSampler_DefaultBankLSB)
            )
            print("Successfully loaded SoundFont Instrument program: \(program)")
        } catch {
            print("Failed to load SoundFont instrument program \(program): \(error)")
        }
    }
    
    // 100% safe, crash-free public AudioToolbox C-API loader.
    // Loads MIDI, strips Program Changes, and exports a clean temporary MIDI to feed AVAudioSequencer.
    private func loadAndSanitizeMIDI(from fileURL: URL, into targetSequencer: AVAudioSequencer) throws {
        // 1. Create raw C MusicSequence
        var sequence: MusicSequence?
        var status = NewMusicSequence(&sequence)
        guard status == noErr, let seq = sequence else {
            throw NSError(domain: "AudioEngineService", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Failed to create MusicSequence"])
        }
        
        // 2. Load the original MIDI file from bundle into C sequence
        status = MusicSequenceFileLoad(seq, fileURL as CFURL, .midiType, [])
        guard status == noErr else {
            DisposeMusicSequence(seq)
            throw NSError(domain: "AudioEngineService", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Failed to load MIDI file"])
        }
        
        // 3. Strip all Program Change events from all tracks using event iterators
        var trackCount: UInt32 = 0
        MusicSequenceGetTrackCount(seq, &trackCount)
        
        for i in 0..<trackCount {
            // Strip Program Changes from ALL tracks to ensure 100% reliable instrument changes
            let shouldStrip = true
            
            if shouldStrip {
                var musicTrack: MusicTrack?
                let trackStatus = MusicSequenceGetIndTrack(seq, i, &musicTrack)
                if trackStatus == noErr, let track = musicTrack {
                    var iterator: MusicEventIterator?
                    NewMusicEventIterator(track, &iterator)
                    
                    var hasEvent: DarwinBoolean = false
                    MusicEventIteratorHasCurrentEvent(iterator!, &hasEvent)
                    
                    while hasEvent.boolValue {
                        var timeStamp: MusicTimeStamp = 0
                        var eventType: MusicEventType = 0
                        var eventData: UnsafeRawPointer?
                        var eventDataSize: UInt32 = 0
                        
                        MusicEventIteratorGetEventInfo(iterator!, &timeStamp, &eventType, &eventData, &eventDataSize)
                        
                        if eventType == kMusicEventType_MIDIChannelMessage {
                            if let channelMessage = eventData?.assumingMemoryBound(to: MIDIChannelMessage.self).pointee {
                                let statusByte = channelMessage.status
                                let isProgramChange = (statusByte & 0xF0) == 0xC0
                                
                                // Strip all Program Change events on all channels
                                if isProgramChange {
                                    // Delete Program Change event
                                    MusicEventIteratorDeleteEvent(iterator!)
                                } else {
                                    MusicEventIteratorNextEvent(iterator!)
                                }
                            } else {
                                MusicEventIteratorNextEvent(iterator!)
                            }
                        } else {
                            MusicEventIteratorNextEvent(iterator!)
                        }
                        
                        MusicEventIteratorHasCurrentEvent(iterator!, &hasEvent)
                    }
                    
                    DisposeMusicEventIterator(iterator!)
                }
            }
        }
        
        // 4. Save sanitized MIDI sequence to a temporary location
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("sanitized_temp.mid")
        try? FileManager.default.removeItem(at: tempURL)
        
        status = MusicSequenceFileCreate(seq, tempURL as CFURL, .midiType, .eraseFile, 0)
        DisposeMusicSequence(seq) // Dispose immediately to prevent memory leak
        
        guard status == noErr else {
            throw NSError(domain: "AudioEngineService", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Failed to save sanitized MIDI file"])
        }
        
        // 5. Feed the sanitized temporary MIDI file into the AVAudioSequencer
        try targetSequencer.load(from: tempURL, options: [])
    }
    
    // Premium 온디바이스 벨소리 렌더러 (AVAudioEngine manualRenderingMode 기반)
    func renderToM4R(trackName: String, startTime: Double, duration: Double, tempoMultiplier: Double, applyFade: Bool, completion: @escaping (URL?) -> Void) {
        // 1. Create offline render engine
        let renderEngine = AVAudioEngine()
        let renderSynth = AVAudioUnitSampler()
        renderEngine.attach(renderSynth)
        
        let outputFormat = renderEngine.mainMixerNode.outputFormat(forBus: 0)
        renderEngine.connect(renderSynth, to: renderEngine.mainMixerNode, format: outputFormat)
        
        let fileManager = FinderFileManager()
        _ = fileManager // Reference to suppress warning if needed
        
        guard let midiURL = Bundle.main.url(forResource: trackName, withExtension: "mid") else {
            print("MIDI file not found in bundle for rendering: \(trackName)")
            completion(nil)
            return
        }
        
        let defaultFileManager = FileManager.default
        // Prepare output .m4r (Apple Ringtone format is technically AAC inside M4A container with .m4r extension)
        let outputURL = defaultFileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("AuraTone_Ringtone.m4r")
        try? defaultFileManager.removeItem(at: outputURL)
        
        // 2. Load MIDI sequence into sequencer
        let renderSequencer = AVAudioSequencer(audioEngine: renderEngine)
        do {
            try loadAndSanitizeMIDI(from: midiURL, into: renderSequencer)
            
            // Route all tracks
            for track in renderSequencer.tracks {
                track.destinationAudioUnit = renderSynth
            }
            
            renderSequencer.prepareToPlay()
            
            // Set rate
            renderSequencer.rate = Float(tempoMultiplier)
            
            // Setup output file writer (using CoreAudio AAC encoder)
            var settings = outputFormat.settings
            settings[AVFormatIDKey] = kAudioFormatMPEG4AAC
            settings[AVNumberOfChannelsKey] = 2
            settings[AVSampleRateKey] = 44100.0
            
            let audioFile = try AVAudioFile(forWriting: outputURL, settings: settings)
            
            // 3. Configure manual rendering
            let maxFrames: AVAudioFrameCount = 4096
            try renderEngine.enableManualRenderingMode(.offline, format: outputFormat, maximumFrameCount: maxFrames)
            
            try renderEngine.start()
            try renderSequencer.start()
            renderSequencer.currentPositionInSeconds = startTime
            
            // Load the selected instrument SoundBank preset BEFORE offline rendering
            guard let bankURL = Bundle.main.url(forResource: "TimGM6mb", withExtension: "sf2") else {
                print("SoundFont TimGM6mb.sf2 not found for rendering!")
                completion(nil)
                return
            }
            try? renderSynth.loadSoundBankInstrument(
                at: bankURL,
                program: selectedInstrumentId,
                bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                bankLSB: UInt8(kAUSampler_DefaultBankLSB)
            )
            
            // Calculate total samples, adjusting for the tempo rate
            let renderedDuration = duration / tempoMultiplier
            let totalSamples = Int64(renderedDuration * outputFormat.sampleRate)
            var renderedSamples: Int64 = 0
            
            let buffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: maxFrames)!
            
            // Render loop
            while renderedSamples < totalSamples {
                let framesToRender = min(maxFrames, AVAudioFrameCount(totalSamples - renderedSamples))
                let status = try renderEngine.renderOffline(framesToRender, to: buffer)
                
                if status != .success {
                    break
                }
                
                // Apply manual fade-out if requested
                if applyFade {
                    let fadeLength = Int64(2.5 * outputFormat.sampleRate) // 2.5 seconds fade
                    let fadeStart = totalSamples - fadeLength
                    if renderedSamples > fadeStart {
                        let progress = Double(renderedSamples - fadeStart) / Double(fadeLength)
                        let volume = Float(1.0 - progress)
                        
                        if let channels = buffer.floatChannelData {
                            for channel in 0..<Int(buffer.format.channelCount) {
                                for frame in 0..<Int(framesToRender) {
                                    channels[channel][frame] *= volume
                                }
                            }
                        }
                    }
                }
                
                try audioFile.write(from: buffer)
                renderedSamples += Int64(framesToRender)
            }
            
            renderSequencer.stop()
            renderEngine.stop()
            
            // Notify back on main thread
            DispatchQueue.main.async {
                completion(outputURL)
            }
            
        } catch {
            print("Manual rendering failed: \(error)")
            DispatchQueue.main.async {
                completion(nil)
            }
        }
    }
}

// Private helper to avoid standard library clash and handle file checks smoothly
private class FinderFileManager {
    init() {}
}
