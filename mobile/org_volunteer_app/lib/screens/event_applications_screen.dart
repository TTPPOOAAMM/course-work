import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/applications/applications_bloc.dart';

class EventApplicationsScreen extends StatefulWidget {
  final int eventId;

  const EventApplicationsScreen({super.key, required this.eventId});

  @override
  State<EventApplicationsScreen> createState() => _EventApplicationsScreenState();
}

class _EventApplicationsScreenState extends State<EventApplicationsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ApplicationsBloc>().add(LoadEventApplications(widget.eventId));
  }

  Widget _buildStatusLabel(String status) {
    if (status == 'approved') {
      return const Text('Одобрено', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold));
    } else if (status == 'rejected') {
      return const Text('Отклонено', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold));
    }
    return const Text('Ожидает решения', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Заявки волонтеров'),
      ),
      body: BlocBuilder<ApplicationsBloc, ApplicationsState>(
        builder: (context, state) {
          if (state is ApplicationsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ApplicationsError) {
            return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
          } else if (state is ApplicationsLoaded) {
            if (state.applications.isEmpty) {
              return const Center(
                child: Text(
                  'На это мероприятие пока нет заявок.',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: state.applications.length,
              itemBuilder: (context, index) {
                final app = state.applications[index];
                final volunteer = app['volunteer'] ?? app['user']; // Страховка на случай разного названия поля
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
                                  ),
                                ],
                              ),
                            ),
                            _buildStatusLabel(status),
                          ],
                        ),
                        
                        if (status == 'pending') ...[
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
    );
  }
}