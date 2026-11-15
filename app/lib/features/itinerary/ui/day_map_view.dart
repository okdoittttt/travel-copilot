import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:travelcopilot/core/platform/maps_config.dart';
import 'package:travelcopilot/features/itinerary/data/itinerary_models.dart';
import 'package:travelcopilot/features/places/ui/place_sheet.dart';
import 'package:travelcopilot/l10n/gen/app_localizations.dart';

/// S07 일정 지도. 그날 장소를 순서 번호 마커로 보여준다. 경로선은 그리지 않는다 (약관, 2차).
///
/// 맵 ID를 쓰지 않는다: 맵 ID를 쓰면 무료 지도가 유료 등급이 된다 (features/routes-map.md 5.4).
/// 좌표는 서버 응답에서 받아 화면에서만 쓰고 기기에 저장하지 않는다.
class DayMapView extends ConsumerWidget {
  const new({required this.items, super.key});

  /// 그날 일정 (순서대로). 좌표가 있는 항목만 마커가 된다.
  final List<ItineraryItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final configured = ref.watch(mapsConfiguredProvider).value ?? false;
    // 키 없이 지도를 만들면 Google Maps SDK가 앱을 종료시킨다
    if (!configured) return Center(child: Text(l10n.mapUnavailable));
    final located = [
      for (final (index, item) in items.indexed)
        if (item.location != null) (number: index + 1, item: item),
    ];
    if (located.isEmpty) return Center(child: Text(l10n.mapNoPlaces));
    return _Map(located: located);
  }
}

typedef _Located = ({int number, ItineraryItem item});

class _Map extends StatefulWidget {
  const new({required this.located});

  final List<_Located> located;

  @override
  State<_Map> createState() => _MapState();
}

class _MapState extends State<_Map> {
  Set<gmaps.Marker> _markers = {};

  gmaps.LatLng _position(ItineraryItem item) =>
      gmaps.LatLng(item.location!.lat, item.location!.lng);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(_buildMarkers());
  }

  @override
  void didUpdateWidget(_Map oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.located != widget.located) unawaited(_buildMarkers());
  }

  Future<void> _buildMarkers() async {
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final color = Theme.of(context).colorScheme.primary;
    final markers = <gmaps.Marker>{};
    for (final (:number, :item) in widget.located) {
      markers.add(
        gmaps.Marker(
          markerId: gmaps.MarkerId(item.id),
          position: _position(item),
          icon: await _numberIcon(number, color, ratio),
          infoWindow: gmaps.InfoWindow(title: '$number. ${item.title}'),
          onTap: () {
            final placeId = item.placeId;
            if (placeId != null) {
              unawaited(showPlaceSheet(context, title: item.title, placeId: placeId));
            }
          },
        ),
      );
    }
    if (mounted) setState(() => _markers = markers);
  }

  gmaps.CameraUpdate _fitAll() {
    // 같은 장소가 여러 번 나오면 영역 크기가 0이 되어 최대 배율로 확대되므로 중복을 합친다
    final points = widget.located.map((e) => _position(e.item)).toSet().toList();
    if (points.length == 1) return gmaps.CameraUpdate.newLatLngZoom(points.single, 14);
    final lats = points.map((p) => p.latitude);
    final lngs = points.map((p) => p.longitude);
    return gmaps.CameraUpdate.newLatLngBounds(
      gmaps.LatLngBounds(
        southwest: gmaps.LatLng(
          lats.reduce((a, b) => a < b ? a : b),
          lngs.reduce((a, b) => a < b ? a : b),
        ),
        northeast: gmaps.LatLng(
          lats.reduce((a, b) => a > b ? a : b),
          lngs.reduce((a, b) => a > b ? a : b),
        ),
      ),
      48,
    );
  }

  @override
  Widget build(BuildContext context) => gmaps.GoogleMap(
    initialCameraPosition: gmaps.CameraPosition(
      target: _position(widget.located.first.item),
      zoom: 13,
    ),
    markers: _markers,
    myLocationButtonEnabled: false,
    mapToolbarEnabled: false,
    onMapCreated: (controller) => controller.moveCamera(_fitAll()),
  );
}

/// 번호가 적힌 원형 마커 이미지.
Future<gmaps.BitmapDescriptor> _numberIcon(int number, Color color, double ratio) async {
  const size = 36.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(ratio);
  const center = Offset(size / 2, size / 2);
  canvas
    ..drawCircle(center, size / 2, Paint()..color = Colors.white)
    ..drawCircle(center, size / 2 - 3, Paint()..color = color);
  final text = TextPainter(
    text: TextSpan(
      text: '$number',
      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  text.paint(canvas, center - Offset(text.width / 2, text.height / 2));
  final image = await recorder.endRecording().toImage((size * ratio).ceil(), (size * ratio).ceil());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return gmaps.BitmapDescriptor.bytes(bytes!.buffer.asUint8List(), imagePixelRatio: ratio);
}
