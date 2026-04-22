import 'package:frontend/features/admin/data/datasources/admin_api_service.dart';
import 'package:frontend/features/admin/domain/entities/dashboard_metrics.dart';
import 'package:frontend/features/admin/domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final AdminApiService apiService;

  DashboardRepositoryImpl(this.apiService);

  @override
  Future<DashboardMetrics> getDashboardMetrics() async {
    try {
      final response = await apiService.getDashboardData();
      return DashboardMetrics.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load dashboard metrics: $e');
    }
  }

  @override
  Future<Map<String, List<int>>> getContentTrends({required String period}) async {
    try {
      final response = await apiService.getContentTrends(period: period);
      return _convertToTrendData(response);
    } catch (e) {
      throw Exception('Failed to load content trends: $e');
    }
  }

  @override
  Future<Map<String, int>> getContentCountByCategory() async {
    try {
      final response = await apiService.getContentByCategory();
      return Map<String, int>.from(response);
    } catch (e) {
      throw Exception('Failed to load content by category: $e');
    }
  }

  @override
  Future<Map<String, double>> getUserEngagementRates() async {
    try {
      final response = await apiService.getUserEngagementRates();
      return Map<String, double>.from(response);
    } catch (e) {
      throw Exception('Failed to load user engagement rates: $e');
    }
  }

  @override
  Future<Map<String, List<int>>> getUserTrends({required String period}) async {
    try {
      final response = await apiService.getUserTrends(period: period);
      return _convertToTrendData(response);
    } catch (e) {
      throw Exception('Failed to load user trends: $e');
    }
  }

  @override
  Future<Map<String, int>> getUsersCountByLocation() async {
    try {
      final response = await apiService.getUsersByLocation();
      return Map<String, int>.from(response);
    } catch (e) {
      throw Exception('Failed to load users by location: $e');
    }
  }

  Map<String, List<int>> _convertToTrendData(Map<String, dynamic> response) {
    final Map<String, List<int>> result = {};
    
    response.forEach((key, value) {
      if (value is List) {
        result[key] = List<int>.from(value.map((item) => item as int));
      }
    });
    
    return result;
  }
} 