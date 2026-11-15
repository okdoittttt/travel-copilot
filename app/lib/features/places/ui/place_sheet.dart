import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travelcopilot/features/places/data/place_models.dart';
import 'package:travelcopilot/features/places/data/places_api.dart';
import 'package:travelcopilot/features/places/ui/google_attribution.dart';
import 'package:travelcopilot/l10n/gen/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// S10 장소 정보 바텀 시트. 제목은 사용자가 저장한 일정 제목 (Google 이름은 요금 때문에 안 받음).
Future<void> showPlaceSheet(
  BuildContext context, {
  required String title,
  required String placeId,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (context) => _PlaceSheet(title: title, placeId: placeId),
);

class _PlaceSheet extends ConsumerStatefulWidget {
  const new({required this.title, required this.placeId});

  final String title;
  final String placeId;

  @override
  ConsumerState<_PlaceSheet> createState() => _PlaceSheetState();
}

class _PlaceSheetState extends ConsumerState<_PlaceSheet> {
  late final Future<PlaceInfo> _info = ref.read(placesApiProvider).details(widget.placeId);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
        child: FutureBuilder<PlaceInfo>(
          future: _info,
          builder: (context, snapshot) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (snapshot.connectionState != ConnectionState.done)
                const LinearProgressIndicator()
              else if (snapshot.hasError)
                Text(l10n.placeLoadFailed)
              else ...[
                if (snapshot.data!.address != null) Text(snapshot.data!.address!),
                const SizedBox(height: 16),
                FilledButton.icon(
                  icon: const Icon(Icons.map_outlined),
                  label: Text(l10n.placeOpenInMaps),
                  onPressed: () => launchUrl(
                    Uri.parse(snapshot.data!.mapsUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ],
              const Align(alignment: Alignment.centerRight, child: GoogleAttribution()),
            ],
          ),
        ),
      ),
    );
  }
}
