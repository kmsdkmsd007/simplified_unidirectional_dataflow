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

    // Verify initial loading state. Note that we don't directly verify state
    // We verify it indirectly at the UI level. This means that if we refactor
    // the code, we don't have to change the tests
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for data to load
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Verify loading state is hidden
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Verify data is displayed
    expect(find.text('Post 1'), findsOneWidget);

    // ignore: unused_local_variable
    final infoCard = tester.widget<InfoCard>(find.byKey(pageCountKey));

    await matchesGolden('FirstLoad');

    expect(find.text('Post 11'), findsNothing);

    // Scroll to the bottom to trigger pagination
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await matchesGolden('AfterDrag');

    await tester.dragUntilVisible(
      find.text('Post 10'),
      find.byType(ListView),
      const Offset(0, -500),
    );
    // Wait for data to load
    await tester.pump(const Duration(seconds: 2));
    await matchesGolden('AfterDragTo10');

    // Verify additional data is displayed
    expect(find.text('Post 11'), findsOneWidget);

    await tester.dragUntilVisible(
      find.text('Post 20'),
      find.byType(ListView),
      const Offset(0, -500),
    );
    // Wait for data to load
    await tester.pump(const Duration(seconds: 2));
    await matchesGolden('AfterDragTo20');

    await tester.pumpAndSettle();
  });
}

/// Generates mock data in the same shape that the JSONPlaceholder API returns
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

/// Checks to see if the golden is the same the expected image
Future<void> matchesGolden(
  String filename,
) async =>
    expectLater(
      find.byType(AppRoot),
      matchesGoldenFile(
        'goldens/$filename.png',
      ),
    );
