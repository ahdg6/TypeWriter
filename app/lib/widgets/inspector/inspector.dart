import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter/app_router.dart";
import "package:typewriter/models/entry.dart";
import "package:typewriter/pages/page_editor.dart";
import "package:typewriter/utils/extensions.dart";
import "package:typewriter/utils/passing_reference.dart";
import "package:typewriter/widgets/components/app/select_entries.dart";
import "package:typewriter/widgets/inspector/editors/name.dart";
import "package:typewriter/widgets/inspector/editors/object.dart";
import "package:typewriter/widgets/inspector/heading.dart";
import "package:typewriter/widgets/inspector/operations.dart";

part "inspector.g.dart";

class InspectingEntryNotifier extends StateNotifier<String?> {
  InspectingEntryNotifier() : super(null);

  void selectEntry(String id) {
    state = id;
  }

  void select(Entry entry) {
    state = entry.id;
  }

  void clearSelection() {
    state = null;
  }

  Future<void> navigateAndSelectEntry(PassingRef ref, String entryId) async {
    final changedPage = await ref.read(appRouter).navigateToEntry(ref, entryId);
    if (changedPage) {
      await Future.delayed(300.ms);
      await WidgetsBinding.instance.endOfFrame;
    }
    state = entryId;
  }
}

final inspectingEntryIdProvider =
    StateNotifierProvider<InspectingEntryNotifier, String?>((ref) => InspectingEntryNotifier());

@riverpod
Entry? inspectingEntry(InspectingEntryRef ref) {
  final selectedEntryId = ref.watch(inspectingEntryIdProvider);
  final page = ref.watch(currentPageProvider);
  return page?.entries.firstWhereOrNull((e) => e.id == selectedEntryId);
}

class Inspector extends HookConsumerWidget {
  const Inspector({
    super.key,
  }) : super();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inspectingEntry = ref.watch(inspectingEntryProvider);
    final isSelectingEntries = ref.watch(isSelectingEntriesProvider);

    // When we are selecting entries, we want a special inspector that allows
    // us to select entries.
    if (isSelectingEntries) {
      return const EntriesSelectorInspector();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: inspectingEntry != null ? _EntryInspector(key: ValueKey(inspectingEntry.id)) : const _EmptyInspector(),
      ),
    );
  }
}

/// The content of the inspector when no entry is selected.
class _EmptyInspector extends HookConsumerWidget {
  const _EmptyInspector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Inspector"),
        const SizedBox(height: 12),
        Text(
          "Click on an entry to inspect its properties.",
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

@riverpod
EntryDefinition? inspectingEntryDefinition(InspectingEntryDefinitionRef ref) {
  final pageId = ref.watch(currentPageIdProvider);
  final entryId = ref.watch(inspectingEntryIdProvider);

  if (pageId.isNullOrEmpty || entryId.isNullOrEmpty) {
    return null;
  }

  return ref.watch(entryDefinitionProvider(pageId!, entryId!));
}

/// The content of the inspector when an dynamic entry is selected.
class _EntryInspector extends HookConsumerWidget {
  const _EntryInspector({
    super.key,
  }) : super();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final object = ref.watch(
      inspectingEntryDefinitionProvider.select((def) => def?.blueprint.fields),
    );

    if (object == null) {
      return const SizedBox();
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Heading(),
          const Divider(),
          const NameField(),
          const Divider(),
          ObjectEditor(
            path: "",
            object: object,
            ignoreFields: const ["id", "name"],
            defaultExpanded: true,
          ),
          const Divider(),
          const Operations(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
