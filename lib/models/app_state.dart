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
