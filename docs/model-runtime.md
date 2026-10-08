# On-device model: runtime and model choice

## Decision
- **Runtime:** [MLX Swift](https://github.com/ml-explore/mlx-swift-lm) (`MLXLLM`), Metal-accelerated, first-party Swift API with streaming (`ChatSession.streamResponse`).
- **Model:** `Qwen3-1.7B` 4-bit (`LLMRegistry.qwen3_1_7b_4bit`), about 1 GB of weights.
- **Config:** one line in `Engine/ModelConfig.swift`.

## Why
- **Fits the phone.** iPhone 14 (A15) has 6 GB RAM and iOS caps normal apps at roughly half of that. A ~1 GB model plus KV cache leaves headroom; 3B-class models (about 1.8 GB) are possible but tight on the 14 and trigger memory kills under pressure. The app requests the increased-memory-limit entitlement as a safety margin.
- **Quality per size.** Qwen3 1.7B follows system prompts and stays in character noticeably better than 1B-class models, which matters for the persona. Thinking mode is turned off (`enable_thinking: false`) to keep latency low.
- **Why not llama.cpp.** Equally capable and portable, but needs a C++ bridge and manual chat-template/streaming glue. MLX gives that in Swift out of the box. If MLX proves a problem on A15, llama.cpp with a Q4_K_M GGUF is the fallback behind the same `ChatEngine` protocol.
- **Alternatives to try** (change `ModelConfig.model`): `llama3_2_3B_4bit` (better, heavier), `gemma3_1B_qat_4bit` (lighter), `llama3_2_1B_4bit`.

## Behavior
- No cloud inference. Weights are downloaded from Hugging Face once on first launch and cached; after that the app works offline. (Bundling weights in the app is possible later if first-run download is unwanted.)
- The simulator has no usable GPU for MLX, so it runs `PlaceholderEngine`. Test on a real iPhone.
- History sent to the model is capped (`maxHistoryMessages`) to bound memory and prefill time.

## Not yet verified
Written without a Swift toolchain. Check on device: first-run download UX, tokens/sec on iPhone 14, peak memory, and the exact `Chat.Message` helper names against mlx-swift-lm 3.31.x.
