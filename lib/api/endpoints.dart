
class ApiEndpoints {
  ApiEndpoints._();

  static const String login = '/api/mobile/login';

  static const String refresh = '/api/mobile/refresh';

  static const String logout = '/api/mobile/logout';

  static String leads(String businessId) {
    return '/api/mobile/businesses/$businessId/leads';
  }

  static String leadDetail(String businessId, String leadId) {
    return '/api/mobile/businesses/$businessId/leads/$leadId';
  }
}

