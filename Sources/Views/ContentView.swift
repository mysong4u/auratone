import SwiftUI

struct ContentView: View {
    @StateObject private var audioService = AudioEngineService.shared
    
    @State private var selectedTrack: MidiTrack = MidiTrackList.list[0]
    @State private var trimStart: Double = 0.0
    @State private var trimDuration: Double = 30.0
    @State private var tempoMultiplier: Double = 1.0
    @State private var applyFadeOut: Bool = true
    
    @State private var isRendering: Bool = false
    @State private var showTutorial: Bool = false
    @State private var renderedFileUrl: URL? = nil
    @State private var showShareSheet: Bool = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background Ambient Aura Gradient
                Color(red: 0.05, green: 0.05, blue: 0.08)
                    .ignoresSafeArea()
                
                // Glowing Aura Orb
                Circle()
                    .fill(selectedTrack.color.opacity(0.15))
                    .frame(width: geo.size.width * 1.2, height: geo.size.width * 1.2)
                    .blur(radius: 80)
                    .position(x: geo.size.width / 2, y: -geo.size.height * 0.1)
                
                VStack(spacing: 0) {
                    // Header Bar
                    headerBar
                    
                    if geo.size.width > 500 {
                        // iPad / Landscape Dual Panel layout
                        HStack(spacing: 20) {
                            trackListView
                                .frame(width: geo.size.width * 0.35)
                            
                            ScrollView {
                                editorPanelView
                            }
                        }
                        .padding(.horizontal)
                    } else {
                        // iPhone Portrait Single Panel Layout
                        TabView {
                            // Tab 1: Track Selection
                            trackListView
                                .tabItem {
                                    Label("Library", systemImage: "music.note.list")
                                }
                            
                            // Tab 2: Editor & Studio
                            ScrollView {
                                editorPanelView
                                    .padding(.bottom, 40)
                            }
                            .tabItem {
                                Label("Studio", systemImage: "slider.horizontal.3")
                            }
                        }
                        .accentColor(selectedTrack.color)
                    }
                }
                
