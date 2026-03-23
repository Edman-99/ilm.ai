import 'package:equatable/equatable.dart';
import 'package:bloc/bloc.dart';

import 'package:ai_stock_analyzer/data/user_plan.dart';

// ── Model ──

class MockUser {
  const MockUser({
    required this.email,
    required this.password,
    this.plan = UserPlan.free,
  });

  final String email;
  final String password;
  final UserPlan plan;
}

// ── State ──

enum AuthStatus { unauthenticated, loading, authenticated, error }

/// Error keys used by AuthCubit — UI translates via AppStrings.
class AuthErrorKey {
  static const accountNotFound = 'accountNotFound';
  static const wrongPassword = 'wrongPassword';
  static const emailTaken = 'emailTaken';
}

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.user,
    this.errorKey,
  });

  final AuthStatus status;
  final MockUser? user;
  final String? errorKey;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    MockUser? user,
    String? errorKey,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorKey: errorKey,
    );
  }

  @override
  List<Object?> get props => [status, user?.email, errorKey];
}

// ── Cubit ──

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthState());

  final _users = <String, MockUser>{
    'free@test.com': const MockUser(
      email: 'free@test.com',
      password: '123',
      plan: UserPlan.free,
    ),
    'pro@test.com': const MockUser(
      email: 'pro@test.com',
      password: '123',
      plan: UserPlan.pro,
    ),
    'premium@test.com': const MockUser(
      email: 'premium@test.com',
      password: '123',
      plan: UserPlan.premium,
    ),
  };

  Future<void> login(String email, String password) async {
    emit(state.copyWith(status: AuthStatus.loading));

    await Future<void>.delayed(const Duration(milliseconds: 400));

    final user = _users[email.toLowerCase()];
    if (user == null) {
      emit(const AuthState(
        status: AuthStatus.error,
        errorKey: AuthErrorKey.accountNotFound,
      ));
      return;
    }

    if (user.password != password) {
      emit(const AuthState(
        status: AuthStatus.error,
        errorKey: AuthErrorKey.wrongPassword,
      ));
      return;
    }

    emit(AuthState(status: AuthStatus.authenticated, user: user));
  }

  Future<void> register(String email, String password) async {
    emit(state.copyWith(status: AuthStatus.loading));

    await Future<void>.delayed(const Duration(milliseconds: 400));

    final key = email.toLowerCase();
    if (_users.containsKey(key)) {
      emit(const AuthState(
        status: AuthStatus.error,
        errorKey: AuthErrorKey.emailTaken,
      ));
      return;
    }

    final user = MockUser(email: key, password: password);
    _users[key] = user;

    emit(AuthState(status: AuthStatus.authenticated, user: user));
  }

  void logout() {
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}
