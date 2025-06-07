import 'package:http/http.dart' as http;
import 'package:shelter_partner/helpers/network_client.dart';

class MockNetworkClient implements NetworkClient {
  final Map<String, http.Response> _responses = {};
  final List<NetworkRequest> _requests = [];
  
  void setResponse(String url, int statusCode, [String? body]) {
    _responses[url] = http.Response(body ?? '', statusCode);
  }
  
  List<NetworkRequest> get requests => List.unmodifiable(_requests);
  
  void clear() {
    _responses.clear();
    _requests.clear();
  }
  
  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    _requests.add(NetworkRequest('GET', url, headers, null));
    final response = _responses[url.toString()];
    if (response != null) {
      return response;
    }
    // Default successful response
    return http.Response('{"status": "success"}', 200);
  }

  @override
  Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body}) async {
    _requests.add(NetworkRequest('POST', url, headers, body));
    final response = _responses[url.toString()];
    if (response != null) {
      return response;
    }
    // Default successful response
    return http.Response('{"status": "success"}', 200);
  }

  @override
  Future<http.Response> delete(Uri url, {Map<String, String>? headers}) async {
    _requests.add(NetworkRequest('DELETE', url, headers, null));
    final response = _responses[url.toString()];
    if (response != null) {
      return response;
    }
    // Default successful response  
    return http.Response('{"success": true}', 200);
  }
}

class NetworkRequest {
  final String method;
  final Uri url;
  final Map<String, String>? headers;
  final Object? body;
  
  NetworkRequest(this.method, this.url, this.headers, this.body);
  
  @override
  String toString() {
    return '$method $url';
  }
}