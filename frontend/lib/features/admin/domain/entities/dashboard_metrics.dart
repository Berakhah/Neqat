class DashboardMetrics {
  final int totalUsers;
  final int activeUsers; 
  final int newUsersLastMonth;
  final List<Map<String, dynamic>> usersByDay;
  final List<Map<String, dynamic>> recentLogs;
  final int pendingPosts;
  final int pendingComments;
  final int unresolvedFlags;
  final List<Map<String, dynamic>> recentActivities;
  final int newUsersToday;
  final Map<String, List<int>> contentTrends;
  final Map<String, int> contentByCategory;
  final int totalContentToday;
  final int totalContentThisWeek;
  final int totalContentThisMonth;
  final Map<String, List<int>> userTrends;
  final Map<String, int> usersByLocation;
  final Map<String, double> userEngagementRates;
  
  DashboardMetrics({
    required this.totalUsers,
    required this.activeUsers,
    required this.newUsersLastMonth,
    required this.usersByDay,
    required this.recentLogs,
    this.pendingPosts = 0,
    this.pendingComments = 0,
    this.unresolvedFlags = 0,
    this.recentActivities = const [],
    this.newUsersToday = 0,
    this.contentTrends = const {'daily': [], 'weekly': [], 'monthly': []},
    this.contentByCategory = const {},
    this.totalContentToday = 0,
    this.totalContentThisWeek = 0,
    this.totalContentThisMonth = 0,
    this.userTrends = const {'daily': [], 'weekly': [], 'monthly': []},
    this.usersByLocation = const {},
    this.userEngagementRates = const {},
  });

  factory DashboardMetrics.empty() {
    return DashboardMetrics(
      totalUsers: 0,
      activeUsers: 0,
      newUsersLastMonth: 0,
      usersByDay: [],
      recentLogs: [],
      pendingPosts: 0,
      pendingComments: 0,
      unresolvedFlags: 0,
      recentActivities: [],
      newUsersToday: 0,
      contentTrends: {'daily': [], 'weekly': [], 'monthly': []},
      contentByCategory: {},
      totalContentToday: 0,
      totalContentThisWeek: 0,
      totalContentThisMonth: 0,
      userTrends: {'daily': [], 'weekly': [], 'monthly': []},
      usersByLocation: {},
      userEngagementRates: {},
    );
  }

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    // Get the values from the backend response, with defaults if they're missing
    return DashboardMetrics(
      totalUsers: json['total_users'] ?? 0,
      activeUsers: json['active_users'] ?? 0,
      newUsersLastMonth: json['new_users_last_30_days'] ?? 0,
      usersByDay: List<Map<String, dynamic>>.from(json['users_by_day'] ?? []),
      recentLogs: List<Map<String, dynamic>>.from(json['recent_logs'] ?? []),
      
      // These are not in the default dashboard endpoint, but we'll add placeholder values
      // They can be populated later from separate API calls if needed
      pendingPosts: json['pending_posts'] ?? 0,
      pendingComments: json['pending_comments'] ?? 0,
      unresolvedFlags: json['unresolved_flags'] ?? 0,
      recentActivities: List<Map<String, dynamic>>.from(json['recent_activities'] ?? []),
      newUsersToday: json['new_users_today'] ?? 0,
      
      // Analytics data
      contentTrends: json['content_trends'] != null 
          ? Map<String, List<int>>.from(json['content_trends'].map(
              (key, value) => MapEntry(key, List<int>.from(value))
            ))
          : {'daily': [], 'weekly': [], 'monthly': []},
      
      contentByCategory: json['content_by_category'] != null 
          ? Map<String, int>.from(json['content_by_category'])
          : {},
          
      totalContentToday: json['total_content_today'] ?? 0,
      totalContentThisWeek: json['total_content_this_week'] ?? 0,
      totalContentThisMonth: json['total_content_this_month'] ?? 0,
      
      // User insights data
      userTrends: json['user_trends'] != null
          ? Map<String, List<int>>.from(json['user_trends'].map(
              (key, value) => MapEntry(key, List<int>.from(value))
            ))
          : {'daily': [], 'weekly': [], 'monthly': []},
          
      usersByLocation: json['users_by_location'] != null
          ? Map<String, int>.from(json['users_by_location'])
          : {},
          
      userEngagementRates: json['user_engagement_rates'] != null
          ? Map<String, double>.from(json['user_engagement_rates'])
          : {},
    );
  }
} 