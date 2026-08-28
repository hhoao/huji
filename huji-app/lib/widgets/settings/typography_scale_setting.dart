import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/theme/app_typography_scale.dart';
import 'package:shared_ui/shared_ui.dart';

/// Typography scale preset strip; shows a percent field when [scaleId] is `custom`.
class TypographyScaleSetting extends StatefulWidget {
  const TypographyScaleSetting({
    required this.scaleId,
    required this.customMultiplier,
    required this.onScaleIdChanged,
    required this.onCustomMultiplierChanged,
    super.key,
  });

  final String scaleId;
  final double customMultiplier;
  final ValueChanged<String> onScaleIdChanged;
  final ValueChanged<double> onCustomMultiplierChanged;

  @override
  State<TypographyScaleSetting> createState() => _TypographyScaleSettingState();
}

class _TypographyScaleSettingState extends State<TypographyScaleSetting> {
  late final TextEditingController _percentController;

  @override
  void initState() {
    super.initState();
    _percentController = TextEditingController(
      text: _percentText(widget.customMultiplier),
    );
  }

  @override
  void didUpdateWidget(covariant TypographyScaleSetting oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.customMultiplier != widget.customMultiplier) {
      final next = _percentText(widget.customMultiplier);
      if (_percentController.text != next) {
        _percentController.text = next;
      }
    }
  }

  @override
  void dispose() {
    _percentController.dispose();
    super.dispose();
  }

  static String _percentText(double multiplier) =>
      (multiplier * 100).round().toString();

  void _commitPercentInput() {
    final parsed = int.tryParse(_percentController.text.trim());
    if (parsed == null) {
      _percentController.text = _percentText(widget.customMultiplier);
      return;
    }
    final multiplier = clampTypographyCustomMultiplier(parsed / 100);
    _percentController.text = _percentText(multiplier);
    widget.onCustomMultiplierChanged(multiplier);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;
    final isCustom = widget.scaleId == 'custom';

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TpSegmentedPicker<String>(
            selected: widget.scaleId,
            scrollable: false,
            onChanged: (id) {
              widget.onScaleIdChanged(id);
              if (id == 'custom') {
                widget.onCustomMultiplierChanged(widget.customMultiplier);
              }
            },
            segments: [
              TpSegmentedOption(
                value: 'compact',
                label: l10n.typographyScaleCompact,
                icon: Icons.density_small_outlined,
              ),
              TpSegmentedOption(
                value: 'standard',
                label: l10n.typographyScaleStandard,
                icon: Icons.density_medium_outlined,
              ),
              TpSegmentedOption(
                value: 'comfortable',
                label: l10n.typographyScaleComfortable,
                icon: Icons.density_large_outlined,
              ),
              TpSegmentedOption(
                value: 'custom',
                label: l10n.typographyScaleCustom,
                icon: Icons.tune_outlined,
              ),
            ],
          ),
          if (isCustom) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 96,
              child: TpInput(
                controller: _percentController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: l10n.typographyScaleCustomHint,
                  suffixText: '%',
                ),
                onSubmitted: (_) => _commitPercentInput(),
                onEditingComplete: _commitPercentInput,
                onTapOutside: (_) => _commitPercentInput(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
