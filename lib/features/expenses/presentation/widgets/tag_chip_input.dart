import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/expense_provider.dart';

/// Inline tag input widget with autocomplete support.
class TagChipInput extends ConsumerStatefulWidget {
  final List<String> initialTags;
  final ValueChanged<List<String>> onTagsChanged;

  const TagChipInput({
    super.key,
    this.initialTags = const [],
    required this.onTagsChanged,
  });

  @override
  ConsumerState<TagChipInput> createState() => _TagChipInputState();
}

class _TagChipInputState extends ConsumerState<TagChipInput> {
  late List<String> _tags;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _tags = List.from(widget.initialTags);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    final clean =
        tag.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9\-_]'), '');
    if (clean.isEmpty || _tags.contains(clean)) return;
    setState(() {
      _tags.add(clean);
      _controller.clear();
      _showSuggestions = false;
    });
    widget.onTagsChanged(_tags);
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
    widget.onTagsChanged(_tags);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final allTagsAsync = ref.watch(allTagsProvider);
    final existingTags =
        allTagsAsync.value?.map((t) => t.name).toList() ?? [];

    final query = _controller.text.trim().toLowerCase();
    final suggestions = existingTags
        .where((t) =>
            t.contains(query) && !_tags.contains(t) && query.isNotEmpty)
        .take(5)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ..._tags.map((tag) => Chip(
                  label: Text('#$tag',
                      style: TextStyle(color: cs.primary, fontSize: 12)),
                  deleteIcon: Icon(Icons.close, size: 14, color: cs.primary),
                  onDeleted: () => _removeTag(tag),
                  backgroundColor: cs.primary.withValues(alpha: 0.08),
                  side: BorderSide(color: cs.primary.withValues(alpha: 0.2)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                )),
            SizedBox(
              width: 120,
              height: 32,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: TextStyle(fontSize: 13, color: cs.onSurface),
                decoration: InputDecoration(
                  hintText: 'add tag...',
                  hintStyle: TextStyle(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      fontSize: 12),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _showSuggestions = v.isNotEmpty),
                onSubmitted: _addTag,
              ),
            ),
          ],
        ),
        if (_showSuggestions && suggestions.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            children: suggestions
                .map((s) => GestureDetector(
                      onTap: () => _addTag(s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('#$s',
                            style: TextStyle(
                                color: cs.onSecondaryContainer,
                                fontSize: 11)),
                      ),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}
