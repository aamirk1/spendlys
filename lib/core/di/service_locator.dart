import 'package:get_it/get_it.dart';
import 'package:spendly/core/storage/secure_storage_service.dart';
import 'package:spendly/core/network/api_client.dart';
import 'package:spendly/core/network/api_constants.dart';
import 'package:spendly/core/services/network_service.dart';
import 'package:spendly/core/services/notification_service.dart';
import 'package:spendly/core/services/reminder_notification_service.dart';
import 'package:spendly/core/services/security_service.dart';
import 'package:spendly/core/services/connectivity_service.dart';
import 'package:spendly/core/services/sync_service.dart';
import 'package:spendly/features/auth/data/services/auth_service.dart';
import 'package:spendly/core/services/app_update_service.dart';
import 'package:spendly/features/business/data/services/business_service.dart';
import 'package:get_storage/get_storage.dart';

// Cubits imports will be added here
import 'package:spendly/core/theme/theme_cubit.dart';
import 'package:spendly/core/localization/localization_cubit.dart';
import 'package:spendly/features/auth/presentation/cubits/onboarding_cubit.dart';
import 'package:spendly/features/user_profile/presentation/cubits/user_info_cubit.dart';
import 'package:spendly/features/splash/presentation/cubits/splash_cubit.dart';
import 'package:spendly/features/auth/presentation/cubits/sign_in_cubit.dart';
import 'package:spendly/features/auth/presentation/cubits/sign_up_cubit.dart';
import 'package:spendly/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:spendly/features/auth/presentation/cubits/forgot_password_cubit.dart';
import 'package:spendly/features/auth/presentation/cubits/change_password_cubit.dart';
import 'package:spendly/features/income_expense/presentation/cubits/expense_cubit.dart';
import 'package:spendly/features/income_expense/presentation/cubits/income_cubit.dart';
import 'package:spendly/features/category/presentation/cubits/category_cubit.dart';
import 'package:spendly/features/income_expense/presentation/cubits/ledger_cubit.dart';
import 'package:spendly/features/lend_borrow/presentation/cubits/loan_cubit.dart';
import 'package:spendly/features/premium/presentation/cubits/payment_cubit.dart';
import 'package:spendly/features/chat/presentation/cubits/chat_cubit.dart';
import 'package:spendly/features/chat/presentation/cubits/message_cubit.dart';
import 'package:spendly/features/user_profile/presentation/cubits/feedback_cubit.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // 1. External & Storage dependencies
  final secureStorage = SecureStorageService();
  getIt.registerSingleton<SecureStorageService>(secureStorage);

  final box = GetStorage();
  getIt.registerSingleton<GetStorage>(box);

  // 2. Core Infrastructure & Services
  getIt.registerSingleton<ApiClient>(
    ApiClient(baseUrl: ApiConstants.baseUrl, secureStorage: secureStorage),
  );
  getIt.registerSingleton<NetworkService>(NetworkService());
  getIt.registerSingleton<SyncService>(SyncService());
  getIt.registerSingleton<ConnectivityService>(ConnectivityService());
  getIt.registerSingleton<AuthService>(AuthService());
  getIt.registerSingleton<AppUpdateService>(AppUpdateService());
  getIt.registerSingleton<BusinessService>(BusinessService());

  // 3. Asynchronous Services Init
  final notificationService = NotificationService();
  await notificationService.init();
  getIt.registerSingleton<NotificationService>(notificationService);

  final reminderService = ReminderNotificationService();
  await reminderService.init();
  getIt.registerSingleton<ReminderNotificationService>(reminderService);

  final securityService = SecurityService();
  await securityService.init();
  getIt.registerSingleton<SecurityService>(securityService);

  // 4. Cubits registration
  getIt.registerLazySingleton<ThemeCubit>(() => ThemeCubit(getIt<GetStorage>()));
  getIt.registerLazySingleton<LocalizationCubit>(() => LocalizationCubit(getIt<GetStorage>()));
  getIt.registerFactory<OnboardingCubit>(() => OnboardingCubit(getIt<GetStorage>()));
  getIt.registerLazySingleton<UserInfoCubit>(() => UserInfoCubit(getIt<GetStorage>()));
  getIt.registerFactory<SplashCubit>(() => SplashCubit(
        getIt<GetStorage>(),
        getIt<AppUpdateService>(),
        getIt<SignInCubit>(),
        getIt<SecureStorageService>(),
        getIt<AuthService>(),
      ));
  getIt.registerFactory<SignInCubit>(() => SignInCubit(
        getIt<SecureStorageService>(),
        getIt<GetStorage>(),
      ));
  getIt.registerFactory<SignUpCubit>(() => SignUpCubit(
        getIt<GetStorage>(),
      ));
  getIt.registerFactory<AuthCubit>(() => AuthCubit(
        getIt<AuthService>(),
        getIt<GetStorage>(),
      ));
  getIt.registerFactory<ForgotPasswordCubit>(() => ForgotPasswordCubit());
  getIt.registerFactory<ChangePasswordCubit>(() => ChangePasswordCubit());

  // Feature Cubits
  getIt.registerLazySingleton<ExpenseCubit>(() => ExpenseCubit(
        getIt<AuthService>(),
      ));
  getIt.registerLazySingleton<IncomeCubit>(() => IncomeCubit(
        getIt<AuthService>(),
      ));
  getIt.registerLazySingleton<CategoryCubit>(() => CategoryCubit(
        getIt<AuthService>(),
      ));
  getIt.registerLazySingleton<LedgerCubit>(() => LedgerCubit(
        getIt<AuthService>(),
        getIt<ExpenseCubit>(),
        getIt<IncomeCubit>(),
        getIt<LoanCubit>(),
      ));
  getIt.registerLazySingleton<LoanCubit>(() => LoanCubit(
        getIt<AuthService>(),
      ));
  getIt.registerLazySingleton<PaymentCubit>(() => PaymentCubit(
        getIt<GetStorage>(),
      ));
  getIt.registerLazySingleton<ChatCubit>(() => ChatCubit(
        getIt<AuthService>(),
      ));
  getIt.registerLazySingleton<MessageCubit>(() => MessageCubit());
  getIt.registerFactory<FeedbackCubit>(() => FeedbackCubit(
        getIt<AuthService>(),
        getIt<ApiClient>(),
      ));
}
