import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zindagi_plus/data/repositories/implementations/auth_repository_mock.dart';
import 'package:zindagi_plus/data/repositories/implementations/health_repository_mock.dart';
import 'package:zindagi_plus/data/repositories/interfaces/auth_repository.dart';
import 'package:zindagi_plus/data/repositories/interfaces/health_repository.dart';

/// Provides the active [AuthRepository] implementation.
///
/// Swap [AuthRepositoryMock] for `AuthRepositoryImpl` when the Django
/// backend is ready — no other code needs to change.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryMock(),
);

/// Provides the active [HealthRepository] implementation.
final healthRepositoryProvider = Provider<HealthRepository>(
  (ref) => HealthRepositoryMock(),
);