                // Loading Overlay for Offline Rendering
                if isRendering {
                    renderingOverlay
                }
            }
        }
        .sheet(isPresented: $showTutorial) {
            TutorialView()
        }
        .sheet(isPresented: $showShareSheet, onDismiss: {
            renderedFileUrl = nil
        }) {
            if let url = renderedFileUrl {
                ShareSheet(activityItems: [url])
            }
        }
    }
    
    // MARK: - Header
    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("AuraTone")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Premium Serverless Ringtone Studio")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: { showTutorial = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "questionmark.circle.fill")
                    Text("Guide")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(20)
            }
        }
        .padding()
    }
    
    // MARK: - Track List Section
    private var trackListView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Signature MIDI")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.gray)
                .padding(.horizontal)
                .padding(.top, 10)
            
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(MidiTrackList.list) { track in
                        Button(action: {
                            audioService.stopMIDI()
                            selectedTrack = track
                            trimStart = 0.0
                            trimDuration = min(30.0, track.duration)
                        }) {
                            HStack(spacing: 14) {
                                Circle()
                                    .fill(track.color)
                                    .frame(width: 10, height: 10)
                                    .shadow(color: track.color, radius: 4)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(track.title)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(selectedTrack.id == track.id ? .white : .gray)
                                    
                                    Text(track.category)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Text(String(format: "%.0fs", track.duration))
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(selectedTrack.id == track.id ? Color.white.opacity(0.08) : Color.white.opacity(0.02))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(selectedTrack.id == track.id ? track.color.opacity(0.4) : Color.clear, lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Editor Panel Section
    private var editorPanelView: some View {
        VStack(spacing: 24) {
            // Interactive Glowing Visualizer
            visualizerView
            
            // Trimming sliders
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Borders & Trim")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("\(String(format: "%.1fs", trimStart)) ~ \(String(format: "%.1fs", trimStart + trimDuration)) (\(String(format: "%.0fs", trimDuration)) limit)")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(selectedTrack.color)
                }
                
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Start Offset")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.gray)
                        Slider(value: $trimStart, in: 0...(selectedTrack.duration - 10))
                            .accentColor(selectedTrack.color)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Duration (Max 40s limit)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.gray)
                        Slider(value: $trimDuration, in: 5...min(40.0, selectedTrack.duration - trimStart))
                            .accentColor(selectedTrack.color)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.03))
                .cornerRadius(20)
            }
            .padding(.horizontal)
            
            // Instrument Chooser
            VStack(alignment: .leading, spacing: 14) {
                Text("Synthesizer Instrument")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.gray)
                
                HStack(spacing: 12) {
                    ForEach(audioService.instruments) { inst in
                        Button(action: {
                            audioService.selectedInstrumentId = inst.id
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: inst.icon)
                                    .font(.system(size: 20))
                                Text(inst.name)
                                    .font(.system(size: 10, weight: .bold))
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(audioService.selectedInstrumentId == inst.id ? selectedTrack.color.opacity(0.2) : Color.white.opacity(0.03))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(audioService.selectedInstrumentId == inst.id ? selectedTrack.color : Color.clear, lineWidth: 1)
                            )
                            .foregroundColor(audioService.selectedInstrumentId == inst.id ? .white : .gray)
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            // Speed (Tempo) & Fade Options
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Tempo Multiplier")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.gray)
                    
                    HStack {
                        Image(systemName: "gauge.with.dots.needle.30percent")
                            .foregroundColor(.gray)
                        Slider(value: $tempoMultiplier, in: 0.6...1.8, step: 0.1)
                            .accentColor(selectedTrack.color)
                            .onChange(of: tempoMultiplier) {
                                audioService.updateTempo(multiplier: tempoMultiplier)
                            }
                        Text(String(format: "%.1fx", tempoMultiplier))
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(width: 40)
                    }
                    .padding()
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(16)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Smart Fade Out")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.gray)
                    
                    Toggle(isOn: $applyFadeOut) {
                        Text("Smooth Fade")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .toggleStyle(SwitchToggleStyle(tint: selectedTrack.color))
                    .padding()
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(16)
                }
                .frame(width: 170)
            }
            .padding(.horizontal)
            
            // Bottom Action Controls
            HStack(spacing: 16) {
                // Play / Stop Preview button
                Button(action: {
                    if audioService.isPlaying {
                        audioService.stopMIDI()
                    } else {
                        audioService.playMIDI(
                            trackName: selectedTrack.fileName,
                            tempoMultiplier: tempoMultiplier,
                            startTime: trimStart,
                            duration: trimDuration
                        )
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: audioService.isPlaying ? "square.fill" : "play.fill")
                        Text(audioService.isPlaying ? "Stop Preview" : "Play Preview")
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(audioService.isPlaying ? Color.red.opacity(0.2) : selectedTrack.color.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(audioService.isPlaying ? Color.red : selectedTrack.color, lineWidth: 1.5)
                    )
                    .cornerRadius(18)
                }
                
                // Export Ringtone button
                Button(action: renderRingtone) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up.fill")
                        Text("Export Ringtone")
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(selectedTrack.color)
                    .cornerRadius(18)
                    .shadow(color: selectedTrack.color.opacity(0.4), radius: 10, y: 4)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Animated Glowing Visualizer View
    private var visualizerView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.02))
                .frame(height: 160)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
            
            // Glowing Aura Core
            Circle()
                .fill(selectedTrack.color.opacity(audioService.isPlaying ? 0.3 : 0.08))
                .frame(width: 100, height: 100)
                .blur(radius: audioService.isPlaying ? 30 : 15)
                .animation(.easeInOut(duration: 0.5), value: audioService.isPlaying)
            
            VStack {
                Text(selectedTrack.title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(selectedTrack.category.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(selectedTrack.color)
                    .padding(.top, 2)
                
                // Real-time Wave Animation when playing
                HStack(spacing: 4) {
                    ForEach(0..<15) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(selectedTrack.color)
                            .frame(width: 4, height: audioService.isPlaying ? CGFloat.random(in: 10...50) : 10)
                            .animation(audioService.isPlaying ? Animation.linear(duration: 0.15).repeatForever(autoreverses: true).delay(Double(i) * 0.02) : .default, value: audioService.isPlaying)
                    }
                }
                .frame(height: 60)
                .padding(.top, 6)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Offline Rendering Loading Screen Overlay
    private var renderingOverlay: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: selectedTrack.color))
                    .scaleEffect(1.5)
                
                Text("Rendering MIDI to Ringtone...")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Generating .M4R container via 온디바이스 AAC encoder")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray)
            }
        }
    }
    
    // MARK: - Render Logic
    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    private func renderRingtone() {
        audioService.stopMIDI()
        withAnimation {
            isRendering = true
        }
        
        audioService.renderToM4R(
            trackName: selectedTrack.fileName,
            startTime: trimStart,
            duration: trimDuration,
            tempoMultiplier: tempoMultiplier,
            applyFade: applyFadeOut
        ) { url in
            withAnimation {
                isRendering = false
            }
            if let exportedURL = url {
                self.renderedFileUrl = exportedURL
                self.showShareSheet = true
            }
        }
    }
}

// MARK: - Share Sheet Helper (UIKit wrapper)
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - App Store Ringtone Guide Sheet (Tutorial)
struct TutorialView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.08)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("How to Apply Your Ringtone")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.bottom, 6)
                        
                        stepRow(
                            step: "1",
                            title: "Export to GarageBand",
                            description: "Export를 누르면 나오는 공유 시트(Share Sheet)에서 'GarageBand' 앱 아이콘을 선택해 전송하세요. 만약 목록에 없다면 '파일에 저장'한 뒤 GarageBand에서 열어주시면 됩니다."
                        )
                        
                        stepRow(
                            step: "2",
                            title: "Share as Ringtone inside GarageBand",
                            description: "GarageBand 앱의 프로젝트 목록에서 보낸 오디오 파일을 길게 누르면 메뉴가 나옵니다. 하단의 [공유]를 선택한 뒤 [벨소리 (Ringtone)] 버튼을 탭하세요."
                        )
                        
                        stepRow(
                            step: "3",
                            title: "Set as Default Ringtone",
                            description: "내보내기가 성공적으로 완료되면 창이 뜹니다. [사운드를 다음으로 사용...]을 눌러 즉시 기본 벨소리로 적용하거나, 아이폰 [설정 > 사운드 및 햅틱 > 벨소리] 목록에서 지정하시면 됩니다!"
                        )
                        
                        Spacer()
                    }
                    .padding(24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            }.foregroundColor(.orange))
        }
        .preferredColorScheme(.dark)
    }
    
    private func stepRow(step: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text(step)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.black)
                .frame(width: 28, height: 28)
                .background(Color.orange)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                    .lineSpacing(4)
            }
        }
        .padding()
        .background(Color.white.opacity(0.02))
        .cornerRadius(18)
    }
}
