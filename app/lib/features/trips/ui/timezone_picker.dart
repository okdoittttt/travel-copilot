import 'package:flutter/material.dart';
import 'package:travelcopilot/features/trips/data/timezones.dart';
import 'package:travelcopilot/l10n/gen/app_localizations.dart';

/// 검색 가능한 시간대 목록을 띄우고 고른 이름을 돌려준다. 닫으면 null.
Future<String?> pickTimezone(BuildContext context, {List<String>? options}) =>
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _TimezoneSheet(options: options ?? availableTimezones()),
    );

class _TimezoneSheet extends StatefulWidget {
  const new({required this.options});

  final List<String> options;

  @override
  State<_TimezoneSheet> createState() => _TimezoneSheetState();
}

class _TimezoneSheetState extends State<_TimezoneSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final query = _query.trim().toLowerCase().replaceAll(' ', '_');
    final matches = query.isEmpty
        ? widget.options
        : widget.options.where((name) => name.toLowerCase().contains(query)).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.timezoneSearch,
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: matches.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(matches[index].replaceAll('_', ' ')),
                onTap: () => Navigator.pop(context, matches[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
