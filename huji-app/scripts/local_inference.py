#!/usr/bin/env python3
"""Local YOLO inference engine — called from Dart via Process.run.

Usage:
  python3 local_inference.py <model_path> <video_path> <output_json_path>
      [--fps 6] [--width 640] [--height 640]
      [--sport ping_pong|badminton] [--match-type normal|profession|singles|doubles]

Output JSON:
{
  "status": "ok" | "error",
  "match_segments": [{"start": 0.0, "end": 5.0, "action": "play_ball"}, ...],
  "frame_count": 140,
  "processing_time_ms": 4500,
  "error": "message if status=error"
}
"""
import argparse
import json
import os
import subprocess
import sys
import tempfile
import time

import numpy as np

# ImageNet normalization constants (ultralytics YOLO classification)
MEAN = np.array([0.485, 0.456, 0.406], dtype=np.float32)
STD = np.array([0.229, 0.224, 0.225], dtype=np.float32)

# Class name → canonical action type (matches Dart ActionType enum)
CLASS_TO_ACTION = {
    "fire_ball": "fireBall",
    "fireball": "fireBall",
    "pick_ball": "pickBall",
    "pickball": "pickBall",
    "play_ball": "playBall",
    "playball": "playBall",
    "transition": "transition",
}


def extract_frames(video_path, fps, width, height):
    """Extract frames as raw RGB24 bytes using ffmpeg."""
    tmpdir = tempfile.mkdtemp(prefix="huji_frames_")
    vf_filter = (
        f"fps={fps},"
        f"scale={width}:{height}:force_original_aspect_ratio=decrease,"
        f"pad={width}:{height}:(ow-iw)/2:(oh-ih)/2"
    )
    cmd = [
        "ffmpeg", "-loglevel", "error", "-i", video_path,
        "-vf", vf_filter,
        "-f", "image2", "-vcodec", "rawvideo", "-pix_fmt", "rgb24",
        f"{tmpdir}/frame_%06d.rgb",
    ]
    subprocess.run(cmd, check=True, timeout=300)
    frame_files = sorted(f for f in os.listdir(tmpdir) if f.endswith(".rgb"))
    return tmpdir, frame_files


def load_model(model_path):
    """Load ONNX model and return session + metadata."""
    import onnxruntime as ort
    session = ort.InferenceSession(model_path)
    input_name = session.get_inputs()[0].name
    output_name = session.get_outputs()[0].name
    import ast
    meta = session.get_modelmeta()
    names_str = meta.custom_metadata_map.get("names", "{}")
    if isinstance(names_str, str):
        # YOLO metadata uses Python dict syntax (single quotes), not JSON
        class_map = ast.literal_eval(names_str)
    else:
        class_map = names_str
    # Convert string keys to int
    class_map = {int(k): v for k, v in class_map.items()}
    return session, input_name, output_name, class_map


def classify_frame(session, input_name, output_name, raw_bytes, width, height):
    """Classify a single raw RGB24 frame."""
    img = np.frombuffer(raw_bytes, dtype=np.uint8).reshape((height, width, 3))
    img_f32 = img.astype(np.float32) / 255.0
    img_f32 = (img_f32 - MEAN) / STD
    img_nchw = np.expand_dims(np.transpose(img_f32, (2, 0, 1)), axis=0)
    outputs = session.run([output_name], {input_name: img_nchw})
    logits = outputs[0][0]
    return int(np.argmax(logits))


def detect_segments(predictions, window_count, interval_seconds):
    """Sliding window segment detection for play_ball."""
    play_idxs = [
        (i, t) for i, (t, action) in enumerate(predictions)
        if action in ("playBall", "fireBall")
    ]
    if len(play_idxs) < window_count:
        return []

    segments = []
    start = 0
    while start + window_count <= len(play_idxs):
        _, first_t = play_idxs[start]
        _, last_t = play_idxs[start + window_count - 1]

        if last_t - first_t <= interval_seconds:
            # Greedily extend
            end = start + window_count - 1
            while end + 1 < len(play_idxs):
                end += 1
            seg_start = play_idxs[start][1]
            seg_end = play_idxs[end][1]
            segments.append({
                "start": round(seg_start, 2),
                "end": round(seg_end, 2),
                "action": "playBall",
            })
            start = end + 1
        else:
            start += 1

    return segments


def main():
    parser = argparse.ArgumentParser(description="Local YOLO inference engine")
    parser.add_argument("model_path", help="Path to ONNX model")
    parser.add_argument("video_path", help="Path to input video")
    parser.add_argument("output_json", help="Path for output JSON")
    parser.add_argument("--fps", type=int, default=6)
    parser.add_argument("--width", type=int, default=640)
    parser.add_argument("--height", type=int, default=640)
    parser.add_argument("--sport", default="ping_pong")
    parser.add_argument("--match-type", default="normal",
                        dest="match_type")
    parser.add_argument("--window-count", type=int, default=5)
    parser.add_argument("--interval", type=float, default=2.0)
    parser.add_argument("--merge-fire-ball", action="store_true",
                        default=True, dest="merge_fire_ball")
    args = parser.parse_args()

    result = {"status": "error", "match_segments": [], "frame_count": 0,
              "processing_time_ms": 0}

    try:
        t_start = time.time()

        # Step 1: Extract frames
        tmpdir, frame_files = extract_frames(
            args.video_path, args.fps, args.width, args.height)

        if not frame_files:
            raise RuntimeError("No frames extracted from video")

        # Step 2: Load model
        session, input_name, output_name, class_map = load_model(args.model_path)

        # Step 3: Classify frames
        predictions = []
        frame_size = args.width * args.height * 3
        for i, fname in enumerate(frame_files):
            with open(os.path.join(tmpdir, fname), "rb") as f:
                raw = f.read(frame_size)
            class_idx = classify_frame(
                session, input_name, output_name, raw, args.width, args.height)
            class_name = class_map.get(class_idx, str(class_idx))
            action = CLASS_TO_ACTION.get(class_name, class_name)
            seconds = i / args.fps
            predictions.append((seconds, action))

        # Step 4: Detect segments
        window_count = args.window_count
        if args.sport == "badminton":
            window_count = 6
        segments = detect_segments(predictions, window_count, args.interval)

        t_elapsed = (time.time() - t_start) * 1000

        result = {
            "status": "ok",
            "match_segments": segments,
            "frame_count": len(frame_files),
            "processing_time_ms": round(t_elapsed, 1),
        }

    except Exception as e:
        result["error"] = str(e)
    finally:
        # Cleanup
        if 'tmpdir' in dir():
            import shutil
            shutil.rmtree(tmpdir, ignore_errors=True)

    with open(args.output_json, "w") as f:
        json.dump(result, f, ensure_ascii=False, indent=2)

    if result["status"] == "error":
        print(f"ERROR: {result.get('error')}", file=sys.stderr)
        sys.exit(1)
    else:
        print(f"Done: {result['frame_count']} frames, "
              f"{len(result['match_segments'])} segments, "
              f"{result['processing_time_ms']:.0f}ms")


if __name__ == "__main__":
    main()
