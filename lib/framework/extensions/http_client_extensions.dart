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
