#!/usr/bin/env python3
"""Generate golden segment JSON using ONNX (no ultralytics required).

Mirrors huji-algorithm predict path:
  resize width=640 -> fps=6 PNG frames -> ONNX profession classify -> segment detect

Usage:
  python3 scripts/generate_onnx_autoclip_golden.py \
      --video test/fixtures/video/test.mp4 \
      --output test/fixtures/autoclip/test_mp4_pingpong.json
"""
from __future__ import annotations

import argparse
import ast
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np

MEAN = np.array([0.0, 0.0, 0.0], dtype=np.float32)
STD = np.array([1.0, 1.0, 1.0], dtype=np.float32)
CLASS_TO_ACTION = {
    "fire_ball": "fireBall",
    "fireball": "fireBall",
    "pick_ball": "pickBall",
    "pickball": "pickBall",
    "play_ball": "playBall",
    "playball": "playBall",
    "transition": "transition",
}


def resize_video(input_file: str, output_file: str, width: int = 640) -> None:
    cmd = [
        "ffmpeg", "-loglevel", "error", "-y",
        "-i", input_file,
        "-vf", f"scale={width}:-1",
        "-c:v", "libx264",
        output_file,
    ]
    subprocess.run(cmd, check=True)


def extract_frames(video_path: str, fps: int, width: int, height: int, tmpdir: str):
    vf = (
        f"fps={fps},"
        f"scale={width}:{height}:force_original_aspect_ratio=decrease,"
        f"pad={width}:{height}:(ow-iw)/2:(oh-ih)/2"
    )
    cmd = [
        "ffmpeg", "-loglevel", "error", "-y",
        "-i", video_path,
        "-vf", vf,
        "-f", "image2", "-vcodec", "rawvideo", "-pix_fmt", "rgb24",
        f"{tmpdir}/frame_%06d.rgb",
    ]
    subprocess.run(cmd, check=True)
    return sorted(f for f in os.listdir(tmpdir) if f.endswith(".rgb"))


def load_model(model_path: str):
    import onnxruntime as ort
    session = ort.InferenceSession(model_path)
    input_name = session.get_inputs()[0].name
    output_name = session.get_outputs()[0].name
    meta = session.get_modelmeta().custom_metadata_map
    names_str = meta.get("names", "{}")
    class_map = ast.literal_eval(names_str)
    class_map = {int(k): v for k, v in class_map.items()}
    return session, input_name, output_name, class_map


def classify_frame(session, input_name, output_name, raw_bytes, width, height):
    img = np.frombuffer(raw_bytes, dtype=np.uint8).reshape((height, width, 3))
    img_f32 = img.astype(np.float32) / 255.0
    img_f32 = (img_f32 - MEAN) / STD
    img_nchw = np.expand_dims(np.transpose(img_f32, (2, 0, 1)), axis=0)
    logits = session.run([output_name], {input_name: img_nchw})[0][0]
    return int(np.argmax(logits))


def detect_segments(predictions, window_count=5, interval_seconds=2.0):
    play_idxs = [
        (i, t) for i, (t, action) in enumerate(predictions)
        if action in ("playBall", "fireBall")
    ]
    n = len(play_idxs)
    if n < window_count:
        return []

    segments = []
    start = 0
    end = 0
    while end < n:
        while start < end and play_idxs[end][1] - play_idxs[start][1] > interval_seconds:
            start += 1
        if end - start + 1 >= window_count:
            max_end = end
            while max_end + 1 < n:
                peek = max_end + 1
                temp_start = start
                while temp_start < peek and play_idxs[peek][1] - play_idxs[temp_start][1] > interval_seconds:
                    temp_start += 1
                if peek - temp_start + 1 >= window_count:
                    max_end = peek
                    start = temp_start
                else:
                    break
            segments.append({
                "start": round(play_idxs[start][1], 2),
                "end": round(play_idxs[max_end][1], 2),
                "action": "playBall",
            })
            start = max_end + 1
            end = start
        else:
            end += 1
    return segments


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--video",
        default="test/fixtures/video/test.mp4",
        help="Input video (default: test/fixtures/video/test.mp4)",
    )
    parser.add_argument("--model", default="assets/models/ping_pong/profession/best.onnx")
    parser.add_argument("--output", default="test/fixtures/autoclip/test_mp4_pingpong.json")
    parser.add_argument("--fps", type=int, default=6)
    parser.add_argument("--size", type=int, default=640)
    args = parser.parse_args()

    app_root = Path(__file__).resolve().parents[1]
    video = Path(args.video).resolve()
    model = (app_root / args.model).resolve()
    output = (app_root / args.output).resolve()

    if not video.is_file():
        print(f"ERROR: video not found: {video}", file=sys.stderr)
        return 1
    if not model.is_file():
        print(f"ERROR: model not found: {model}", file=sys.stderr)
        return 1

    with tempfile.TemporaryDirectory(prefix="huji_golden_") as tmp:
        resized = os.path.join(tmp, "resized.mp4")
        frames_dir = os.path.join(tmp, "frames")
        os.makedirs(frames_dir, exist_ok=True)

        print(f"Resize -> {resized}")
        resize_video(str(video), resized)

        print("Extract frames...")
        frame_files = extract_frames(resized, args.fps, args.size, args.size, frames_dir)
        print(f"Frames: {len(frame_files)}")

        session, input_name, output_name, class_map = load_model(str(model))
        frame_size = args.size * args.size * 3
        predictions = []
        for i, fname in enumerate(frame_files):
            with open(os.path.join(frames_dir, fname), "rb") as f:
                raw = f.read(frame_size)
            idx = classify_frame(session, input_name, output_name, raw, args.size, args.size)
            name = class_map.get(idx, str(idx))
            action = CLASS_TO_ACTION.get(name, name)
            predictions.append((i / args.fps, action))

        segments = detect_segments(predictions)

    try:
        video_rel = str(video.relative_to(app_root))
    except ValueError:
        video_rel = str(video)

    payload = {
        "video": video_rel,
        "sport": "ping_pong",
        "match_type": "profession",
        "source": "onnx_golden_generator",
        "all_match_segment_count": len(segments),
        "great_match_segment_count": len(segments),
        "all_match_segments": segments,
        "great_match_segments": segments,
    }

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(payload, ensure_ascii=False, indent=2))
    print(f"Golden saved: {output} ({len(segments)} segments)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
