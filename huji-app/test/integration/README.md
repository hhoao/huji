# Local detection integration tests

Fixtures under `test/fixtures/`:

| Path | Purpose |
|------|---------|
| `video/test.mp4` | Ping-pong sample (from huji-algorithm) |
| `video/blue.mp4` | Badminton singles sample |
| `autoclip/test_mp4_pingpong.json` | Ping-pong algorithm golden |
| `autoclip/blue_mp4_badminton.json` | Badminton algorithm golden |

## Regenerate golden JSON

```bash
# Ping pong
PYTHONPATH=../huji-algorithm \
  ../huji-algorithm/.venv/bin/python3 scripts/generate_autoclip_golden.py

# Badminton singles
PYTHONPATH=../huji-algorithm \
  ../huji-algorithm/.venv/bin/python3 scripts/generate_autoclip_golden.py --sport badminton
```

## Run tests

```bash
# Fixture smoke tests (no ONNX)
flutter test test/fixtures/autoclip/autoclip_fixture_test.dart

# Integration golden tests (ONNX cases skip in VM)
flutter test test/integration/local_detection_golden_test.dart

# End-to-end clip flow: demo video → local detection → task completed
# (tagged `integration`; excluded from default CI via --exclude-tags integration)
flutter test test/integration/clip_flow_integration_test.dart
```

Expected segment counts (algorithm golden):

- Ping pong `test.mp4`: **3** segments
- Badminton `blue.mp4`: **4** segments

Algorithm-aligned desktop config: ping pong reserve 0/1s, badminton reserve 1/1s, min duration 2s.
