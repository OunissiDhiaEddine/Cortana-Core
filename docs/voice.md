# Voice mode (deferred until after shipping)

Status: not built. `Engine/Speech.swift` defines `SpeechOutput` as the extension point; the app currently uses no voice.

## Plan
1. **First pass:** `AVSpeechSynthesizer` with the best installed system voice, behind `SpeechOutput`. Speak each finished sentence while the reply streams. Add a mute toggle.
2. **Speech input:** the `Speech` framework (on-device recognition) to feed the existing chat input, with the orb in a "listening" state.
3. **Custom voice (optional):** an on-device TTS model (for example a small Piper/Kokoro-class model) as another `SpeechOutput`.

## Licensing concern: the original Windows Cortana voice
The Windows Cortana voice is Microsoft's recording work (voiced by Jen Taylor, who also voices the Halo character). Extracting or re-using those audio assets, or training a clone of her voice, would infringe Microsoft's rights and raise personal-voice and consent issues. Do not ship it. For a personal, never-distributed build, that is still your call and risk, but it should not be in this repository.

Distributable options: system voices, a TTS model with a permissive licence, or a voice from an actor who has agreed in writing.
