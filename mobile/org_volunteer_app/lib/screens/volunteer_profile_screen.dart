import 'package:flutter/material.dart';
import '../data/api_client.dart';

class VolunteerProfileScreen extends StatelessWidget {
  final int userId;
  final ApiClient _apiClient = ApiClient();

  VolunteerProfileScreen({super.key, required this.userId});

  Future<Map<String, dynamic>> _fetchVolunteerProfile() async {
    final response = await _apiClient.dio.get('/api/users/$userId/profile');
    return response.data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль волонтера'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchVolunteerProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Не удалось загрузить профиль.\nУбедитесь, что на бэкенде реализован эндпоинт\nGET /api/users/{user_id}/profile',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red, fontSize: 15),
                ),
              ),
            );
          }

          final userData = snapshot.data!;
          final profile = userData['profile'] ?? {};
          final List<dynamic> skills = profile['skills'] ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          child: Icon(Icons.person, size: 40, color: Theme.of(context).colorScheme.primary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userData['full_name'] ?? 'Имя не указано',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                userData['email'] ?? '',
                                style: const TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                const Text('Личные данные', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.phone_android),
                        title: const Text('Номер телефона'),
                        subtitle: Text(profile['phone'] ?? 'Не указан'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.cake_outlined),
                        title: const Text('Дата рождения'),
                        subtitle: Text(profile['birth_date'] ?? 'Не указана'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text('Интересы и увлечения', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        profile['interests'] ?? 'Волонтер еще не заполнил информацию о своих интересах.',
                        style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.black87),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                const Text('Ключевые навыки', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (skills.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text('Навыки не добавлены', style: TextStyle(color: Colors.grey, fontSize: 15)),
                  )
                else
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: skills.map((skill) {
                      return Chip(
                        label: Text(skill['skill_name'] ?? ''),
                        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                        side: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)),
                        labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w500),
                      );
                    }).toList(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}