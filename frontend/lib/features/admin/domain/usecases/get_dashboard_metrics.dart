import 'package:frontend/features/admin/domain/entities/dashboard_metrics.dart';
import 'package:frontend/features/admin/domain/repositories/dashboard_repository.dart';

class GetDashboardMetrics {
  final DashboardRepository repository;

  GetDashboardMetrics(this.repository);

  Future<DashboardMetrics> call() async {
    return await repository.getDashboardMetrics();
  }
} 