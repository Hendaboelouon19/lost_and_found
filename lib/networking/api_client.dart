class ApiClient {
  ApiClient({String? baseUrl}) : _baseUrl = baseUrl ?? 'https://api.example.com';

  final String _baseUrl;

  String get baseUrl => _baseUrl;
}
