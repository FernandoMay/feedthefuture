class AppConstants {
  AppConstants._();

  // App
  static const String appName = 'FeedTheFuture';
  static const String appVersion = '1.0.0';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String donationsCollection = 'donations';
  static const String pickupRequestsCollection = 'pickup_requests';
  static const String deliveryRoutesCollection = 'delivery_routes';
  static const String communityRequestsCollection = 'community_requests';
  static const String impactMetricsCollection = 'impact_metrics';
  static const String nutritionProfilesCollection = 'nutrition_profiles';
  static const String auditLogsCollection = 'audit_logs';

  // User Roles
  static const String roleDonor = 'DONOR';
  static const String roleNgo = 'NGO';
  static const String roleVolunteer = 'VOLUNTEER';
  static const String roleCommunity = 'COMMUNITY';
  static const String roleAdmin = 'ADMIN';

  // Donation Status
  static const String statusPending = 'pending';
  static const String statusAvailable = 'available';
  static const String statusMatched = 'matched';
  static const String statusInTransit = 'in_transit';
  static const String statusDelivered = 'delivered';
  static const String statusCancelled = 'cancelled';
  static const String statusExpired = 'expired';

  // Food Risk Score
  static const String riskSafe = 'SAFE';
  static const String riskConditional = 'CONDITIONAL';
  static const String riskReject = 'REJECT';

  // Donation Categories
  static const List<String> foodCategories = [
    'Frutas y Verduras',
    'Lácteos',
    'Panadería',
    'Carnes y Proteínas',
    'Granos y Cereales',
    'Comida Preparada',
    'Bebidas',
    'Enlatados',
    'Otros',
  ];

  // Units
  static const List<String> weightUnits = ['kg', 'g', 'lb', 'oz'];
  static const List<String> volumeUnits = ['L', 'mL', 'oz_fl'];
  static const List<String> countUnits = ['unidades', 'cajas', 'bolsas', 'porciones'];

  // CO2 factor (kg CO2 per kg food saved)
  static const double co2PerKgFood = 2.5;

  // Map defaults (CDMX)
  static const double defaultLatitude = 19.4326;
  static const double defaultLongitude = -99.1332;
  static const double defaultZoom = 12.0;

  // Pagination
  static const int defaultPageSize = 20;

  // Cache
  static const Duration cacheExpiry = Duration(minutes: 10);
  static const Duration shortCacheExpiry = Duration(minutes: 2);

  // Notification channels
  static const String notifChannelDonations = 'donations_channel';
  static const String notifChannelMatching = 'matching_channel';
  static const String notifChannelDelivery = 'delivery_channel';
}
