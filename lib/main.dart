import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:ioc_container/ioc_container.dart';
import 'package:simplified_unidirectional_dataflow/controllers/app_controller.dart';
import 'package:simplified_unidirectional_dataflow/ui/app_root.dart';

/// The main service locator for the entire app. It contains all state and
/// factories. You can access this globally, or run this through the widget
/// tree as an inherited widget with flutter_ioc_container.
/// https://pub.dev/packages/flutter_ioc_container
///
/// Note that flutter_ioc_container performs a similar function to Provider
/// but neither are necessary. Putting a container inside the
/// widget tree only prevents access to this one global container. There
/// is no issue with using this container directly in your widgets as long
/// as all your tests refresh this container to avoid sharing state.
late final IocContainer container;

void main() {
  container = compose().toContainer();
  runApp(const AppRoot());
  unawaited(initialize());
}

/// This is where you'd normally fetch data that you don't need
/// right at the beginning of the app. As long as the state is
/// initialized correctly, the correct ui will display anyway
Future<void> initialize() async => container<AppController>().refresh();

/// Register services using the builder
IocContainerBuilder compose([bool allowOverrides = false]) =>
    IocContainerBuilder(allowOverrides: allowOverrides)
      ..addSingleton(
        (container) => GlobalKey<NavigatorState>(),
      )
      ..addSingleton(
        (container) => Client(),
      )
      ..addSingleton(
        (container) => AppController(
          container.get<Client>(),
          container.get<GlobalKey<NavigatorState>>(),
        ),
      );
