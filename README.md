# Cortana Core

An on-device iPhone chatbot with a Cortana look and a Halo-style AI persona. No cloud APIs: the model runs locally.

**Status:** in progress (see [CHANGELOG](CHANGELOG.md), [dev log](docs/dev-log.md)).

## Build
Requires Xcode 16+ and iOS 17+ (target: iPhone 14 or newer).

```sh
scripts/bootstrap.sh   # generates CortanaCore.xcodeproj from project.yml
```

Model: Qwen3-1.7B 4-bit via MLX Swift, downloaded once then fully offline ([details](docs/model-runtime.md)). Run on a real iPhone; the simulator uses a placeholder.

## Layout
| Path | Contents |
|---|---|
| `src/CortanaCore` | App code (`App`, `Views`, `Engine`, `Support`, `Resources`) |
| `tests/` | Unit tests |
| `docs/` | Design notes and dev log |
| `scripts/` | Dev helpers |

## Notes
Cortana and Halo are trademarks of Microsoft. This is an unaffiliated fan project. The app icon still uses Microsoft Cortana artwork as a placeholder and should be replaced before any public release.
