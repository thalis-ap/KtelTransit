import 'package:flutter/material.dart';

class ExpandableDescription extends StatefulWidget {
  final String description;

  const ExpandableDescription({super.key, required this.description});

  @override
  State<ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<ExpandableDescription> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.description,
                      // Show only 1 line when collapsed, unlimited when expanded
                      maxLines: _isExpanded ? null : 1,
                      overflow: _isExpanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          );
  }
}
