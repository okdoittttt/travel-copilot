import 'package:flutter/material.dart';

/// S01 시작 화면. 저장된 로그인 정보를 확인하는 동안 보인다.
class SplashScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
