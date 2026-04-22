import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app/providers/theme_notifier.dart';
import 'package:frontend/features/settings/presentation/widgets/info_card.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeNotifierProvider);
    final isDark = themeMode == ThemeMode.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.grey[100] : Colors.grey[900],
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            children: [
                              const CircleAvatar(
                                radius: 50,
                                backgroundImage: NetworkImage(
                                  'https://picsum.photos/200',
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 5,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color:
                                        isDark
                                            ? Colors.grey[800]
                                            : Colors.blue[700],
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Abenezer Walelign',
                            style: TextStyle(
                              color: isDark ? Colors.grey[100] : Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Software Developer',
                            style: TextStyle(
                              color: isDark ? Colors.grey[300] : Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          buildInfoCard(
                            icon: Icons.person,
                            title: 'First Name',
                            subtitle: 'Abenezer',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 15),
                          buildInfoCard(
                            icon: Icons.person,
                            title: 'Last Name',
                            subtitle: 'Walelign',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 15),
                          buildInfoCard(
                            icon: Icons.email,
                            title: 'Email',
                            subtitle: 'john.doe@example.com',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 15),
                          buildInfoCard(
                            icon: Icons.phone,
                            title: 'Phone',
                            subtitle: '+251 911091111',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? Colors.grey[800] : Colors.blue[700],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 22,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Edit Profile',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey[100] : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
