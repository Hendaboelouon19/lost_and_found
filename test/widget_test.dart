import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:errasoft/core/di/dependency_injection.dart';
import 'package:errasoft/core/networking/api_service.dart';
import 'package:errasoft/core/utils/local_storage.dart';
import 'package:errasoft/features/auth/login/data/models/login_request_model.dart';
import 'package:errasoft/features/auth/login/data/repo/login_repository.dart';
import 'package:errasoft/features/auth/login/presentation/screens/login_screen.dart';
import 'package:errasoft/features/auth/register/home/data/models/lost_found_report.dart';
import 'package:errasoft/features/auth/register/home/presentation/cubit/home_cubit.dart';
import 'package:errasoft/features/auth/register/home/presentation/screens/home_screen.dart';
import 'package:errasoft/main.dart';

class _OfflineApiService extends ApiService {
  _OfflineApiService() : super(Dio());

  @override
  Future<Response> login({
    required String email,
    required String password,
  }) async {
    throw DioException(
      type: DioExceptionType.connectionError,
      requestOptions: RequestOptions(path: '/login'),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    getIt.reset();
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    await setupGetIt();
  });

  test('falls back to local login when there is no internet connection', () async {
    final repository = LoginRepository(_OfflineApiService(), LocalStorage.instance);

    final response = await repository.login(
      const LoginRequestModel(
        email: 'offline@test.com',
        password: '123456',
      ),
    );

    expect(response.token, isNotEmpty);
    expect(await LocalStorage.instance.getToken(), isNotNull);
  });

  testWidgets('shows login screen when no saved user token exists', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('shows home screen when a saved token exists', (tester) async {
    SharedPreferences.setMockInitialValues({
      'token': 'mock-token',
      'user_id': 'mock-user-id',
    });
    await LocalStorage.init();

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  test('calculates a strong match for matching lost and found reports', () {
    final lost = LostFoundReport(
      id: 'lost-1',
      title: 'Black AirPods',
      type: ReportType.lost,
      category: 'Electronics',
      location: 'Gate 3',
      time: 'Today, 5:15 PM',
      description: 'Black AirPods with a charging case and a scratch on the right side.',
    );

    final found = LostFoundReport(
      id: 'found-1',
      title: 'Black AirPods',
      type: ReportType.found,
      category: 'Electronics',
      location: 'Gate 3',
      time: 'Today, 5:30 PM',
      description: 'One earbud was still charging near the entrance.',
    );

    final score = LostFoundReport.calculateMatchProbability(lost, found);

    expect(score, greaterThan(80));
    expect(score, lessThanOrEqualTo(100));
  });

  test('adds a newly submitted report to the home list', () async {
    final cubit = HomeCubit();
    await cubit.loadItems();

    final newReport = LostFoundReport(
      id: 'new-1',
      title: 'Wallet',
      type: ReportType.found,
      category: 'Accessories',
      location: 'Library desk',
      time: 'Today, 9:00 AM',
      description: 'Brown wallet with a student ID inside.',
    );

    cubit.addReport(newReport);

    final state = cubit.state;
    expect(state, isA<HomeLoaded>());
    final loaded = state as HomeLoaded;
    expect(loaded.items.any((item) => item.id == 'new-1'), isTrue);
  });
}
