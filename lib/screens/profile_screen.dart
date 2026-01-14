import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'dart:io';
import '../providers/theme_provider.dart';
import '../utils/theme_utils.dart';
import '../services/user_profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  String? _profilePicturePath;
  bool _isLoading = false;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final profile = await UserProfileService.instance.getProfile(user.id);
      if (profile != null) {
        setState(() {
          _profile = profile;
          _nameController.text = profile['display_name'] ?? '';
          _profilePicturePath = profile['profile_picture_path'];
        });
      } else {
        // Create default profile
        _nameController.text = user.email?.split('@')[0] ?? 'User';
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      await UserProfileService.instance.saveProfile(
        userId: user.id,
        displayName: _nameController.text.trim(),
        profilePicturePath: _profilePicturePath,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profile saved locally'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _profilePicturePath = image.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: FuturisticTheme.getBackgroundColor(isDark),
      appBar: AppBar(
        title: Text(
          'Profile',
          style: FuturisticTheme.getTitleStyle(isDark),
        ),
        backgroundColor: FuturisticTheme.getSurfaceColor(isDark),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: FuturisticTheme.getBackgroundGradient(isDark),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: FuturisticTheme.neonCyan,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Profile Picture
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: FuturisticTheme.neonCyan,
                            width: 3,
                          ),
                        ),
                        child: ClipOval(
                          child: _profilePicturePath != null
                              ? Image.file(
                                  File(_profilePicturePath!),
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color:
                                      FuturisticTheme.neonCyan.withOpacity(0.1),
                                  child: Icon(
                                    Icons.person,
                                    size: 60,
                                    color: FuturisticTheme.neonCyan,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Change Picture'),
                      style: TextButton.styleFrom(
                        foregroundColor: FuturisticTheme.neonCyan,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Display Name
                    _buildGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Display Name',
                            style:
                                FuturisticTheme.getBodyStyle(isDark).copyWith(
                              fontSize: 12,
                              color: FuturisticTheme.textGray,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nameController,
                            style: FuturisticTheme.getBodyStyle(isDark),
                            decoration: InputDecoration(
                              hintText: 'Enter your name',
                              hintStyle: TextStyle(
                                color: FuturisticTheme.textGray,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Email (Read-only)
                    _buildGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email',
                            style:
                                FuturisticTheme.getBodyStyle(isDark).copyWith(
                              fontSize: 12,
                              color: FuturisticTheme.textGray,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user?.email ?? 'Not logged in',
                            style: FuturisticTheme.getBodyStyle(isDark),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Privacy Notice
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: FuturisticTheme.neonCyan.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: FuturisticTheme.neonCyan.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock,
                            color: FuturisticTheme.neonCyan,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your profile data is stored locally on your device for privacy.',
                              style:
                                  FuturisticTheme.getBodyStyle(isDark).copyWith(
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Save Button
                    ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FuturisticTheme.neonCyan,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'SAVE PROFILE',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: FuturisticTheme.getGlassDecoration(
        Provider.of<ThemeProvider>(context).isDarkMode,
      ),
      child: child,
    );
  }
}
