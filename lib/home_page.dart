import 'dart:async';

import 'package:flutter/material.dart';
import 'package:simplified_unidirectional_dataflow/controllers/app_controller.dart';
import 'package:simplified_unidirectional_dataflow/framework/framework.dart';
import 'package:simplified_unidirectional_dataflow/main.dart';
import 'package:simplified_unidirectional_dataflow/models/app_state.dart';
import 'package:simplified_unidirectional_dataflow/models/post.dart';
import 'package:simplified_unidirectional_dataflow/ui/constants.dart';
import 'package:simplified_unidirectional_dataflow/ui/info_card.dart';

const postCountKey = ValueKey('PostsInfoCard');
const pageCountKey = ValueKey('PageInfoCard');

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Posts'),
        ),
        body: ValueListenableBuilder<AppState>(
          valueListenable: container<AppController>(),
          builder: (context, state, _) => switch (state.postsData) {
            // Loading
            Loading() => spinner,

            //We have data
            Paged<ImmutableList<Post>, Fault>(
              data: final posts,
              nextUrl: final nextUrl
            ) ||
            Paging<ImmutableList<Post>, Fault>(
              data: final posts,
              nextUrl: final nextUrl
            ) =>
              _mainStack(
                context,
                posts,
                nextUrl,
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (s) => _onScrollNotification(s, nextUrl),
                    child: _mainListView(posts, nextUrl),
                  ),
                ),
              ),

            //An error occurred
            Failed<ImmutableList<Post>, Fault>(
              error: Fault(message: final msg)
            ) =>
              _errorDisplay(context, msg),

            // Other cases
            _ => _defaultDisplay(context),
          },
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
              child,
            ],
          ),
          _refreshButton(context),
        ],
      );

  Stack _defaultDisplay(BuildContext context) => Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No data available.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error: $msg',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ],
            ),
          ),
          _refreshButton(context),
        ],
      );

  Positioned _refreshButton(BuildContext context) => Positioned(
        right: 16,
        bottom: 16,
        child: FloatingActionButton(
          onPressed: () => unawaited(container<AppController>().refresh()),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          child: const Icon(Icons.refresh),
        ),
      );

  Container _infoCards(BuildContext context, ImmutableList<Post> posts) =>
      Container(
        padding: const EdgeInsets.all(16),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
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

  ListView _mainListView(ImmutableList<Post> posts, Uri? nextUrl) {
    debugPrint('Rendering list view with ${posts.length} items.');
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: posts.length + 1,
      itemBuilder: (context, index) => switch ((index, posts)) {
        (final idx, _) when idx == posts.length => nextUrl != null
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text('Loading...'),
                ),
              )
            : const SizedBox.shrink(),
        (final idx, final items) => Card(
            margin: const EdgeInsets.symmetric(
              vertical: 4,
              horizontal: 8,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                '${items[idx].id}. ${items[idx].title}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  items[idx].body,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ),
          ),
      },
    );
  }

  bool _onScrollNotification(ScrollNotification scrollInfo, Uri? nextUrl) {
    if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
        nextUrl != null) {
      debugPrint('Fetching next page of posts...');
      unawaited(
        container<AppController>().fetchPosts(),
      );
    } else {
      debugPrint('No more posts to fetch.');
    }
    return false;
  }
}
