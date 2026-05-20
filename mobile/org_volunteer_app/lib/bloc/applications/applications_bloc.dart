import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';
import '../../data/api_client.dart';

abstract class ApplicationsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ApplicationsLoading extends ApplicationsState {}

class ApplicationsLoaded extends ApplicationsState {
  final List<dynamic> applications;
  ApplicationsLoaded(this.applications);

  @override
  List<Object?> get props => [applications];
}

class ApplicationsError extends ApplicationsState {
  final String message;
  ApplicationsError(this.message);

  @override
  List<Object?> get props => [message];
}

abstract class ApplicationsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadEventApplications extends ApplicationsEvent {
  final int eventId;
  LoadEventApplications(this.eventId);

  @override
  List<Object?> get props => [eventId];
}

class ChangeApplicationStatus extends ApplicationsEvent {
  final int eventId;
  final int applicationId;
  final String newStatus;

  ChangeApplicationStatus(this.eventId, this.applicationId, this.newStatus);

  @override
  List<Object?> get props => [eventId, applicationId, newStatus];
}

class ApplicationsBloc extends Bloc<ApplicationsEvent, ApplicationsState> {
  final ApiClient _apiClient = ApiClient();

  ApplicationsBloc() : super(ApplicationsLoading()) {
    on<LoadEventApplications>(_onLoadEventApplications);
    on<ChangeApplicationStatus>(_onChangeStatus);
  }

  Future<void> _onLoadEventApplications(LoadEventApplications event, Emitter<ApplicationsState> emit) async {
    emit(ApplicationsLoading());
    try {
      final response = await _apiClient.dio.get('/api/events/${event.eventId}/applications');
      emit(ApplicationsLoaded(response.data));
    } catch (e) {
      emit(ApplicationsError('Не удалось загрузить список заявок'));
    }
  }

  Future<void> _onChangeStatus(ChangeApplicationStatus event, Emitter<ApplicationsState> emit) async {
    try {
      await _apiClient.dio.patch(
        '/api/applications/${event.applicationId}/status',
        data: {'status': event.newStatus},
      );
      
      add(LoadEventApplications(event.eventId));
    } on DioException catch (e) {
      final errorMsg = e.response?.data['detail'] ?? 'Ошибка при смене статуса';
      emit(ApplicationsError(errorMsg.toString()));
    } catch (e) {
      emit(ApplicationsError(e.toString()));
    }
  }
}