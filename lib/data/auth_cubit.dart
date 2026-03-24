import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:bloc/bloc.dart';

import 'package:ai_stock_analyzer/data/user_plan.dart';

// ── Model ──

class AuthUser {
  const AuthUser({
    required this.email,
    this.plan = UserPlan.free,
  });

  final String email;
  final UserPlan plan;
}

// ── State ──

enum AuthStatus { unauthenticated, loading, authenticated, error }

class AuthErrorKey {
  static const accountNotFound = 'accountNotFound';
  static const wrongPassword = 'wrongPassword';
  static const emailTaken = 'emailTaken';
  static const networkError = 'networkError';
}

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.user,
    this.errorKey,
  });

  final AuthStatus status;
  final AuthUser? user;
  final String? errorKey;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
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
  AuthCubit({required Dio httpClient})
      : _http = httpClient,
        super(const AuthState());

  final Dio _http;

  String? _token;

  String? get token => _token;

  Future<void> login(String email, String password) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      final resp = await _http.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email.toLowerCase(), 'password': password},
      );

      final data = resp.data!;
      _setToken(data['token'] as String?);

      final user = AuthUser(
        email: data['email'] as String? ?? email.toLowerCase(),
        plan: _parsePlan(data['plan']),
      );

      emit(AuthState(status: AuthStatus.authenticated, user: user));
    } on DioException catch (e) {
      final errorKey = _mapError(e);
      emit(AuthState(status: AuthStatus.error, errorKey: errorKey));
    }
  }

  Future<void> register(String email, String password) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      final resp = await _http.post<Map<String, dynamic>>(
        '/auth/register',
        data: {'email': email.toLowerCase(), 'password': password},
      );

      final data = resp.data!;
      _setToken(data['token'] as String?);

      final user = AuthUser(
        email: data['email'] as String? ?? email.toLowerCase(),
        plan: _parsePlan(data['plan']),
      );

      emit(AuthState(status: AuthStatus.authenticated, user: user));
    } on DioException catch (e) {
      final errorKey = _mapError(e);
      emit(AuthState(status: AuthStatus.error, errorKey: errorKey));
    }
  }

  void logout() {
    _setToken(null);
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  void _setToken(String? token) {
    _token = token;
    if (token != null) {
      _http.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _http.options.headers.remove('Authorization');
    }
  }

  UserPlan _parsePlan(dynamic value) {
    if (value is String) {
      return UserPlan.values.firstWhere(
        (p) => p.name == value,
        orElse: () => UserPlan.free,
      );
    }
    return UserPlan.free;
  }

  String _mapError(DioException e) {
    final statusCode = e.response?.statusCode;
    if (statusCode == null) return AuthErrorKey.networkError;

    final body = e.response?.data;
    final message = body is Map ? (body['error'] ?? body['message'] ?? '') : '';
    final msg = message.toString().toLowerCase();

    if (statusCode == 404 || msg.contains('not found')) {
      return AuthErrorKey.accountNotFound;
    }
    if (statusCode == 401 || msg.contains('password')) {
      return AuthErrorKey.wrongPassword;
    }
    if (statusCode == 409 || msg.contains('exists') || msg.contains('taken')) {
      return AuthErrorKey.emailTaken;
    }
    return AuthErrorKey.networkError;
  }
}
