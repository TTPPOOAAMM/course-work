import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/api_client.dart';

// Состояния Блока
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

// События Блока
abstract class MyEventsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadMyEvents extends MyEventsEvent {
  final String statusFilter;
  final String dateOrder;
  final String searchQuery;
  final int? locationFilter; 

  LoadMyEvents({
    this.statusFilter = 'all', 
    this.dateOrder = 'newest', 
    this.searchQuery = '',
    this.locationFilter = 0, // 0 - означает отображение всех мероприятий без фильтра по району
  });

  @override
  List<Object?> get props => [statusFilter, dateOrder, searchQuery, locationFilter];
}

class ChangeEventStatus extends MyEventsEvent {
  final int eventId;
  final String newStatus;
  final String statusFilter;
  final String dateOrder;
  final String searchQuery;
  final int? locationFilter;

  ChangeEventStatus({
    required this.eventId,
    required this.newStatus,
    required this.statusFilter,
    required this.dateOrder,
    required this.searchQuery,
    this.locationFilter = 0,
  });

  @override
  List<Object?> get props => [eventId, newStatus, statusFilter, dateOrder, searchQuery, locationFilter];
}

class ArchiveEvent extends MyEventsEvent {
  final int eventId;
  final String statusFilter;
  final String dateOrder;
  final String searchQuery;
  final int? locationFilter;

  ArchiveEvent({
    required this.eventId,
    required this.statusFilter,
    required this.dateOrder,
    required this.searchQuery,
    this.locationFilter = 0,
  });

  @override
  List<Object?> get props => [eventId, statusFilter, dateOrder, searchQuery, locationFilter];
}

class MyEventsBloc extends Bloc<MyEventsEvent, MyEventsState> {
  final ApiClient _apiClient = ApiClient();

  MyEventsBloc() : super(MyEventsLoading()) {
    
    on<LoadMyEvents>((event, emit) async {
      emit(MyEventsLoading());
      try {
        final filteredEvents = await _fetchAndFilterEvents(
          event.statusFilter, event.dateOrder, event.searchQuery, event.locationFilter
        );
        emit(MyEventsLoaded(filteredEvents));
      } catch (e) {
        emit(MyEventsError('Не удалось загрузить ваши мероприятия'));
      }
    });

    on<ChangeEventStatus>((event, emit) async {
      try {
        await _apiClient.dio.put(
          '/api/events/${event.eventId}',
          data: {'status': event.newStatus},
        );
        final filteredEvents = await _fetchAndFilterEvents(
          event.statusFilter, event.dateOrder, event.searchQuery, event.locationFilter
        );
        emit(MyEventsLoaded(filteredEvents));
      } catch (e) {
        emit(MyEventsError('Не удалось изменить статус мероприятия'));
      }
    });

    on<ArchiveEvent>((event, emit) async {
      try {
        await _apiClient.dio.delete('/api/events/${event.eventId}');
        final filteredEvents = await _fetchAndFilterEvents(
          event.statusFilter, event.dateOrder, event.searchQuery, event.locationFilter
        );
        emit(MyEventsLoaded(filteredEvents));
      } catch (e) {
        emit(MyEventsError('Не удалось архивировать мероприятие'));
      }
    });
  }

  Future<List<dynamic>> _fetchAndFilterEvents(
    String statusFilter, String dateOrder, String searchQuery, int? locationFilter
  ) async {
    final response = await _apiClient.dio.get('/api/events/me');
    List<dynamic> allEvents = response.data;
    List<dynamic> filteredEvents = [];

    // 1. Фильтрация по статусу
    if (statusFilter == 'all') {
      filteredEvents = List.from(allEvents);
    } else {
      filteredEvents = allEvents.where((e) => e['status'] == statusFilter).toList();
    }

    // 2. Фильтрация по поисковому запросу
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filteredEvents = filteredEvents.where((e) {
        final title = (e['title'] ?? '').toString().toLowerCase();
        return title.contains(query);
      }).toList();
    }

    // ИСПРАВЛЕНО: Если выбран 0 или null, фильтр игнорируется, и выводятся ВСЕ события организатора
    if (locationFilter != null && locationFilter != 0) {
      filteredEvents = filteredEvents.where((e) => e['location_id'] == locationFilter).toList();
    }

    // 3. Сортировка по дате
    filteredEvents.sort((a, b) {
      final dateA = DateTime.parse(a['event_date']);
      final dateB = DateTime.parse(b['event_date']);
      if (dateOrder == 'newest') {
        return dateB.compareTo(dateA);
      } else {
        return dateA.compareTo(dateA);
      }
    });

    return filteredEvents;
  }
}