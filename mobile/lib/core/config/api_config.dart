class ApiConfig {
  // Base URL
  static const String baseUrl = 'http://api.e-learning.click';
  
  // Token cố định để test (SAU NÀY NÊN DÙNG SECURE STORAGE)
  // Thay YOUR_TEST_TOKEN_HERE bằng token thực tế từ Swagger hoặc backend
  static const String testToken = 'YOUR_TEST_TOKEN_HERE';
  
  // API Endpoints
  static const String topicsEndpoint = '/api/vocabs/topics';
  static const String newWordsEndpoint = '/api/vocabs/new-words';
  static const String reviewDeckEndpoint = '/api/vocabs/review-deck';
  static const String answerEndpoint = '/api/vocabs/answer';
  
  // Headers
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $testToken',
  };
  
  // Full URLs
  static String get topicsUrl => '$baseUrl$topicsEndpoint';
  static String get newWordsUrl => '$baseUrl$newWordsEndpoint';
  static String get reviewDeckUrl => '$baseUrl$reviewDeckEndpoint';
  static String get answerUrl => '$baseUrl$answerEndpoint';
  
  // Helper method để tạo URL với query parameters
  static String buildUrl(String endpoint, Map<String, dynamic>? queryParams) {
    if (queryParams == null || queryParams.isEmpty) {
      return '$baseUrl$endpoint';
    }
    
    final uri = Uri.parse('$baseUrl$endpoint');
    final newUri = uri.replace(queryParameters: queryParams.map(
      (key, value) => MapEntry(key, value.toString()),
    ));
    return newUri.toString();
  }
}