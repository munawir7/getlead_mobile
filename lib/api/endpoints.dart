class ApiEndpoints {
  ApiEndpoints._();

  // ============================================================
  // AUTH
  // ============================================================

  static const String login =
      '/api/mobile/login';

  static const String refresh =
      '/api/mobile/refresh';

  static const String logout =
      '/api/mobile/logout';

  // ============================================================
  // LEADS
  // ============================================================

  static String leads(
    String businessId,
  ) {
    return '/api/mobile/businesses/'
        '$businessId/leads';
  }

  static String leadMeta(
    String businessId,
  ) {
    return '/api/mobile/businesses/'
        '$businessId/leads/meta';
  }

  static String leadDetail(
  String businessId,
  String leadId,
) {
  return '/api/mobile/businesses/$businessId/leads/$leadId';
}
  // ============================================================
  // PUT - FULL EDIT
  // ============================================================

  static String updateLead(
    String businessId,
    String leadId,
  ) {
    return '/api/mobile/businesses/'
        '$businessId/leads/$leadId';
  }

  // ============================================================
  // PATCH - PARTIAL UPDATE
  // ============================================================

  static String patchLead(
    String businessId,
    String leadId,
  ) {
    return '/api/mobile/businesses/'
        '$businessId/leads/$leadId';
  }

  // ============================================================
  // PATCH - STATUS
  // ============================================================

  static String updateLeadStatus(
    String businessId,
    String leadId,
  ) {
    return '/api/mobile/businesses/'
        '$businessId/leads/$leadId/status';
  }

  // ============================================================
  // PATCH - STAR
  // ============================================================

  static String toggleLeadStar(
    String businessId,
    String leadId,
  ) {
    return '/api/mobile/businesses/'
        '$businessId/leads/$leadId/toggle-star';
  }

  // ============================================================
  // DELETE
  // ============================================================

  static String deleteLead(
    String businessId,
    String leadId,
  ) {
    return '/api/mobile/businesses/'
        '$businessId/leads/$leadId';
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  static String validatePhone(
    String businessId,
  ) {
    return '/api/mobile/businesses/'
        '$businessId/leads/validate-phone';
  }

  static String validateEmail(
    String businessId,
  ) {
    return '/api/mobile/businesses/'
        '$businessId/leads/validate-email';
  }
}