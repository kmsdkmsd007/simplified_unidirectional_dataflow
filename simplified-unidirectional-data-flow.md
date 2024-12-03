# Flutter: Simplified Unidirectional Data Flow

Unidirectional Data Flow is an approach to state management popularized by libraries like [React Redux](https://react-redux.js.org/). It is the foundation of the Bloc pattern in Flutter. It ensures that state changes are predictable and follow a single direction. The focus is on an immutable state, based on the Functional Programming paradigm.

This article explores what we call Simplified Unidirectional Data Flow (SUDF) in Flutter. It leverages core Flutter build blocks like `ValueNotifier` and a minimalist service locator to achieve clean and maintainable state management without the complexity of the Bloc architecture.

While Nimblesite doesn't have a single recommended architecture, it is one of our officially recommended app architectures. 

## Table of Contents

- [Flutter: Simplified Unidirectional Data Flow](#flutter-simplified-unidirectional-data-flow)
  - [Introduction](#introduction)
  - [The Controller - ValueNotifier](#the-controller---valuenotifier)
  - [Dependency Manager / Service Locator - ioc\_container](#dependency-manager--service-locator---ioc_container)
  - [State - Immutable Data Classes with `typedef`](#state---immutable-data-classes-with-typedef)
    - [Post Model](#post-model)
    - [Immutable Collections](#immutable-collections)
    - [Embracing Algebraic Data Types](#embracing-algebraic-data-types)
  - [Building the AppController](#building-the-appcontroller)
    - [AppState](#appstate)
    - [AppController Implementation](#appcontroller-implementation)
  - [Extending HttpClient for Data Fetching](#extending-httpclient-for-data-fetching)
  - [The Sample App: Bringing It All Together](#the-sample-app-bringing-it-all-together)
    - [Main Application](#main-application)
    - [Home Page](#home-page)
  - [Widget Testing the Full App](#widget-testing-the-full-app)
  - [Further Reading](#further-reading)
  - [Conclusion](#conclusion)

## Introduction

State management in Flutter doesn't have to be a complex endeavour. Your team can leverage the simple Flutter building blocks like `ValueNotifier` to create a clean and maintainable architecture for your app. This approach not only reduces boilerplate but also keeps your codebase understandable and scalable. Here, we introduce the various [components](https://www.christianfindlay.com/blog/flutter-state-management-components) for state management with SUDF.

## The Controller - ValueNotifier

[`ValueNotifier`](https://api.flutter.dev/flutter/foundation/ValueNotifier-class.html) is one of Flutter's hidden gems. It allows you to listen to changes in value and rebuild widgets accordingly, just as [Cubit](https://bloclibrary.dev/bloc-concepts/#cubit) does. Here's why you might choose `ValueNotifier` over other state management solutions:

- **Simplicity**: No need to introduce third-party packages or complex patterns.
- **Performance**: Only rebuilds widgets when the value changes.
- **Ease of Use**: Integrates seamlessly with [`ValueListenableBuilder`](https://api.flutter.dev/flutter/widgets/ValueListenableBuilder-class.html).

You can also use other types for your controller, such as Cubit, [StateNotifier](https://pub.dev/packages/state_notifier) or [ChangeNotifier](https://api.flutter.dev/flutter/foundation/ChangeNotifier-class.html).

## Dependency Manager / Service Locator - ioc_container

Your team can use a service locator instead of the Provider library to manage controllers and their state and make them available to widgets. You can also simply call it a container.

We recommend the [`ioc_container`](https://pub.dev/packages/ioc_container) package because it is robust and lightweight without global registrations by default. [get_it](https://pub.dev/packages/get_it) is another service locator package that also works. A service locator allows you to inject dependencies throughout the app without the ceremony of more complex solutions like Provider.


Register your services and controllers in the `main` function before running the app.

```dart
import 'package:ioc_container/ioc_container.dart';

void main() {
  container = compose().toContainer();
  runApp(const AppRoot());
  unawaited(initialize());
}

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
```

## State - Immutable Data Classes with `typedef`

Instead of relying on code generation tools like `freezed`, we recommend Dart's `typedef` keyword to create immutable data classes. This keeps your models simple and avoids additional dependencies. the advantage of [Dart records](https://dart.dev/language/records) is that they come with equality semantics built in.

If maintaining the `copyWith` and `toJson` methods becomes problematic for maintenance reasons, you can create your own code generation with a tool like [`builder_runner`](https://pub.dev/packages/build_runner) or AI. Dart will soon have [macros](https://dart.dev/language/macros) and this should make code generation easier still.

Here is an example of a data class with typedef and helpers for JSON and cloning:

### Post Model

```dart
import 'package:simplified_unidirectional_dataflow/framework/framework.dart';

/// A JSON Placeholder post.
typedef Post = ({
  int id,
  String title,
  String body,
  int userId,
});

/// The state of the posts.
typedef PostsState = DataState<ImmutableList<Post>, Fault>;

/// Paging state
typedef PagingPosts = Loading<ImmutableList<Post>, Fault>;

/// A page was loaded
typedef PagedPosts = Loaded<ImmutableList<Post>, Fault>;

/// Failed to load posts
typedef FailedPosts = Failed<ImmutableList<Post>, Fault>;

/// Creates a new post.
Post createPost({
  required int id,
  required String title,
  required String body,
  required int userId,
}) =>
    (
      id: id,
      title: title,
      body: body,
      userId: userId,
    );

extension PostExtensions on Post {
  /// Copies the post with the given fields.
  Post copyWith({
    int? id,
    String? title,
    String? body,
    int? userId,
  }) =>
      createPost(
        id: id ?? this.id,
        title: title ?? this.title,
        body: body ?? this.body,
        userId: userId ?? this.userId,
      );

  /// Converts the post to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
      };
}

/// Converts a JSON map to a post.
Post? postFromJson(Map<String, dynamic> json) => switch (json) {
      {
        'id': final int id,
        'title': final String title,
        'body': final String body,
        'userId': final int userId,
      } =>
        createPost(
          id: id,
          title: title,
          body: body,
          userId: userId,
        ),
      _ => null,
    };
```

### Immutable Collections

Many Bloc apps make the mistake of using mutable lists and other collections. This can create hard-to-debug errors because equality semantics don't work correctly unless the list also honors equality semantics. You need to use immutable lists on your models. You can use any immutable collection library that works for your team, but here is an example implementation of an immutable list. This is not a full reference. It's only here for demonstration purposes.

```dart
/// An immutable collection that wraps a List to enforce unidirectional data
/// flow principles. Prevents direct mutations and ensures new instances are
/// created for changes, maintaining a clear state history and predictable data
/// flow.
@immutable
class ImmutableList<T> extends Iterable<T> {
  /// Creates an ImmutableList from an Iterable
  ImmutableList(Iterable<T> innerIterable)
      : _innerUnmodifiableList = List<T>.unmodifiable(innerIterable);

  /// Creates an empty ImmutableList
  const ImmutableList.empty() : _innerUnmodifiableList = const [];

  final List<T> _innerUnmodifiableList;

  /// Computes a hash code based on all elements in the list
  @override
  int get hashCode => Object.hashAll(_innerUnmodifiableList);

  /// Gets an iterator over the elements of the immutable list
  @override
  Iterator<T> get iterator => _innerUnmodifiableList.iterator;

  /// Gets the number of elements in the immutable list
  @override
  int get length => _innerUnmodifiableList.length;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImmutableList<T> &&
          length == other.length &&
          _innerUnmodifiableList.asMap().entries.every(
                (entry) =>
                    entry.value == other._innerUnmodifiableList[entry.key],
              );

  /// Gets the element at the specified index
  /// Throws RangeError if index is out of bounds
  T operator [](int index) => _innerUnmodifiableList[index];

  /// Creates a new ImmutableList with the specified element added to the end
  ImmutableList<T> add(T element) =>
      ImmutableList<T>([..._innerUnmodifiableList, element]);

  /// Creates a new ImmutableList with all specified elements added to the end
  ImmutableList<T> addAll(Iterable<T> elements) =>
      ImmutableList<T>([..._innerUnmodifiableList, ...elements]);

  /// Returns a map associating integer indices with elements
  Map<int, T> asMap() => _innerUnmodifiableList.asMap();

  /// Safely gets an element at the specified index, returning null if out of
  ///  bounds
  T? elementAtOrNull(int index) =>
      index >= 0 && index < length ? _innerUnmodifiableList[index] : null;

  /// Creates a new ImmutableList with elements transformed by the given
  /// function
  @override
  ImmutableList<R> map<R>(R Function(T) toElement) =>
      ImmutableList<R>(_innerUnmodifiableList.map(toElement));

  /// Creates a new ImmutableList with the specified element removed
  ImmutableList<T> remove(T element) =>
      ImmutableList<T>(_innerUnmodifiableList.where((e) => e != element));

  /// Creates a new ImmutableList containing only elements that satisfy the test
  @override
  ImmutableList<T> where(bool Function(T) test) =>
      ImmutableList<T>(_innerUnmodifiableList.where(test));
}
```

By defining our data models this way, we maintain immutability and ensure that our state remains predictable.

### Embracing Algebraic Data Types

Algebraic Data Types (ADTs) allow us to represent state in a way that's both expressive and type-safe. As I discussed in my article on [Dart Algebraic Data Types](https://www.christianfindlay.com/blog/dart-algebraic-data-types) the concept:

> allows developers to model complex data structures more elegantly than traditional object-oriented classes

They allow you to define data sets with mutually exclusive values, so it is never possible to access data that is not available in its current state. This is perfect for representing things like data that is loading, loaded, or in an error state. All of the information you need to display what is happening on screen is encapsulated in these states without the need for flags like `isLoading` etc.

Let's define a `DataState<T, E>` with multiple states:

```dart
/// Represents the possible states of data in a unidirectional data flow architecture.
/// This sealed class hierarchy ensures exhaustive pattern matching when handling
/// different states of data loading and presentation.
sealed class DataState<T, E> {}

/// Initial state before any data loading has begun. 
/// Use this instead of the late keyword.
/// In unidirectional flow, this represents the entry point before any actions
/// have been dispatched.
class Uninitialized<T, E> extends DataState<T, E> {}

/// Represents paginated data with optional next page information.
/// Used for infinite scrolling and pagination patterns in the unidirectional flow.
class Loaded<T, E> extends DataState<T, E> {
  /// Creates a Paged state with the specified data and optional next page URL
  Loaded(this.data, {this.nextUrl});

  /// The current page of loaded data
  final T data;

  /// URL for fetching the next page, null if no more pages
  final Uri? nextUrl;
}

/// Represents paginated data with optional next page information.
/// Used for infinite scrolling and pagination patterns in the unidirectional flow.
class Loading<T, E> extends DataState<T, E> {
  /// Creates a paged state with the specified data and optional next page URL
  Loading(this.data, {this.nextUrl});

  /// The current page of loaded data
  final T data;

  /// URL for fetching the next page, null if no more pages
  final Uri? nextUrl;
}

/// Represents a failed data operation.
/// Used when an action in the flow results in an error.
class Failed<T, E> extends DataState<T, E> {
  /// Creates a Failed state with the specified error
  Failed(this.error);

  /// The error that occurred during the operation
  final E error;
}
```

## Building the AppController

The `AppController` manages the application state, handles data fetching, and navigates between screens. It extends `ValueNotifier` and uses the `AppState` typedef.

### AppState

```dart
import 'package:simplified_unidirectional_dataflow/framework/framework.dart';
import 'package:simplified_unidirectional_dataflow/models/post.dart';

/// The state of the app.
typedef AppState = ({
  PostsState postsData,
  int pageCount,
});

AppState createAppState({
  PostsState? postsData,
  int pageCount = 0,
}) =>
    (postsData: postsData ?? Uninitialized(), pageCount: pageCount);

extension AppStateExtensions on AppState {
  /// Copies the app state with the given fields.
  AppState copyWith({
    PostsState? postsData,
    int? pageCount,
  }) =>
      createAppState(
        postsData: postsData ?? this.postsData,
        pageCount: pageCount ?? this.pageCount,
      );
}
```

### AppController Implementation

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:simplified_unidirectional_dataflow/framework/framework.dart';
import 'package:simplified_unidirectional_dataflow/models/app_state.dart';
import 'package:simplified_unidirectional_dataflow/models/post.dart';

/// The controller for the app
class AppController extends ValueNotifier<AppState> {
  AppController(this.httpClient, this.navigatorKey) : super(createAppState());

  /// The HTTP client
  final Client httpClient;

  /// The navigator key
  final GlobalKey<NavigatorState> navigatorKey;

  /// The number of posts loaded
  int? get postCount => switch (value.postsData) {
        PagedPosts(
          data: final posts,
        ) =>
          posts.length,
        _ => null,
      };

  /// Fetches the next page of posts
  Future<void> fetchPosts() async {
    try {
      if (value.postsData is Loading) {
        debugPrint('Already fetching posts. Ignoring request.');
        return;
      }

      switch (value.postsData) {
        // Switch to paging a new page
        case Loaded(data: final d, nextUrl: final url):
          value = value.copyWith(postsData: Loading(d, nextUrl: url));

        // Switch to paging for the first page
        case Uninitialized():
          value = value.copyWith(
            postsData: Loading(~<Post>[], nextUrl: _postsUrl(0)),
          );

        default:
      }

      // Get the next page of posts
      final nextPageResult = await _fetchPostsData();

      debugPrint('Fetch result: $nextPageResult. Page Count: $value.pageCount. '
          'Post Count: $postCount. Updating state...');

      value = value.copyWith(
        postsData: switch ((value.postsData, nextPageResult)) {
          //This is a page after the first page
          (
            PagingPosts(data: final oldPosts),
            PagedPosts(data: final newPosts)
          ) =>
            // We add the new posts to the old posts
            Loaded(
              ~[...oldPosts, ...newPosts],
              nextUrl: _postsUrl(value.pageCount + 1),
            ),
          //This is the first page
          (_, final PagedPosts pagedPosts) => pagedPosts,
          // This is an error or some other result
          (_, final otherResult) => otherResult,
        },
      );

      value = value.copyWith(pageCount: value.pageCount + 1);
    } catch (e) {
      //An error is unlikely, but could occur if there is a mistake in the code
      value = value.copyWith(postsData: Failed((message: e.toString())));
    }
  }

  /// Refreshes the data from scratch
  Future<void> refresh() async {
    value = value.copyWith(pageCount: 0, postsData: Uninitialized());
    await fetchPosts();
  }

  /// Fetches posts from the API based on the current page
  Future<PostsState> _fetchPostsData() async {
    final fetchPostPageUrl = switch (value.postsData) {
      PagedPosts(nextUrl: final url) || PagingPosts(nextUrl: final url) => url,
      _ => null,
    };

    if (fetchPostPageUrl == null) {
      debugPrint('No URL to fetch posts from. Ignoring request.');
      return value.postsData;
    }

    return httpClient.getPagedData<Post>(
      fetchPostPageUrl,
      postFromJson,
      getNextUrlFromResponse: _getNextUrl,
    );
  }

  /// Callback that checks to see if there are more posts to fetch
  Uri? _getNextUrl(Response r) {
    final nextUrl = switch (r.headers['x-total-count']) {
      final String totalCount
          when (int.tryParse(totalCount) ?? 0) > (value.pageCount + 1) * 10 =>
        _postsUrl(value.pageCount + 1),
      _ => null,
    };

    return nextUrl;
  }

  /// Get the url based on the page count
  Uri _postsUrl(int pageCount) => Uri.parse(
        'https://jsonplaceholder.typicode.com/posts?_start=${pageCount * 10}&_limit=10',
      );
}
```

The controller handles fetching posts, loading the next page, and updating the state accordingly.

Notice that the `AppController` injects a `Client` directly. We don't put abstractions over the top of the client to hide it. We don't need to because we can mock `Client` directly for tests, and we can encapsulate data fetching functionality in extensions on the `Client` type.

## Extending HttpClient for Data Fetching

We extend `HttpClient` with a generic `getPagedData` method to handle data fetching and pagination. 

```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:simplified_unidirectional_dataflow/framework/framework.dart';

/// Extensions on HttpClient to support unidirectional data flow patterns
/// when fetching paginated data from APIs.
extension ClientExtensions on Client {
  /// Fetches paginated data and wraps it in appropriate DataState instances
  /// to maintain unidirectional flow of data through the application.
  ///
  /// Verb: GET
  ///
  /// The result transitions through states:
  /// 1. Loading - during fetch
  /// 2. Paged - on successful fetch with pagination
  /// 3. Failed - if an error occurs
  ///
  /// This method is safe to call outside a try/catch block.
  Future<DataState<ImmutableList<T>, Fault>> getPagedData<T>(
    Uri url,
    T? Function(
      Map<String, dynamic> json,
    ) fromJson, {
    required Uri? Function(Response url) getNextUrlFromResponse,
  }) async {
    try {
      final response = await this.get(url);

      final body = response.body;

      final nextUrl = getNextUrlFromResponse(response);

      debugPrint('API Called Url: $url. Response: ${response.statusCode}'
          'Next Url: $nextUrl');

      return switch (response.statusCode) {
        200 => Loaded(
            _mapData(body, fromJson),
            nextUrl: nextUrl,
          ),
        _ => Failed((message: 'Failed to load data: ${response.statusCode}')),
      };
    } catch (e) {
      //Note: you can include more information like stack trace here
      return Failed((message: e.toString()));
    }
  }

  ImmutableList<T> _mapData<T>(
    String body,
    T? Function(Map<String, dynamic> json) fromJson,
  ) {
    final list = ~(jsonDecode(body) as List<dynamic>)
        .map((e) => fromJson(e as Map<String, dynamic>))
        //Note that this will filter out any objects that couldn't
        //be converted to type T
        .whereType<T>();
    return list;
  }
}
```

This method abstracts the data fetching logic, making our controller cleaner. Notice that the method returns a `DataState`, which integrates easily into our controller and will never throw an exception. It is safe to handle the result with a [switch expression](https://www.christianfindlay.com/blog/dart-switch-expressions).

## The Sample App: Bringing It All Together

Here are some files in the sample application.

### Main Application

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:ioc_container/ioc_container.dart';
import 'package:simplified_unidirectional_dataflow/controllers/app_controller.dart';
import 'package:simplified_unidirectional_dataflow/ui/app_root.dart';

void main() {
  container = compose().toContainer();
  runApp(const AppRoot());
  unawaited(initialize());
}

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

/// This is where you'd normally fetch data that you don't need
/// right at the beginning of the app. As long as the state is
/// initialized correctly, the correct ui will display anyway
Future<void> initialize() async => container<AppController>().refresh();
```

### Home Page

The home page reveals the simplicity of using the approach in a real widget.

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:simplified_unidirectional_dataflow/controllers/app_controller.dart';
import 'package:simplified_unidirectional_dataflow/framework/framework.dart';
import 'package:simplified_unidirectional_dataflow/main.dart';
import 'package:simplified_unidirectional_dataflow/models/app_state.dart';
import 'package:simplified_unidirectional_dataflow/models/post.dart';
import 'package:simplified_unidirectional_dataflow/ui/constants.dart';
import 'package:simplified_unidirectional_dataflow/ui/info_card.dart';
import 'package:simplified_unidirectional_dataflow/ui/post_card.dart';

const pageCountKey = ValueKey('PageInfoCard');
const postCountKey = ValueKey('PostsInfoCard');

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(
            appTitle,
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
          ),
          centerTitle: true,
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: ValueListenableBuilder<AppState>(
          valueListenable: container<AppController>(),
          builder: (context, state, _) => switch (state.postsData) {
            PagedPosts(data: final posts, nextUrl: final nextUrl) ||
            PagingPosts(data: final posts, nextUrl: final nextUrl) =>
              _mainStack(
                context,
                posts,
                nextUrl,
                _buildMainList(posts, nextUrl),
              ),
            FailedPosts(error: Fault(message: final msg)) =>
              _errorDisplay(context, msg),
            _ => _defaultDisplay(context),
          },
        ),
      );

  Widget _buildMainList(ImmutableList<Post> posts, Uri? nextUrl) =>
      NotificationListener<ScrollNotification>(
        onNotification: (s) => _onScrollNotification(s, nextUrl),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          itemCount: posts.length + (nextUrl != null ? 1 : 0),
          itemBuilder: (context, index) => index == posts.length
              ? _loadingIndicator()
              : PostCard(post: posts[index]),
        ),
      );

  Stack _defaultDisplay(BuildContext context) => Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  'No data available.',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
          ),
          _refreshButton(context),
        ],
      );

  Stack _errorDisplay(BuildContext context, String msg) => Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error: $msg',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ],
            ),
          ),
          _refreshButton(context),
        ],
      );

  Container _infoCards(BuildContext context, ImmutableList<Post> posts) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            InfoCard(
              key: postCountKey,
              label: 'Posts',
              value: '${posts.length}',
            ),
            InfoCard(
              key: pageCountKey,
              label: 'Page',
              value: '${(posts.length / 10).ceil()}',
            ),
          ],
        ),
      );

  Widget _loadingIndicator() => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );

  Stack _mainStack(
    BuildContext context,
    ImmutableList<Post> posts,
    Uri? nextUrl,
    Widget child,
  ) =>
      Stack(
        children: [
          Column(
            children: [
              _infoCards(context, posts),
              Expanded(child: child),
            ],
          ),
          _refreshButton(context),
        ],
      );

  bool _onScrollNotification(ScrollNotification scrollInfo, Uri? nextUrl) {
    if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
        nextUrl != null) {
      unawaited(
        container<AppController>().fetchPosts(),
      );
    }
    return false;
  }

  Positioned _refreshButton(BuildContext context) => Positioned(
        right: 16,
        bottom: 16,
        child: FloatingActionButton(
          onPressed: () => unawaited(container<AppController>().refresh()),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          foregroundColor: Theme.of(context).colorScheme.onSecondary,
          child: const Icon(Icons.refresh),
        ),
      );
}
```

## Widget Testing the Full App

Testing ensures our app works as intended. We'll use `MockClient` to simulate API responses and verify that data loads and pagination functions correctly. You can also run this as an integration test on a real device. Widget testing and integration testing are not mutually exclusive. The code is basically the same. You can add a flag to avoid mocking the data so that the real data loads if you are in control of the data.

```dart
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
```

## Further Reading

Unidirectional data flow is not a new concept. Haskell has been taking this approach to statement management for decades, and the advantages were well established going back to the late 90s. The paper [Functional Reactive Animation](http://conal.net/papers/icfp97/icfp97.pdf) uses surprisingly familiar language to talk about state management. While it does not mention unidirectional data flow as a term, it lays out the foundation for what would later become a popular approach to state management in many UI toolkits such as React, Flutter, and Jetpack Compose.

## Conclusion
This approach keeps your codebase clean, understandable, and easy to maintain. While SUDF is not the simplest Flutter state management solution, it strikes a happy balance between simplicity and the most rigid approaches like full Bloc.

State management doesn't have to be complicated. As we've demonstrated, you can achieve a robust unidirectional data flow with just a few core Flutter concepts. The key is to embrace simplicity and let the language features work for you.

Feel free to experiment with the sample app, tweak the controller, or expand upon the models. While the sample app is not a complete framework, you are free to use this approach in your apps because you don't need a full framework to use the approach.

 It's a great alternative to Bloc, and Nimblesite is happy to convert your existing Bloc apps to use SUDF. Reach out if you'd like to discuss this approach with your team or need help with an existing Flutter app.


