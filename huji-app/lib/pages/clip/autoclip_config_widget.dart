import 'package:flutter/material.dart';
import 'package:huji_app/api/models/autoclip/clip_models.dart';
import 'package:huji_app/api/models/autoclip/video_models.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/pages/clip/types.dart';
import 'package:huji_app/theme/themed_mobile.dart';
import 'package:shared_ui/shared_ui.dart';

// 视频配置组件
class VideoConfigWidget extends StatefulWidget {
  final SportType sportType;
  final VideoClipConfigReqVo initialValues;
  final Function(VideoClipConfigReqVo) onConfigChanged;

  const VideoConfigWidget({
    super.key,
    required this.sportType,
    required this.initialValues,
    required this.onConfigChanged,
  });

  @override
  State<VideoConfigWidget> createState() => _VideoConfigWidgetState();
}

class _VideoConfigWidgetState extends State<VideoConfigWidget> {
  late Map<String, dynamic> _configValues;

  @override
  void initState() {
    super.initState();
    _configValues = widget.initialValues.toJson();
  }

  @override
  void didUpdateWidget(VideoConfigWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sportType != widget.sportType ||
        oldWidget.initialValues != widget.initialValues) {
      _configValues = widget.initialValues.toJson();
    }
  }

  void _updateValue(String key, dynamic value) {
    setState(() {
      // 如果值是枚举类型（ModeEnum 或 MatchType），需要转换为对应的整数值
      if (value is ModeEnum) {
        _configValues[key] = value.value;
      } else if (value is MatchType) {
        _configValues[key] = value.value;
      } else {
        _configValues[key] = value;
      }
    });
    if (widget.sportType == SportType.pingpong) {
      widget.onConfigChanged(
        PingPongVideoClipConfigReqVo.fromJson(_configValues),
      );
    } else {
      widget.onConfigChanged(
        BadmintonVideoClipConfigReqVo.fromJson(_configValues),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<ConfigItem> configItems;
    if (widget.sportType == SportType.pingpong) {
      configItems = ConfigItems().getConfigItems(
        widget.sportType,
        PingPongVideoClipConfigReqVo.fromJson(_configValues),
        context.hujiL10n,
      );
    } else {
      configItems = ConfigItems().getConfigItems(
        widget.sportType,
        BadmintonVideoClipConfigReqVo.fromJson(_configValues),
        context.hujiL10n,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 选项标题
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 16.0),
          child: Text(
            context.hujiL10n.clipOptionsTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        // 可滚动的选项内容
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: configItems.map((item) {
                // 检查是否应该显示此选项
                if (item.visibleOn != null && !item.visibleOn!(_configValues)) {
                  return const SizedBox.shrink();
                }

                return _buildConfigItem(item);
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfigItem(ConfigItem item) {
    switch (item.type) {
      case ConfigItemType.select:
        return _buildSelectItem(item);
      case ConfigItemType.toggle:
        return _buildSwitchItem(item);
      case ConfigItemType.slider:
        return _buildSliderItem(item);
    }
  }

  Widget _buildSelectItem(ConfigItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Text(item.label, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 16),
          Expanded(
            child: TpCompactSelect<Object>(
              value: item.value as Object,
              entries: [
                for (final option
                    in item.selectOptions ?? const <ConfigOption>[])
                  (option.value as Object, option.label),
              ],
              onChanged: (value) {
                if (value != null) {
                  _updateValue(item.key, value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchItem(ConfigItem item) {
    final cs = context.cs;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Text(item.label, style: const TextStyle(fontSize: 16)),
          if (item.tooltip != null) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: item.tooltip!,
              child: Icon(
                Icons.help_outline,
                size: 18,
                color: cs.mutedForeground,
              ),
            ),
          ],
          const Spacer(),
          Switch(
            value: item.value as bool,
            onChanged: (value) => _updateValue(item.key, value),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderItem(ConfigItem item) {
    final sliderConfig = item.sliderConfig!;
    final value = item.value as double;
    final cs = context.cs;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(item.label, style: const TextStyle(fontSize: 16)),
              if (item.tooltip != null) ...[
                const SizedBox(width: 8),
                Tooltip(
                  message: item.tooltip!,
                  child: Icon(
                    Icons.help_outline,
                    size: 18,
                    color: cs.mutedForeground,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: value,
                  min: sliderConfig.min,
                  max: sliderConfig.max,
                  divisions: sliderConfig.divisions,
                  label: value.toStringAsFixed(1),
                  onChanged: (newValue) => _updateValue(item.key, newValue),
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  value.toStringAsFixed(1),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
