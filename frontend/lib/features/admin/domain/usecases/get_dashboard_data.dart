import 'package:frontend/shared/domain/utils/either.dart';
import 'package:frontend/shared/domain/error/failure.dart';
import 'package:frontend/features/admin/domain/entities/dashboard_metrics.dart';
import 'package:frontend/features/admin/domain/repositories/admin_repository.dart';

class GetDashboardData {
  final AdminRepository repository;

  GetDashboardData(this.repository);

  Future<Either<Failure, DashboardMetrics>> call() {
    return repository.getDashboardData();
  }
} 