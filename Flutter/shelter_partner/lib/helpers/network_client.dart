import 'package:http/http.dart' as http;

/// NetworkClient class for abstracting HTTP requests (for testability)
abstract class NetworkClient {
  Future<http.Response> get(Uri url, {Map<String, String>? headers});
  Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body});
  Future<http.Response> delete(Uri url, {Map<String, String>? headers});
}

class DefaultNetworkClient implements NetworkClient {
  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    return http.get(url, headers: headers);
  }

  @override
  Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body}) {
    return http.post(url, headers: headers, body: body);
  }

  @override
  Future<http.Response> delete(Uri url, {Map<String, String>? headers}) {
    return http.delete(url, headers: headers);
  }
}