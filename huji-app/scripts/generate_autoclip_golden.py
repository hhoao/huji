#!/usr/bin/env python3
"""Generate golden autoclip results from huji-algorithm for app regression tests.

Usage:
  # Ping pong (default)
  python3 scripts/generate_autoclip_golden.py

  # Badminton singles
  python3 scripts/generate_autoclip_golden.py --sport badminton

Requires huji-algorithm dependencies (ultralytics, opencv-python, ray, etc.).
Run from huji-app/ with PYTHONPATH pointing at huji-algorithm root.
"""
from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def _algorithm_root(app_root: Path) -> Path:
    return app_root.parent / "huji-algorithm"


def _segment_to_dict(segment_map: dict) -> dict:
    action, segment = next(iter(segment_map.items()))
    return {
        "action": action.name.lower(),
        "start": round(segment.start_seconds, 2),
        "end": round(segment.end_seconds, 2),
    }


def _sport_defaults(app_root: Path, sport: str) -> tuple[Path, Path, str, str]:
    if sport == "ping_pong":
        return (
            app_root / "test/fixtures/video/test.mp4",
            app_root / "test/fixtures/autoclip/test_mp4_pingpong.json",
            "ping_pong",
            "profession",
        )
    if sport == "badminton":
        return (
            app_root / "test/fixtures/video/blue.mp4",
            app_root / "test/fixtures/autoclip/blue_mp4_badminton.json",
            "badminton",
            "singles",
        )
    raise ValueError(f"Unsupported sport: {sport}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate autoclip golden JSON")
    parser.add_argument(
        "--sport",
        choices=("ping_pong", "badminton"),
        default="ping_pong",
        help="Sport type (default: ping_pong)",
    )
    parser.add_argument(
        "--video",
        default=None,
        help="Input video path (default: sport-specific fixture under test/fixtures/video/)",
    )
    parser.add_argument(
        "--output",
        default=None,
        help="Output JSON path (default: sport-specific under test/fixtures/autoclip/)",
    )
    args = parser.parse_args()

    app_root = _repo_root()
    algo_root = _algorithm_root(app_root)
    if str(algo_root) not in sys.path:
        sys.path.insert(0, str(algo_root))

    default_video, default_output, sport_key, match_type = _sport_defaults(
        app_root, args.sport
    )
    video_path = Path(args.video or default_video).resolve()
    output_path = Path(args.output or default_output).resolve()

    if not video_path.is_file():
        print(f"ERROR: video not found: {video_path}", file=sys.stderr)
        return 1
    if not algo_root.is_dir():
        print(f"ERROR: huji-algorithm not found: {algo_root}", file=sys.stderr)
        return 1

    os.chdir(algo_root)

    from src.main.config.config import load_config
    from src.main.service.large_model_service import LargeModelService
    from src.main.utils.path_utils import get_resource

    config = load_config()
    large_model_service = LargeModelService(config.large_model_service_config)

    if args.sport == "ping_pong":
        from src.main.core.pingpong_auto_clipper import PingPongAutoClipper

        clipper = PingPongAutoClipper(
            config.auto_clip_config.ping_pong,
            config.auto_clip_config.common_options,
            large_model_service,
        )
        model_name = config.auto_clip_config.ping_pong.singles_model
    else:
        from src.main.core.badminton_auto_clipper import BadmintonAutoClipper

        clipper = BadmintonAutoClipper(
            config.auto_clip_config.badminton,
            config.auto_clip_config.common_options,
            large_model_service,
        )
        model_name = config.auto_clip_config.badminton.singles_model

    resolved_video = (
        video_path if video_path.is_file() else Path(get_resource(str(video_path)))
    )
    print(f"Running {args.sport} autoclip on: {resolved_video}")
    result = clipper.autoclip_video(str(resolved_video))

    try:
        video_rel = str(resolved_video.relative_to(app_root))
    except ValueError:
        video_rel = str(resolved_video)

    payload = {
        "video": video_rel,
        "sport": sport_key,
        "match_type": match_type,
        "source": "huji-algorithm",
        "model": model_name,
        "all_match_segment_count": len(result.all_match_segments),
        "great_match_segment_count": len(result.great_match_segments),
        "all_match_segments": [
            _segment_to_dict(s) for s in result.all_match_segments
        ],
        "great_match_segments": [
            _segment_to_dict(s) for s in result.great_match_segments
        ],
    }

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2))
    print(
        f"Golden saved: {output_path} "
        f"({payload['all_match_segment_count']} all, "
        f"{payload['great_match_segment_count']} great)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
