enum PermissionEnum {
  basicClip("basic_clip", "基础剪辑"),
  limitedMinutes("limited_minutes", "有限使用量"),
  basicSaveDays("basic_save_days", "基础保存时间"),
  customConfig("custom_config", "自定义配置"),
  proSaveDays("pro_save_days", "Pro保存时间"),
  priorityProcessing("priority_processing", "优先处理"),
  unlimitedMinutes("unlimited_minutes", "无限使用量"),
  extendedSaveDays("extended_save_days", "延长保存时间"),
  freeBonusMinutes("free_bonus_minutes", "赠予时长"),
  proBonusMinutes("pro_bonus_minutes", "Pro版订阅计划赠予的时长"),
  maxBonusMinutes("max_bonus_minutes", "Max版订阅计划赠予的时长"),
  editClip("edit_clip", "编辑片段"),
  remoteClip("remote_clip", "云端剪辑"),
  basicKnowledge("basic_knowledge", "基础知识库"),
  advancedKnowledge("advanced_knowledge", "高级知识库"),
  highQuality("high_quality", "高质量导出");

  const PermissionEnum(this.code, this.name);
  final String code;
  final String name;
}
