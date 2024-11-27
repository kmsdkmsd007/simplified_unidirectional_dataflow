import 'package:flutter/material.dart';
import 'package:simplified_unidirectional_dataflow/home_page.dart';
import 'package:simplified_unidirectional_dataflow/main.dart';

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Simplified Unidirectional Dataflow Sample',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6750A4),
            brightness: Theme.of(context).brightness,
          ),
          useMaterial3: true,
        ),
        navigatorKey: container<GlobalKey<NavigatorState>>(),
        home: const HomePage(),
      );
}
