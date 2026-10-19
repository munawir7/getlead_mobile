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

// ==================== TASKS ====================

// Get all tasks
static String tasks(String businessId) =>
'/api/mobile/businesses/$businessId/tasks';

// Get task metadata
static String taskMeta(String businessId) =>
'/api/mobile/businesses/$businessId/tasks/meta';

// Get task priorities
static String taskPriorities(String businessId) =>
'/api/mobile/businesses/$businessId/tasks/priorities';

// Get task categories
static String taskCategories(String businessId) =>
'/api/mobile/businesses/$businessId/tasks/categories';

// Get task overview
static String taskOverview(String businessId) =>
'/api/mobile/businesses/$businessId/tasks/overview';

// Get task counts by category
static String taskCountsByCategory(String businessId) =>
'/api/mobile/businesses/$businessId/tasks/counts/by-category';

// Get general tasks
static String generalTasks(String businessId) =>
'/api/mobile/businesses/$businessId/tasks/general-tasks';

// Get general task statistics
static String generalTaskStats(String businessId) =>
'/api/mobile/businesses/$businessId/tasks/general-tasks/stats';

// Get call tasks
static String callTasks(String businessId) =>
'/api/mobile/businesses/$businessId/tasks/call-tasks';

// Get call task statistics
static String callTaskStats(String businessId) =>
'/api/mobile/businesses/$businessId/tasks/call-tasks/stats';

// Get deal tasks
static String dealTasks(String businessId) =>
'/api/mobile/businesses/$businessId/tasks/deal-tasks';

// Get deal task statistics
static String dealTaskStats(String businessId) =>
'/api/mobile/businesses/$businessId/tasks/deal-tasks/stats';

// Get one task
static String taskDetail(String businessId, String taskId) =>
'/api/mobile/businesses/$businessId/tasks/$taskId';

// Create task
static String createTask(String businessId) =>
'/api/mobile/businesses/$businessId/tasks';

// Delete task
static String deleteTask(String businessId, String taskId) =>
'/api/mobile/businesses/$businessId/tasks/$taskId';

// Complete task
static String completeTask(String businessId, String taskId) =>
'/api/mobile/businesses/$businessId/tasks/$taskId/complete';

// Reschedule task
static String rescheduleTask(String businessId, String taskId) =>
'/api/mobile/businesses/$businessId/tasks/$taskId/reschedule';

// Cancel task
static String cancelTask(String businessId, String taskId) =>
'/api/mobile/businesses/$businessId/tasks/$taskId/cancel';

// Complete call task
static String completeCallTask(String businessId, String taskId) =>
'/api/mobile/businesses/$businessId/tasks/$taskId/complete-call';

// ==================== NOTES ====================

// Get notes for a lead
static String leadNotes(String businessId, String leadId) =>
'/api/mobile/businesses/$businessId/leads/$leadId/notes';

// Create a note for a lead
static String createLeadNote(String businessId, String leadId) =>
'/api/mobile/businesses/$businessId/leads/$leadId/notes';

// Get notes for a deal
static String dealNotes(String businessId, String dealId) =>
'/api/mobile/businesses/$businessId/deals/$dealId/notes';

// Create a note for a deal
static String createDealNote(String businessId, String dealId) =>
'/api/mobile/businesses/$businessId/deals/$dealId/notes';

// Generate a presigned URL for file uploads
static String presignedUploadUrl(String businessId) =>
'/api/mobile/businesses/$businessId/upload/presigned-url';
}
