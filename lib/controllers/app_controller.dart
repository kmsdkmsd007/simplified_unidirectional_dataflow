import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:simplified_unidirectional_dataflow/framework/framework.dart';
import 'package:simplified_unidirectional_dataflow/models/app_state.dart';
import 'package:simplified_unidirectional_dataflow/models/post.dart';

// Note: you should use a more robust logging solution

class AppController extends ValueNotifier<AppState> {
  AppController(this.httpClient, this.navigatorKey) : super(createAppState());

  final Client httpClient;
  final GlobalKey<NavigatorState> navigatorKey;

  /// Refreshes the data from scratch
  Future<void> refresh() async {
    value = value.copyWith(pageCount: 0, postsData: Uninitialized());
    await fetchPosts();
  }

  int? get postCount => switch (value.postsData) {
        Paged<ImmutableList<Post>, Fault>(
          data: final posts,
        ) =>
          posts.length,
        _ => null,
      };

  /// Whether or not the last fetch says the paging is complete
  bool pagingComplete = false;

  /// Callback that checks to see if there are more posts to fetch
  Uri? _getNextUrl(Response r) {
    final nextUrl = switch (r.headers['x-total-count']) {
      final String totalCount
          when (int.tryParse(totalCount) ?? 0) > (value.pageCount + 1) * 10 =>
        _postsUrl(value.pageCount + 1),
      _ => null,
    };

    debugPrint('Next URL: $nextUrl');
    return nextUrl;
  }

  Uri _postsUrl(int pageCount) => Uri.parse(
        'https://jsonplaceholder.typicode.com/posts?_start=${pageCount * 10}&_limit=10',
      );

  /// Fetches the next page of posts
  Future<void> fetchPosts() async {
    if (value.postsData is Loading || value.postsData is Paging) {
      debugPrint('Already fetching posts. Ignoring request.');
      return;
    } else {
      debugPrint('Fetching posts... Current state: ${value.postsData}');
    }

    try {
      final previousPosts = switch (value.postsData) {
        Paged<ImmutableList<Post>, Fault>(data: final d) => d,
        _ => null,
      };

      final previousPostsState = value.postsData;

      //Set state to loading
      value = value.copyWith(postsData: Paging(previousPosts ?? ~<Post>[]));
      final dataState = await _fetchPostsData();
      debugPrint('Fetch result: $dataState. Page Count: $value.pageCount. '
          'Post Count: $postCount. Updating state...');

      if (previousPosts
          case Paged<ImmutableList<Post>, Fault>(data: final posts)) {
        debugPrint('Before state update. Post IDs: ${posts.map((e) => e.id)}');
      } else {
        debugPrint('Before state update. State: ${value.postsData}');
      }

      value = value.copyWith(
        postsData: switch ((previousPostsState, dataState)) {
          //This is the second page
          (
            Paged<ImmutableList<Post>, Fault>(data: final oldPosts),
            Paged<ImmutableList<Post>, Fault>(data: final newPosts)
          ) =>
            // We add the new posts to the old posts
            _handleNextPage(oldPosts, newPosts),
          //This is the first page
          (_, final Paged<ImmutableList<Post>, Fault> result) =>
            _handleFirstPage(result),
          // This is an error or some other result
          (_, final otherResult) => otherResult,
        },
      );

      if (value.postsData
          case Paged<ImmutableList<Post>, Fault>(data: final posts)) {
        debugPrint('State updated. Post IDs: ${posts.map((e) => e.id)}');
      } else {
        debugPrint('State updated. State: ${value.postsData}');
      }

      //This is not a very accurate page count, but it works for this example
      value = value.copyWith(pageCount: value.pageCount + 1);
      debugPrint('incremented page count to ${value.pageCount}');
    } catch (e) {
      debugPrint('Error fetching posts: $e');
      value = value.copyWith(postsData: Failed((message: e.toString())));
    }
  }

  /// Handles the first page of posts
  DataState<ImmutableList<Post>, Fault> _handleFirstPage(
    Paged<ImmutableList<Post>, Fault> result,
  ) {
    debugPrint(
      'Fetched the first ${result.data.length} new posts.',
    );
    return result;
  }

  /// Handles the next page of posts
  Paged<ImmutableList<Post>, Fault> _handleNextPage(
    ImmutableList<Post> oldPosts,
    ImmutableList<Post> newPosts,
  ) {
    debugPrint(
      'Fetched ${newPosts.length} new posts.',
    );
    final data = ~[...oldPosts, ...newPosts];
    return Paged(data);
  }

  /// Fetches posts from the API based on the current page
  Future<DataState<ImmutableList<Post>, Fault>> _fetchPostsData() async {
    final fetchPostPageUrl = switch (value.postsData) {
      Paged<ImmutableList<Post>, Fault>(nextUrl: final url) => url,
      _ => _postsUrl(0),
    };

    if (fetchPostPageUrl == null) {
      return value.postsData;
    }

    debugPrint('Fetching posts from: $fetchPostPageUrl');

    return httpClient.getPagedData<Post>(
      fetchPostPageUrl,
      postFromJson,
      getNextUrlFromResponse: _getNextUrl,
    );
  }
}
