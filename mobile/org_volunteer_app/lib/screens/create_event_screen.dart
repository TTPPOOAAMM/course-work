import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/event/event_bloc.dart';

class CreateEventScreen extends StatefulWidget {
  final Map<String, dynamic>? eventToEdit;

  const CreateEventScreen({super.key, this.eventToEdit});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _participantsController = TextEditingController();
  
  DateTime? _selectedDate;
  int? _selectedLocationId;

  bool get _isEditMode => widget.eventToEdit != null;

  @override
  void initState() {
    super.initState();
    context.read<EventBloc>().add(LoadLocations());

    if (_isEditMode) {
      final event = widget.eventToEdit!;
      _titleController.text = event['title'] ?? '';
      _descController.text = event['description'] ?? '';
      _participantsController.text = (event['max_participants'] ?? '').toString();
      _selectedLocationId = event['location_id'];
      if (event['event_date'] != null) {
        _selectedDate = DateTime.parse(event['event_date']);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _participantsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: _isEditMode ? DateTime.now().subtract(const Duration(days: 365)) : DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? 'Редактирование мероприятия' : 'Новое мероприятие')),
      body: BlocConsumer<EventBloc, EventState>(
        listener: (context, state) {
          if (state is EventCreateSuccess || state is EventUpdateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_isEditMode ? 'Изменения успешно сохранены!' : 'Мероприятие успешно создано!'), 
                backgroundColor: Colors.green
              ),
            );
            context.pop(); 
          } else if (state is EventError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Theme.of(context).colorScheme.error),
            );
          }
        },
        builder: (context, state) {
          if (state is EventLoading || state is EventInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          List<dynamic> locations = [];
          if (state is LocationsLoaded) {
            locations = state.locations;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Название', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Введите название' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(labelText: 'Описание', border: OutlineInputBorder()),
                    maxLines: 3,
                    validator: (v) => v!.isEmpty ? 'Введите описание' : null,
                  ),
                  const SizedBox(height: 16),

                  ListTile(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    title: Text(_selectedDate == null 
                        ? 'Выберите дату проведения' 
                        : 'Дата: ${_selectedDate!.toLocal().toString().split(' ')[0]}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Район', border: OutlineInputBorder()),
                    value: _selectedLocationId,
                    items: locations.map((loc) {
                      return DropdownMenuItem<int>(
                        value: loc['ID_Locations'],
                        child: Text(loc['district_name']),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedLocationId = val),
                    validator: (v) => v == null ? 'Выберите район' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _participantsController,
                    decoration: const InputDecoration(labelText: 'Количество мест', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Укажите лимит волонтеров' : null,
                  ),
                  const SizedBox(height: 32),

                  FilledButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate() && _selectedDate != null) {
                        final title = _titleController.text;
                        final description = _descController.text;
                        final eventDate = _selectedDate!.toIso8601String();
                        final locationId = _selectedLocationId!;
                        final maxParticipants = int.parse(_participantsController.text);

                        if (_isEditMode) {
                          context.read<EventBloc>().add(
                            UpdateEvent(
                              eventId: widget.eventToEdit!['ID_event'],
                              title: title,
                              description: description,
                              eventDate: eventDate,
                              locationId: locationId,
                              maxParticipants: maxParticipants,
                            ),
                          );
                        } else {
                          context.read<EventBloc>().add(
                            CreateNewEvent(
                              title: title,
                              description: description,
                              eventDate: eventDate,
                              locationId: locationId,
                              maxParticipants: maxParticipants,
                            ),
                          );
                        }
                      } else if (_selectedDate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Пожалуйста, выберите дату')),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(_isEditMode ? 'Сохранить изменения' : 'Создать', style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}