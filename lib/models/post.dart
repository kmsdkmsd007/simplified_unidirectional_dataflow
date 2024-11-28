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
typedef PagingPosts = Paging<ImmutableList<Post>, Fault>;

/// A page was loaded
typedef PagedPosts = Paged<ImmutableList<Post>, Fault>;

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
