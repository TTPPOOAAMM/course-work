import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/event/event_bloc.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    context.read<EventBloc>().add(LoadLocations());
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
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
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
      appBar: AppBar(title: const Text('Новое мероприятие')),
      body: BlocConsumer<EventBloc, EventState>(
        listener: (context, state) {
          if (state is EventCreateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Мероприятие успешно создано!'), backgroundColor: Colors.green),
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
                        context.read<EventBloc>().add(
                          CreateNewEvent(
                            title: _titleController.text,
                            description: _descController.text,
                            eventDate: _selectedDate!.toIso8601String().split('T')[0],
                            locationId: _selectedLocationId!,
                            maxParticipants: int.parse(_participantsController.text),
                          ),
                        );
                      } else if (_selectedDate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Пожалуйста, выберите дату')),
                        );
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text('Создать', style: TextStyle(fontSize: 16)),
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