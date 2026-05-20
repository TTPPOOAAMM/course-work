import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/api_client.dart';

abstract class MyEventsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class MyEventsLoading extends MyEventsState {}

class MyEventsLoaded extends MyEventsState {
  final List<dynamic> events;
  MyEventsLoaded(this.events);
  
  @override
  List<Object?> get props => [events];
}

class MyEventsError extends MyEventsState {
  final String message;
  MyEventsError(this.message);
  
  @override
  List<Object?> get props => [message];
}

class LoadMyEvents extends Equatable {
  @override
  List<Object?> get props => [];
}

class MyEventsBloc extends Bloc<LoadMyEvents, MyEventsState> {
  final ApiClient _apiClient = ApiClient();

  MyEventsBloc() : super(MyEventsLoading()) {
    on<LoadMyEvents>((event, emit) async {
      emit(MyEventsLoading());
      try {
        final response = await _apiClient.dio.get('/api/events/me');
        
        List<dynamic> events = response.data;
        events.sort((a, b) => DateTime.parse(b['event_date']).compareTo(DateTime.parse(a['event_date'])));
        
        emit(MyEventsLoaded(events));
      } catch (e) {
        emit(MyEventsError('Не удалось загрузить ваши мероприятия'));
      }
    });
  }
}