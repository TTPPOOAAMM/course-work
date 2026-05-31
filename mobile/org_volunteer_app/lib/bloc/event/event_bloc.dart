import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';
import '../../data/api_client.dart';

abstract class EventState extends Equatable {
  @override
  List<Object?> get props => [];
}

class EventInitial extends EventState {}
class EventLoading extends EventState {}

class LocationsLoaded extends EventState {
  final List<dynamic> locations;
  LocationsLoaded(this.locations);
  @override
  List<Object?> get props => [locations];
}

class EventCreateSuccess extends EventState {}
class EventUpdateSuccess extends EventState {} 

class EventError extends EventState {
  final String message;
  EventError(this.message);
  @override
  List<Object?> get props => [message];
}

abstract class EventEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadLocations extends EventEvent {}

class CreateNewEvent extends EventEvent {
  final String title;
  final String description;
  final String eventDate; 
  final int locationId;
  final int maxParticipants;

  CreateNewEvent({
    required this.title,
    required this.description,
    required this.eventDate,
    required this.locationId,
    required this.maxParticipants,
  });

  @override
  List<Object?> get props => [title, description, eventDate, locationId, maxParticipants];
}

class UpdateEvent extends EventEvent {
  final int eventId;
  final String title;
  final String description;
  final String eventDate; 
  final int locationId;
  final int maxParticipants;

  UpdateEvent({
    required this.eventId,
    required this.title,
    required this.description,
    required this.eventDate,
    required this.locationId,
    required this.maxParticipants,
  });

  @override
  List<Object?> get props => [eventId, title, description, eventDate, locationId, maxParticipants];
}

class EventBloc extends Bloc<EventEvent, EventState> {
  final ApiClient _apiClient = ApiClient();
  List<dynamic> _cachedLocations = [];
  
  EventBloc() : super(EventInitial()) {
    on<LoadLocations>(_onLoadLocations);
    on<CreateNewEvent>(_onCreateNewEvent);
    on<UpdateEvent>(_onUpdateEvent); 
  }

  Future<void> _onLoadLocations(LoadLocations event, Emitter<EventState> emit) async {
    emit(EventLoading());
    try {
      final response = await _apiClient.dio.get('/api/references/locations');
      _cachedLocations = response.data;
      emit(LocationsLoaded(_cachedLocations));
    } catch (e) {
      emit(EventError('Не удалось загрузить список локаций.'));
    }
  }

  Future<void> _onCreateNewEvent(CreateNewEvent event, Emitter<EventState> emit) async {
    emit(EventLoading());
    try {
      await _apiClient.dio.post(
        '/api/events/',
        data: {
          'title': event.title,
          'description': event.description,
          'event_date': event.eventDate,
          'location_id': event.locationId,
          'max_participants': event.maxParticipants,
          'category_ids': [1],
        },
      );
      emit(EventCreateSuccess());
    } on DioException catch (e) {
      final errorMsg = e.response?.data['detail'] ?? 'Ошибка при создании мероприятия';
      emit(EventError(errorMsg.toString()));
      emit(LocationsLoaded(_cachedLocations)); 
    } catch (e) {
      emit(EventError(e.toString()));
      emit(LocationsLoaded(_cachedLocations));
    }
  }

  Future<void> _onUpdateEvent(UpdateEvent event, Emitter<EventState> emit) async {
    emit(EventLoading());
    try {
      await _apiClient.dio.put(
        '/api/events/${event.eventId}',
        data: {
          'title': event.title,
          'description': event.description,
          'event_date': event.eventDate,
          'location_id': event.locationId,
          'max_participants': event.maxParticipants,
        },
      );
      emit(EventUpdateSuccess());
    } on DioException catch (e) {
      final errorMsg = e.response?.data['detail'] ?? 'Ошибка при обновлении мероприятия';
      emit(EventError(errorMsg.toString()));
      emit(LocationsLoaded(_cachedLocations)); 
    } catch (e) {
      emit(EventError(e.toString()));
      emit(LocationsLoaded(_cachedLocations));
    }
  }
}