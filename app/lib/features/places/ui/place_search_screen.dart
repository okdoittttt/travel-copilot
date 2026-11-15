import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travelcopilot/core/api/app_exception.dart';
import 'package:travelcopilot/features/places/data/place_models.dart';
import 'package:travelcopilot/features/places/data/places_api.dart';
import 'package:travelcopilot/features/places/ui/google_attribution.dart';
import 'package:travelcopilot/l10n/gen/app_localizations.dart';

/// S08 장소 검색. 고르면 [PlacePick]을 돌려준다.
///
/// 비용 때문에 2글자 이상, 입력이 0.3초 멈췄을 때만 서버에 묻는다 (features/itinerary.md 5.5).
/// 화면에 들어올 때 Google 과금 세션 토큰을 만들고, 장소를 고르면 그 세션을 끝낸다.
class PlaceSearchScreen extends ConsumerStatefulWidget {
  const new({super.key, this.bias, this.debounce = const Duration(milliseconds: 300)});

  /// 결과를 치우칠 좌표 (그날 첫 장소).
  final LatLng? bias;

  final Duration debounce;

  static const minQueryLength = 2;

  @override
  ConsumerState<PlaceSearchScreen> createState() => _PlaceSearchScreenState();
}

class _PlaceSearchScreenState extends ConsumerState<PlaceSearchScreen> {
  final String _sessionToken = newPlacesSessionToken();
  Timer? _timer;
  int _requestId = 0;
  List<PlaceSuggestion> _results = [];
  String? _error;
  bool _loading = false;
  bool _picking = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _timer?.cancel();
    final query = value.trim();
    if (query.length < PlaceSearchScreen.minQueryLength) {
      setState(() {
        _results = [];
        _error = null;
      });
      return;
    }
    _timer = Timer(widget.debounce, () => _search(query));
  }

  Future<void> _search(String query) async {
    final id = ++_requestId;
    setState(() => _loading = true);
    try {
      final results = await ref
          .read(placesApiProvider)
          .autocomplete(query, sessionToken: _sessionToken, bias: widget.bias);
      // 늦게 도착한 이전 검색 결과는 버린다
      if (!mounted || id != _requestId) return;
      setState(() {
        _results = results;
        _error = null;
      });
    } on AppException catch (error) {
      if (!mounted || id != _requestId) return;
      setState(() => _error = _message(error));
    } finally {
      if (mounted && id == _requestId) setState(() => _loading = false);
    }
  }

  String _message(AppException error) {
    final l10n = AppLocalizations.of(context);
    return switch (error) {
      ServerException(statusCode: 429) => l10n.rateLimited,
      NetworkException() => l10n.errorNotSaved,
      _ => l10n.placesUnavailable,
    };
  }

  Future<void> _pick(PlaceSuggestion suggestion) async {
    setState(() => _picking = true);
    try {
      // 같은 세션 토큰으로 장소 상세를 불러 과금 세션을 끝낸다. 서버는 좌표를 10분 기억한다
      final info = await ref
          .read(placesApiProvider)
          .details(suggestion.placeId, sessionToken: _sessionToken);
      if (!mounted) return;
      Navigator.of(
        context,
      ).pop(PlacePick(placeId: info.placeId, googleName: suggestion.name, address: info.address));
    } on AppException catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.placeSearchTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                key: const Key('place-search-field'),
                autofocus: true,
                maxLength: 100,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: l10n.placeSearchHint,
                  counterText: '',
                ),
                onChanged: _onChanged,
              ),
            ),
            if (_loading || _picking) const LinearProgressIndicator(),
            if (_error != null) Padding(padding: const EdgeInsets.all(16), child: Text(_error!)),
            Expanded(
              child: ListView(
                children: [
                  for (final s in _results)
                    ListTile(
                      leading: const Icon(Icons.place_outlined),
                      title: Text(s.name),
                      subtitle: s.secondary == null ? null : Text(s.secondary!),
                      enabled: !_picking,
                      onTap: () => _pick(s),
                    ),
                ],
              ),
            ),
            // Places 결과를 Google 지도 없이 보여줄 때는 출처 표시가 필요하다 (약관)
            const GoogleAttribution(),
          ],
        ),
      ),
    );
  }
}
