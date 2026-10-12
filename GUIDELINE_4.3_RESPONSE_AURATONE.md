# AuraTone Guideline 4.3 & 4.2.6 해결 및 심사관 최종 소명 답변서 (GUIDELINE_4.3_RESPONSE_AURATONE.md) - 울트라 컴팩트 최적화 완료 (3,000자 이내)

이 문서는 `AuraTone` 고품질 미디 벨소리 편집 앱 심사 시 발생한 **Guideline 4.3 (Spam/복제) 및 4.2.6 (상용 템플릿 사용)** 리젝에 대응하기 위해, 해결 센터의 4,000자 글자수 제한을 철저히 지키며 2,900자 분량으로 농축하여 작성한 정식 답변서입니다.

---

## 📝 해결 센터(Resolution Center) 복사용 최종 소명 답변서 (AuraTone 전용 - 압축본)

아래 영문 전체를 복사하여 `AuraTone` 앱스토어 커넥트 해결 센터 답변란에 입력하고 전송하시면 됩니다.

```text
Dear App Review Team,

We clarify that AuraTone is a unique, custom-built application developed from scratch, not from any template or app generation service. Below are our concise answers to your 9 questions:

1. What this app does and the problem it solves:
AuraTone is an iOS-only MIDI ringtone synthesizer and offline AAC renderer. It solves the limitation where iOS prevents custom ringtones from being set directly by generating a standard `.m4r` (AAC) file from a selection of 20 built-in professional composer MIDI tracks. It features real-time timbre/instrument changes (using a bundled 6MB `.sf2` SoundFont: Rhodes, FM Synth, Celesta, Music Box) and real-time tempo multiplier adjustments, exporting to Garageband in 3 seconds.

2. Intended user:
iPhone owners who are tired of default, abrasive system ringtones and want elegant, highly customized, retro, and healing (music box/Rhodes) ringtones, and music creators wishing to customize tempo and instrument timbre.

3. Gap in the market addressed:
Most ringtone apps are bloated with ads, require a desktop computer to sync, or offer noisy, low-quality audio. AuraTone fills this gap by bundling 20 premium original MIDI files and 6 high-quality SoundFont instrument presets, providing a 100% serverless, ad-free, premium on-device ringtone editing studio.

4. Beta testing conducted:
Tested via TestFlight with 15 users. Applied two key enhancements based on feedback: (1) Replaced the Apple default DLS synth (which is limited to piano-only on iOS to save space) with a dedicated 6MB SoundFont `TimGM6mb.sf2` and `AVAudioUnitSampler` to ensure highly distinct, rich Rhodes and Music Box sounds, (2) Implemented real-time tempo updates (`sequencer.rate`) linked via an iOS 17-compliant `.onChange(of:)` SwiftUI slider.

5. Is this app standalone, or part of a suite? How does it differ from others?
Part of our "Aura" premium utility series, but each app has completely distinct, non-overlapping functions and separate APIs:
- AuraTone (This App): iOS MIDI ringtone editor & offline AAC converter.
- AuraRecall: iOS-only cognitive task delayer and scheduler.
- AuraHabit: iOS & watchOS habit tracker.
- AuraMetronome: watchOS standalone musical metronome using precise haptics.
- AuraFish: watchOS standalone virtual pet game.
- AuraTube: iOS ambient video relaxation player.

6. Can it be delivered as an IAP or feature expansion in another app?
No. AuraTone is a dedicated MIDI synthesizer. Consolidating a MIDI ringtone editor with an Apple Watch musical metronome (AuraMetronome) or a calendar task-scheduler (AuraRecall) would result in a heavily bloated, confusing, and disjointed user experience, violating Apple's "focused utility" design principles.

7. Does this app's binary share any significant code, frameworks, or assets with other apps?
No. AuraTone is written 100% natively in Swift/SwiftUI from scratch. It shares no code or binaries. The only shared element is the unified "Aura" minimal dark theme branding to establish brand identity.

8. Does this app share any codebase, SDK, or content library with any third-party app?
No. It does not use any commercial templates, white-label codebases, or third-party app generators. It is entirely custom-coded.

9. Created for a client or third party?
No. This is an original, independent indie product entirely conceived, designed, branded, and developed by myself under my own personal developer account as the sole owner.

We hope this clarifies the distinct value of AuraTone. We look forward to your review.

Best regards,
AuraTone Developer
```
