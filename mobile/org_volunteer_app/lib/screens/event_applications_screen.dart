import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/applications/applications_bloc.dart';

class EventApplicationsScreen extends StatefulWidget {
  final int eventId;
  final String eventStatus;

  const EventApplicationsScreen({
    super.key, 
    required this.eventId, 
    required this.eventStatus,
  });

  @override
  State<EventApplicationsScreen> createState() => _EventApplicationsScreenState();
}

class _EventApplicationsScreenState extends State<EventApplicationsScreen> {
  
  bool get _isEventLocked => 
      widget.eventStatus == 'completed' || 
      widget.eventStatus == 'archived' || 
      widget.eventStatus == 'expired';

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  void _loadApplications() {
    context.read<ApplicationsBloc>().add(LoadEventApplications(widget.eventId));
  }

  Widget _buildStatusLabel(String status) {
    switch (status) {
      case 'approved':
        return const Text('Одобрено', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold));
      case 'rejected':
        return const Text('Отклонено', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold));
      case 'pending':
        return const Text('Ожидает решения', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold));
      case 'completed':
        return const Text('Завершенно', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold));
      case 'expired':
        return const Text('Истекло', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold));
      default:
        return Text(status, style: const TextStyle(fontWeight: FontWeight.bold));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Заявки волонтеров'),
      ),
      body: Column(
        children: [
          if (_isEventLocked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.amber.shade100,
              child: Row(
                children: [
                  Icon(Icons.lock_outline, color: Colors.amber.shade900, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Мероприятие завершено или переведено в архив. Изменение статусов заявок заблокировано.',
                      style: TextStyle(
                        color: Colors.amber.shade900, 
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _loadApplications();
              },
              child: BlocBuilder<ApplicationsBloc, ApplicationsState>(
                builder: (context, state) {
                  if (state is ApplicationsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is ApplicationsError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(state.message, style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadApplications,
                            child: const Text('Повторить'),
                          ),
                        ],
                      ),
                    );
                  } else if (state is ApplicationsLoaded) {
                    if (state.applications.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                          const Center(
                            child: Text(
                              'На это мероприятие пока нет заявок.',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      itemCount: state.applications.length,
                      itemBuilder: (context, index) {
                        final app = state.applications[index];
                        final volunteer = app['volunteer'] ?? app['user'];
                        final status = app['status'];
                        final applicationId = app['ID_application'];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: () {
                                          context.push('/volunteer-profile/${volunteer['ID_user']}');
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                                child: const Icon(Icons.person),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      volunteer['full_name'] ?? 'Имя не указано',
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                    ),
                                                    Text(
                                                      volunteer['email'] ?? '',
                                                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildStatusLabel(status),
                                    
                                    if (!_isEventLocked)
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                                        tooltip: 'Изменить статус заявки',
                                        onSelected: (newStatus) {
                                          context.read<ApplicationsBloc>().add(
                                            ChangeApplicationStatus(widget.eventId, applicationId, newStatus),
                                          );
                                        },
                                        itemBuilder: (context) => [
                                          if (status != 'pending')
                                            const PopupMenuItem(
                                              value: 'pending',
                                              child: Text('Вернуть в ожидание'),
                                            ),
                                          if (status != 'approved')
                                            const PopupMenuItem(
                                              value: 'approved',
                                              child: Text('Одобрить'),
                                            ),
                                          if (status != 'rejected')
                                            const PopupMenuItem(
                                              value: 'rejected',
                                              child: Text('Отклонить'),
                                            ),
                                        ],
                                      ),
                                  ],
                                ),
                                
                                if (status == 'pending' && !_isEventLocked) ...[
                                  const Divider(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          context.read<ApplicationsBloc>().add(
                                            ChangeApplicationStatus(widget.eventId, applicationId, 'rejected')
                                          );
                                        },
                                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                                        child: const Text('Отклонить'),
                                      ),
                                      const SizedBox(width: 8),
                                      FilledButton(
                                        onPressed: () {
                                          context.read<ApplicationsBloc>().add(
                                            ChangeApplicationStatus(widget.eventId, applicationId, 'approved')
                                          );
                                        },
                                        style: FilledButton.styleFrom(backgroundColor: Colors.green),
                                        child: const Text('Одобрить'),
                                      ),
                                    ],
                                  )
                                ]
                              ],
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
    );
  }
}