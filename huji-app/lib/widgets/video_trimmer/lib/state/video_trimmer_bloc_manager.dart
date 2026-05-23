import 'dart:io';

import 'package:restcut/widgets/video_trimmer/lib/managers/video_clip_segment.dart';
import 'package:restcut/widgets/video_trimmer/lib/state/clip_segment_bloc.dart';
import 'package:restcut/widgets/video_trimmer/lib/state/trimmer_bloc.dart';
import 'package:restcut/widgets/video_trimmer/lib/state/trimmer_event.dart';

class VideoTrimmerBlocManager {
  late final ClipSegmentBloc clipSegmentBloc;
  late final TrimmerBloc trimmerBloc;

  VideoTrimmerBlocManager({
    required File file,
    required List<VideoClipSegment>? initialSegments,
  }) {
    clipSegmentBloc = ClipSegmentBloc(videoTrimmerBlocManager: this);
    trimmerBloc = TrimmerBloc(file: file, videoTrimmerBlocManager: this);
    trimmerBloc.add(TrimmerLoadVideo(initialSegments: initialSegments));
  }
}
