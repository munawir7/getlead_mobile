class ApiEndpoints {
  ApiEndpoints._();

  // ==================== AUTH ====================

  static const String login = '/api/mobile/login';

  static const String refresh = '/api/mobile/refresh';

  static const String logout = '/api/mobile/logout';

  // ==================== LEADS ====================

  // Get all leads
  static String leads(String businessId) =>
      '/api/mobile/businesses/$businessId/leads';

  // Get lead metadata
  static String leadMeta(String businessId) =>
      '/api/mobile/businesses/$businessId/leads/meta';

  // Get a single lead
  static String leadDetail(String businessId, String leadId) =>
      '/api/mobile/businesses/$businessId/leads/$leadId';

  // Create a lead
  static String createLead(String businessId) =>
      '/api/mobile/businesses/$businessId/leads';

  // Update a lead
  static String updateLead(String businessId, String leadId) =>
      '/api/mobile/businesses/$businessId/leads/$leadId';

  // Partially update a lead
  static String patchLead(String businessId, String leadId) =>
      '/api/mobile/businesses/$businessId/leads/$leadId';

  // Update lead status
  static String updateLeadStatus(String businessId, String leadId) =>
      '/api/mobile/businesses/$businessId/leads/$leadId';

  // Toggle lead star
  static String toggleLeadStar(String businessId, String leadId) =>
      '/api/mobile/businesses/$businessId/leads/$leadId/toggle-star';

  // Delete a lead
  static String deleteLead(String businessId, String leadId) =>
      '/api/mobile/businesses/$businessId/leads/$leadId';

  // ==================== DEALS ====================

  // Get all deals
  static String deals(String businessId) =>
      '/api/mobile/businesses/$businessId/deals';

  // Get deal metadata
  static String dealMeta(String businessId) =>
      '/api/mobile/businesses/$businessId/deals/meta';

  // Get a single deal
  static String dealDetail(String businessId, String dealId) =>
      '/api/mobile/businesses/$businessId/deals/$dealId';

  // Create a deal
  static String createDeal(String businessId) =>
      '/api/mobile/businesses/$businessId/deals';

  // Update a deal
  static String updateDeal(String businessId, String dealId) =>
      '/api/mobile/businesses/$businessId/deals/$dealId';

  // Partially update a deal
  static String patchDeal(String businessId, String dealId) =>
      '/api/mobile/businesses/$businessId/deals/$dealId';
           
  // Delete a deal
  static String deleteDeal(String businessId, String dealId) =>
      '/api/mobile/businesses/$businessId/deals/$dealId';
}