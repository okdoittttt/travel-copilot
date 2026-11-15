import 'package:flutter/material.dart';

/// Google Maps 출처 표시. Places 결과를 보여주는 모든 화면 아래에 둔다 (Google 약관).
class GoogleAttribution extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(12),
    child: Text('Google Maps', style: Theme.of(context).textTheme.labelSmall),
  );
}
