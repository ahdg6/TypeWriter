import "dart:convert";

import "package:collection/collection.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter/models/adapter.dart";
import "package:typewriter/models/page.dart";
import "package:typewriter/utils/extensions.dart";
import "package:typewriter/utils/passing_reference.dart";

part "entry.g.dart";

@riverpod
EntryDefinition? entryDefinition(EntryDefinitionRef ref, String pageId, String entryId) {
  final entry = ref.watch(entryProvider(pageId, entryId));
  final adapterEntry = ref.watch(entryBlueprintProvider(entry?.type ?? ""));
  if (entry == null || adapterEntry == null) {
    return null;
  }
  return EntryDefinition(pageId: pageId, entry: entry, blueprint: adapterEntry);
}

class EntryDefinition {
  EntryDefinition({
    required this.pageId,
    required this.entry,
    required this.blueprint,
  });
  final String pageId;
  final Entry entry;
  final EntryBlueprint blueprint;

  void updateField(PassingRef ref, String path, dynamic value) {
    final page = ref.read(pageProvider(pageId));
    if (page == null) return;
    page.updateEntryValue(ref, entry, path, value);
  }
}

class Entry {
  Entry(this.data);

  Entry.fromBlueprint({
    required String id,
    required EntryBlueprint blueprint,
  }) : data = {
          ...blueprint.fields.defaultValue,
          "id": id,
          "name": "new_${blueprint.name}",
          "type": blueprint.name,
        };

  factory Entry.fromJson(Map<String, dynamic> json) => Entry(json);
  final Map<String, dynamic> data;

  Map<String, dynamic> toJson() => data;

  String get id => data["id"] as String;

  String get name => data["name"] as String;

  String get formattedName => name.formatted;

  String get type => data["type"] as String;

  /// Returns the values in [map] that match [path].
  ///
  /// The path is a string representation of keys and indices to access the values in [map].
  /// ".*" can be used in [path] to match any key in a map, and "[0-9]+" can be used to match
  /// any index in a list.
  ///
  /// # Example
  ///
  /// Given the following map:
  ///
  /// ```
  /// Map<String, dynamic> map = {
  ///   "foo": [{"bar": 42}, {"baz": 56}],
  ///   "qux": {"quux": [1, 2, 3]}
  /// };
  /// ```
  ///
  /// The following paths and their returned values are:
  ///
  /// | Path                  | Returned value |
  /// |----------------------|----------------|
  /// | "foo.*.bar"          | [42]           |
  /// | "foo.0.bar"          | [42]           |
  /// | "qux.quux.*"         | [1, 2, 3]      |
  /// | "qux.quux.2"         | [3]            |
  ///
  List<dynamic> _crawl(String path, [Map<String, dynamic>? map]) {
    final data = map ?? this.data;
    if (path.isEmpty) {
      return [data];
    }
    final parts = path.split(".");
    return parts.fold(<dynamic>[data], (current, part) {
      return current.expand((item) {
        if (item is Map) {
          return _crawlInMap(item, part);
        } else if (item is List) {
          return _crawlInList(item, part);
        }
        return [];
      }).toList();
    });
  }

  /// Crawls [map] using [part] of [path].
  List<dynamic> _crawlInMap(Map<dynamic, dynamic> map, String part) {
    if (part == "*") {
      return map.values.toList();
    } else if (map.containsKey(part)) {
      return [map[part]];
    }
    return [];
  }

  /// Crawls [list] using [part] of [path].
  List<dynamic> _crawlInList(List<dynamic> list, String part) {
    if (part == "*") {
      return list;
    } else if (int.tryParse(part) != null && list.length > int.parse(part)) {
      return [list[int.parse(part)]];
    }
    return [];
  }

  /// Returns a inner field of this entry.
  /// These fields can be nested using dot notation, like "data.value", "data.1.value", etc.
  /// If the field is not found, a given default value is returned.
  dynamic get(String path, [dynamic defaultValue]) {
    return _crawl(path).firstOrNull ?? defaultValue;
  }

  /// Returns all values of a given path.
  /// This may look similar to [get], but it returns all values of a given path.
  /// Hence wildcards are supported, like "data.*.value", "data.*.1.value", etc.
  List<dynamic> getAll(String path) => _crawl(path);

  /// Returns a new copy of this entry with the given field updated.
  /// You can update nested fields by using dot notation, such as "data.value", "data.1.value", etc.
  ///
  /// For example:
  ///   - if you want to update the field "bar" in the first item of a list at the key "foo",
  ///     use the field "foo.0.bar".
  ///   - if you want to update all the keys in a map, use ".*".
  ///
  /// Returns the original entry if the field is not found.
  Entry copyWith(String field, dynamic value) {
    final parts = field.split(".");
    final last = parts.removeLast();
    // Make a deep copy of the data. To avoid modifying the original data.
    final data = jsonDecode(jsonEncode(this.data));

    final current = _crawl(parts.join("."), data).firstOrNull;
    if (current == null) {
      // The field does not exist. Return the original entry.
      return this;
    }

    // Update the field.
    if (current is Map) {
      current[last] = value;
    }
    if (current is List && int.tryParse(last) != null) {
      current[int.parse(last)] = value;
    }

    return Entry(data);
  }

  /// Returns a new copy of this entry with all values of a given path updated.
  /// All possible fields are checked and mapped to a new value. If the new value is null, the field is removed from the map or list.
  /// If the new value is a map or list, the old value is replaced with the new one.
  /// If the new value is a primitive, the old value is replaced with the new one.
  /// This may look similar to [copyWith], but it updates all values of a given path.
  /// Hence wildcards are supported, like "data.*.value", "data.*.1.value", etc.
  Entry copyMapped(String path, dynamic Function(dynamic) mapper) {
    final parts = path.split(".");
    final last = parts.removeLast();
    // Make a deep copy of the data. To avoid modifying the original data.
    final data = jsonDecode(jsonEncode(this.data));

    final subFields = _crawl(parts.join("."), data);

    if (last == "*") {
      for (final item in subFields) {
        _updateAllValues(item, mapper);
      }
    } else {
      for (final item in subFields) {
        _updateSingleValue(item, last, mapper);
      }
    }

    return Entry(data);
  }

  void _updateAllValues(dynamic item, dynamic Function(dynamic) mapper) {
    if (item is Map) {
      for (final key in item.keys.toList()) {
        _updateSingleValue(item, key, mapper);
      }
    }
    if (item is List) {
      item.replaceRange(0, item.length, item.map(mapper).whereNotNull());
    }
  }

  void _updateSingleValue(dynamic item, String last, dynamic Function(dynamic) mapper) {
    if (item is Map && item.containsKey(last)) {
      final value = mapper(item[last]);
      if (value == null) {
        item.remove(last);
      } else {
        item[last] = value;
      }
    }
    if (item is List) {
      final index = last.asInt;
      if (index == null || index < 0 || index >= item.length) {
        return;
      }
      final value = mapper(item[index]);
      if (value == null) {
        item.removeAt(index);
      } else {
        item[index] = value;
      }
    }
  }

  @override
  String toString() => "Entry{data: $data}";

  @override
  bool operator ==(Object other) => identical(this, other) || other is Entry && data == other.data;

  @override
  int get hashCode => data.hashCode;
}
