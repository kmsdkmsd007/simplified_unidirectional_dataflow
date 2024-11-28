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
        PagedPosts(
          data: final posts,
        ) =>
          posts.length,
        _ => null,
      };

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

  /// Fetches the next page of posts
  Future<void> fetchPosts() async {
    try {
      if (value.postsData is Loading || value.postsData is Paging) {
        debugPrint('Already fetching posts. Ignoring request.');
        return;
      }

      switch (value.postsData) {
        // Switch to paging a new page
        case Paged(data: final d, nextUrl: final url):
          value = value.copyWith(postsData: Paging(d, nextUrl: url));

        // Switch to paging for the first page
        case Uninitialized():
          value = value.copyWith(
            postsData: Paging(~<Post>[], nextUrl: _postsUrl(0)),
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
            Paged(
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
      //An error is unlikely, but could occur if there is a mistak in the code
      value = value.copyWith(postsData: Failed((message: e.toString())));
    }
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
}
