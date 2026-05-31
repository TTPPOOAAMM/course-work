import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/my_events/my_events_bloc.dart';
import '../data/api_client.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ApiClient _apiClient = ApiClient();

  String _statusFilter = 'all'; 
  String _dateOrder = 'newest'; 
  String _searchQuery = '';    
  
  List<dynamic> _locations = [];
  int _selectedLocationId = 0; // 0 означает сброс фильтра и показ всех событий

  @override
  void initState() {
    super.initState();
    _loadLocationsAndEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLocationsAndEvents() async {
    try {
      final response = await _apiClient.dio.get('/api/references/locations');
      if (mounted) {
        setState(() {
          _locations = response.data;
        });
      }
    } catch (_) {
      // Изолируем ошибку, чтобы пустой справочник локаций не ломал загрузку событий
    }
    _loadEvents();
  }

  void _loadEvents() {
    context.read<MyEventsBloc>().add(
      LoadMyEvents(
        statusFilter: _statusFilter, 
        dateOrder: _dateOrder,
        searchQuery: _searchQuery,
        locationFilter: _selectedLocationId, 
      ),
    );
  }

  void _updateStatusFilter(String status) {
    setState(() {
      _statusFilter = status;
    });
    _loadEvents();
  }

  void _showDeleteConfirmation(BuildContext context, int eventId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удаление мероприятия'),
        content: const Text('Вы уверены, что хотите перевести это мероприятие в архив? Все необработанные заявки волонтеров автоматически закроются.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<MyEventsBloc>().add(
                ArchiveEvent(
                  eventId: eventId,
                  statusFilter: _statusFilter,
                  dateOrder: _dateOrder,
                  searchQuery: _searchQuery,
                  locationFilter: _selectedLocationId,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    String text;
    
    switch (status) {
      case 'active':
        bgColor = Colors.green;
        text = 'Активно';
        break;
      case 'closed':
        bgColor = Colors.orange;
        text = 'Закрыто';
        break;
      case 'completed':
        bgColor = Colors.blue;
        text = 'Завершено';
        break;
      case 'archived':
        bgColor = Colors.grey;
        text = 'В архиве';
        break;
      default:
        bgColor = Colors.blueGrey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bgColor),
      ),
      child: Text(
        text,
        style: TextStyle(color: bgColor, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои мероприятия'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.swap_vert),
            tooltip: 'Сортировка по дате',
            onSelected: (value) {
              setState(() {
                _dateOrder = value;
              });
              _loadEvents();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'newest',
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_downward, 
                      color: _dateOrder == 'newest' ? Theme.of(context).colorScheme.primary : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    const Text('Сначала новые'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'oldest',
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_upward, 
                      color: _dateOrder == 'oldest' ? Theme.of(context).colorScheme.primary : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    const Text('Сначала старые'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Поле поиска по названию события
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 4.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск по названию...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                          _loadEvents();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _loadEvents();
              },
            ),
          ),

          // Выпадающий список выбора района
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: DropdownButtonFormField<int>(
              decoration: InputDecoration(
                labelText: 'Фильтр по району',
                prefixIcon: const Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              ),
              value: _selectedLocationId,
              items: [
                // ИСПРАВЛЕНО: Текст изменен на более понятный и точный в соответствии с логикой
                const DropdownMenuItem<int>(
                  value: 0,
                  child: Text('Все мероприятия (без фильтра)'),
                ),
                ..._locations.map((loc) {
                  return DropdownMenuItem<int>(
                    value: loc['ID_Locations'],
                    child: Text(loc['district_name']),
                  );
                }),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedLocationId = val ?? 0;
                });
                _loadEvents();
              },
            ),
          ),

          // Панель выбора статуса (Фильтрация)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Все'),
                  selected: _statusFilter == 'all',
                  onSelected: (selected) => _updateStatusFilter('all'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Активные'),
                  selected: _statusFilter == 'active',
                  onSelected: (selected) => _updateStatusFilter('active'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Закрытые'),
                  selected: _statusFilter == 'closed',
                  onSelected: (selected) => _updateStatusFilter('closed'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Завершенные'),
                  selected: _statusFilter == 'completed',
                  onSelected: (selected) => _updateStatusFilter('completed'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('В архиве'),
                  selected: _statusFilter == 'archived',
                  onSelected: (selected) => _updateStatusFilter('archived'),
                ),
              ],
            ),
          ),

          // Основной список событий
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _loadLocationsAndEvents();
              },
              child: BlocBuilder<MyEventsBloc, MyEventsState>(
                builder: (context, state) {
                  if (state is MyEventsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is MyEventsError) {
                    return ListView(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                        Center(child: Text(state.message, style: const TextStyle(color: Colors.red))),
                      ],
                    );
                  } else if (state is MyEventsLoaded) {
                    if (state.events.isEmpty) {
                      return ListView(
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                          const Center(
                            child: Text(
                              'Мероприятий не найдено.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: state.events.length,
                      itemBuilder: (context, index) {
                        final event = state.events[index];
                        final date = DateTime.parse(event['event_date']).toLocal().toString().split(' ')[0];
                        
                        final int pendingCount = event['pending_count'] ?? 0;
                        final int remainingSeats = event['remaining_seats'] ?? 0;
                        final int maxParticipants = event['max_participants'] ?? 0;
                        final String currentStatus = event['status'] ?? 'active';

                        final int locationId = event['location_id'] ?? 0;
                        final locationData = _locations.firstWhere(
                          (l) => l['ID_Locations'] == locationId,
                          orElse: () => null,
                        );
                        final String locationName = locationData != null ? locationData['district_name'] : 'Район не указан';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              await context.push(
                                '/event-applications/${event['ID_event']}',
                                extra: event['status'],
                              );
                              if (context.mounted) {
                                _loadEvents(); 
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                event['title'],
                                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context).colorScheme.primary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (pendingCount > 0) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  '$pendingCount',
                                                  style: const TextStyle(
                                                    color: Colors.white, 
                                                    fontSize: 11, 
                                                    fontWeight: FontWeight.bold
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      _buildStatusBadge(currentStatus),
                                      
                                      if (currentStatus != 'archived')
                                        PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                                          tooltip: 'Управление событием',
                                          onSelected: (action) async {
                                            if (action == 'delete') {
                                              _showDeleteConfirmation(context, event['ID_event']);
                                            } else if (action == 'edit') {
                                              await context.push('/create-event', extra: event);
                                              if (context.mounted) {
                                                _loadEvents(); 
                                              }
                                            } else {
                                              context.read<MyEventsBloc>().add(
                                                ChangeEventStatus(
                                                  eventId: event['ID_event'],
                                                  newStatus: action,
                                                  statusFilter: _statusFilter,
                                                  dateOrder: _dateOrder,
                                                  searchQuery: _searchQuery,
                                                  locationFilter: _selectedLocationId, 
                                                ),
                                              );
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            if (currentStatus == 'active')
                                              const PopupMenuItem(value: 'closed', child: Text('Закрыть набор')),
                                            if (currentStatus == 'closed')
                                              const PopupMenuItem(value: 'active', child: Text('Открыть набор')),
                                            if (currentStatus == 'active' || currentStatus == 'closed')
                                              const PopupMenuItem(value: 'edit', child: Text('Редактировать инфо')),
                                            if (currentStatus == 'active' || currentStatus == 'closed')
                                              const PopupMenuItem(value: 'completed', child: Text('Завершить событие')),
                                            const PopupMenuItem(
                                              value: 'delete', 
                                              child: Text('Удалить (В архив)', style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Text(date, style: const TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),

                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          locationName, 
                                          style: const TextStyle(color: Colors.grey),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  Text(
                                    event['description'] ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Divider(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        remainingSeats == 0 
                                            ? 'Мест больше нет' 
                                            : 'Осталось мест: $remainingSeats из $maxParticipants',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: remainingSeats == 0 ? Colors.red : Colors.grey.shade700,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          if (pendingCount > 0) ...[
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                          ],
                                          Text(
                                            pendingCount > 0 ? 'Новые заявки ->' : 'Смотреть заявки ->', 
                                            style: TextStyle(
                                              color: pendingCount > 0 ? Colors.red : Colors.blue, 
                                              fontWeight: FontWeight.bold
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/create-event');
          if (context.mounted) {
            _loadLocationsAndEvents();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}