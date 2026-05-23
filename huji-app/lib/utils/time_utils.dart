import 'package:intl/intl.dart';

/// timeStamp to 刚刚/几分钟前/几小时前/几天前/几天后/几小时后/几分钟后
String timeStampToTimeAgo(int? timeStamp) {
  if (timeStamp == null) {
    return '未知时间';
  }

  try {
    final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timeStamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 0) {
      return '${-difference.inDays}天后';
    } else if (difference.inHours < 0) {
      return '${-difference.inHours}小时后';
    } else if (difference.inMinutes < 0) {
      return '${-difference.inMinutes}分钟后';
    } else {
      return '刚刚';
    }
  } catch (e) {
    return '时间格式错误';
  }
}

/// timeStamp to yyyy-MM-dd
String timeStampToDateString(int? timeStamp) {
  if (timeStamp == null) {
    return '未知时间';
  }

  return DateFormat(
    'yyyy-MM-dd',
  ).format(DateTime.fromMillisecondsSinceEpoch(timeStamp));
}

/// timeStamp to yyyy-MM-dd HH:MM:SS
String timeStampToDateTimeString(int? timeStamp) {
  if (timeStamp == null) {
    return '未知时间';
  }

  return DateTime.fromMillisecondsSinceEpoch(timeStamp).toString();
}

/// 格式化时间显示
/// seconds to MM:SS
String formatTime(double seconds) {
  final minutes = (seconds / 60).floor();
  final remainingSeconds = (seconds % 60).floor();
  return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
}

/// 格式化片段时长显示
/// seconds to HH:MM:SS
String formatSegmentDuration(double seconds, {int precision = 1}) {
  if (seconds < 60) {
    // 小于1分钟，显示秒数
    return '${seconds.toStringAsFixed(precision)}s';
  } else if (seconds < 3600) {
    // 小于1小时，显示分钟和秒
    final minutes = (seconds / 60).floor();
    final remainingSeconds = (seconds % 60).floor();
    return '${minutes}m ${remainingSeconds}s';
  } else {
    // 大于1小时，显示小时、分钟和秒
    final hours = (seconds / 3600).floor();
    final minutes = ((seconds % 3600) / 60).floor();
    final remainingSeconds = (seconds % 60).floor();
    return '${hours}h ${minutes}m ${remainingSeconds}s';
  }
}

/// Duration to HH:MM:SS
String formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final hours = twoDigits(duration.inHours.remainder(24));
  final minutes = twoDigits(duration.inMinutes.remainder(60));
  final seconds = twoDigits(duration.inSeconds.remainder(60));
  return '$hours:$minutes:$seconds';
}

String formatDateTimeToHHMMSS(DateTime dateTime) {
  return DateFormat('HH:mm:ss').format(dateTime);
}

/// timeStamp to yyyy-MM-dd HH:MM:SS
String formatDateTimeToyyyyMMddHHMMSS(DateTime dateTime) {
  return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
}

/// timeStamp to yyyy-MM-dd HH:MM:SS
String timeStampToyyyyMMddHHMMSSS(int? timeStamp) {
  if (timeStamp == null) {
    return '未知时间';
  }

  return formatDateTimeToyyyyMMddHHMMSS(
    DateTime.fromMillisecondsSinceEpoch(timeStamp),
  );
}

/// timeStamp to HH:MM:SS
String timeStampToHHMMSS(int? timeStamp) {
  if (timeStamp == null) {
    return '未知时间';
  }

  return formatDateTimeToHHMMSS(DateTime.fromMillisecondsSinceEpoch(timeStamp));
}

String formatDurationToHHMMSSS(Duration duration) {
  return formatDuration(duration);
}

String formatSecondsToHHMMSSS(int seconds) {
  return formatDurationToHHMMSSS(Duration(seconds: seconds));
}

String formatMillisecondsToHHMMSSS(int milliseconds) {
  return formatDurationToHHMMSSS(Duration(milliseconds: milliseconds));
}
