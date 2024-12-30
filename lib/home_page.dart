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
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withAlpha((0.6 * 255).toInt()),
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
