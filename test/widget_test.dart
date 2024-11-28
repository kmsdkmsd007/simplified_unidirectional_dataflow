// test/widget_test.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:simplified_unidirectional_dataflow/home_page.dart';
import 'package:simplified_unidirectional_dataflow/main.dart';
import 'package:simplified_unidirectional_dataflow/ui/app_root.dart';
import 'package:simplified_unidirectional_dataflow/ui/info_card.dart';

void main() {
  testWidgets('Paged data is loaded and displayed', (
    tester,
  ) async {
    // Common monitor resolution
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;

    final mockClient = getMockClientForJsonPlaceholder();

    // Replace the HttpClient in the IoC container
    container = (compose(true)..addSingleton<Client>((ioc) => mockClient))
        .toContainer();

    unawaited(initialize());

    await tester.pumpWidget(const AppRoot());

    // Verify initial loading state
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for data to load
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Verify data is displayed
    expect(find.text('Post 1'), findsOneWidget);

    // ignore: unused_local_variable
    final asdasd = tester.widget<InfoCard>(find.byKey(pageCountKey));

    await matchesGolden('FirstLoad');

    // await tester.dragUntilVisible(
    //   find.text('Post 10'),
    //   find.byType(ListView),
    //   const Offset(0, -500),
    // );

    // Scroll to the bottom to trigger pagination
    await tester.drag(find.byType(ListView), const Offset(0, -500));

    await tester.pumpAndSettle();

    await matchesGolden('AfterDrag');

    expect(find.text('Post 10'), findsOneWidget);

    // Scroll to the bottom to trigger pagination
    // await tester.drag(find.byType(ListView), const Offset(0, -500));

    // Wait for data to load
    await tester.pump(const Duration(seconds: 2));

    // Verify additional data is displayed
    expect(find.text('Post 11'), findsOneWidget);
    expect(find.text('Post 20'), findsOneWidget);
  });
}

MockClient getMockClientForJsonPlaceholder() => MockClient((request) async {
      final uri = request.url;
      final start = uri.queryParameters['_start'] ?? '0';

      // Other pages
      final startIndex = int.parse(start);

      final json = jsonEncode(
        List.generate(
          10,
          (index) => {
            'id': startIndex + index + 1,
            'title': 'Post ${startIndex + index + 1}',
            'body': 'Content of Post ${startIndex + index + 1}',
            'userId': 1,
          },
        ),
      );

      return Future.delayed(
        const Duration(seconds: 1),
        () => Response(
          json,
          200,
          headers: {'x-total-count': '100'},
        ),
      );
    });

Future<void> matchesGolden(
  String filename,
) async =>
    expectLater(
      find.byType(AppRoot),
      matchesGoldenFile(
        'goldens/$filename.png',
      ),
    );
