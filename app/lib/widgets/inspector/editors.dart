import "package:flutter/material.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter/models/adapter.dart";
import "package:typewriter/utils/extensions.dart";
import "package:typewriter/widgets/inspector/editors/boolean.dart";
import "package:typewriter/widgets/inspector/editors/cron.dart";
import "package:typewriter/widgets/inspector/editors/duration.dart";
import "package:typewriter/widgets/inspector/editors/entry_selector.dart";
import "package:typewriter/widgets/inspector/editors/enum.dart";
import "package:typewriter/widgets/inspector/editors/list.dart";
import "package:typewriter/widgets/inspector/editors/location.dart";
import "package:typewriter/widgets/inspector/editors/map.dart";
import "package:typewriter/widgets/inspector/editors/material.dart";
import "package:typewriter/widgets/inspector/editors/number.dart";
import "package:typewriter/widgets/inspector/editors/object.dart";
import "package:typewriter/widgets/inspector/editors/optional.dart";
import "package:typewriter/widgets/inspector/editors/sound.dart";
import "package:typewriter/widgets/inspector/editors/string.dart";
import "package:typewriter/widgets/inspector/inspector.dart";

part "editors.g.dart";

@riverpod
dynamic fieldValue(FieldValueRef ref, String path, [dynamic defaultValue]) {
  final entry = ref.watch(inspectingEntryProvider);
  return entry?.get(path, defaultValue) ?? defaultValue;
}

@riverpod
List<EditorFilter> editorFilters(EditorFiltersRef ref) => [
      // Modifier Editors
      EntrySelectorEditorFilter(),
      SoundSelectorEditorFilter(),

      // Custom Editors
      MaterialSelectorEditorFilter(),
      OptionalEditorFilter(),
      LocationEditorFilter(),
      DurationEditorFilter(),
      CronEditorFilter(),

      // Default filters
      StringEditorFilter(),
      NumberEditorFilter(),
      BooleanEditorFilter(),
      EnumEditorFilter(),
      ListEditorFilter(),
      MapEditorFilter(),
      ObjectEditorFilter(),
    ];

abstract class EditorFilter {
  bool canEdit(FieldInfo info);

  Widget build(String path, FieldInfo info);
}

@riverpod
String pathDisplayName(
  PathDisplayNameRef ref,
  String path, [
  String defaultValue = "",
]) {
  String parseName(String path) {
    final parts = path.split(".");
    final name = parts.last;
    if (name == "") return defaultValue;
    if (int.tryParse(name) != null) {
      final parent = parts.sublist(0, parts.length - 1).join(".");
      final parentName = parseName(parent);
      return "$parentName #${int.parse(name) + 1}";
    }
    return name;
  }

  return parseName(path).formatted;
}
