import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../../data/api_client.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiClient _apiClient = ApiClient();
  final _storage = const FlutterSecureStorage();

  AuthBloc() : super(AuthInitial()) {
    on<AuthCheckStatus>(_onCheckStatus);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onCheckStatus(AuthCheckStatus event, Emitter<AuthState> emit) async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      emit(Authenticated());
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoginRequested(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await _apiClient.dio.post(
        '/api/auth/login',
        data: {
          'username': event.email,
          'password': event.password,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      final token = response.data['access_token'];
      await _storage.write(key: 'access_token', value: token);

      final userResponse = await _apiClient.dio.get('/api/users/me');
      final roleId = userResponse.data['role_id'];

      if (roleId == 2) {
        emit(Authenticated());
      } else {
        await _storage.delete(key: 'access_token');
        emit(const AuthFailure('Доступ запрещен. Вы волонтер, а это приложение для Организаторов.'));
      }
      } on DioException catch (e) {
        print('DIO ERROR: ${e.message}'); 
        final errorMessage = e.response?.data['detail'] ?? 'Ошибка сети: ${e.message}';
        emit(AuthFailure(errorMessage.toString()));
      } catch (e) {
        print('GENERAL ERROR: $e');
        emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onRegisterRequested(AuthRegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _apiClient.dio.post('/api/auth/register', data: {
        'full_name': event.fullName,
        'email': event.email,
        'password': event.password,
        'role_id': 2,
      });
      
      add(AuthLoginRequested(email: event.email, password: event.password));
    } on DioException catch (e) {
      print('DIO ERROR: ${e.message}'); 
      final errorMessage = e.response?.data['detail'] ?? 'Ошибка сети: ${e.message}';
      emit(AuthFailure(errorMessage.toString()));
    } catch (e) {
      print('GENERAL ERROR: $e');
      emit(AuthFailure(e.toString()));    }
  }

  Future<void> _onLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    await _storage.delete(key: 'access_token');
    emit(Unauthenticated());
  }
}