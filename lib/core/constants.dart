
class AppConstants {
  AppConstants._();

  static const String baseUrl = 'https://v3.getleadcrm.com';

  // Business associated with the logged-in Getlead account.
  static const String businessId = '01KPJ4Y341NFSQ19ZWC51P3X9D';

  static const int pageSize = 20;

  static const Duration listCacheDuration = Duration(minutes: 5);
  static const Duration detailCacheDuration = Duration(minutes: 10);
}

