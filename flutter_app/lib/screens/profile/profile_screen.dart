import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isEditing = false;
  bool _isLoading = false;
  XFile? _pickedImage;

  Future<void> _pickAndUploadPhoto() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId;
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not identified')));
      return;
    }

    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (xfile == null) {
        return;
      }

      setState(() {
        _pickedImage = xfile;
        _isLoading = true;
      });

      final file = await MultipartFile.fromFile(
        xfile.path,
        filename: xfile.name,
      );
      final formData = FormData();
      formData.files.add(MapEntry('avatar', file));

      final response = await ApiService.put('/users/$userId', data: formData);

      // Try to extract updated user object from response
      Map<String, dynamic>? newUser;
      if (response['user'] != null) {
        newUser = Map<String, dynamic>.from(response['user']);
      } else if (response['data'] is Map && response['data']['user'] != null) {
        newUser = Map<String, dynamic>.from(response['data']['user']);
      } else if (response['avatar'] != null) {
        newUser = Map<String, dynamic>.from(authProvider.userData ?? {});
        newUser['avatar'] = response['avatar'];
      }

      if (newUser != null) {
        await authProvider.updateUser(newUser);
      } else {
        final local = Map<String, dynamic>.from(authProvider.userData ?? {});
        local['avatar'] = _pickedImage!.path; // local preview
        await authProvider.updateUser(local);
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile photo updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to upload photo: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              if (!_isEditing)
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                  icon: const Icon(Icons.edit),
                ),
              if (_isEditing) ...[
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                    });
                  },
                  icon: const Icon(Icons.close),
                ),
                IconButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  icon: const Icon(Icons.save),
                ),
              ],
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: FormBuilder(
              key: _formKey,
              enabled: _isEditing,
              child: Column(
                children: [
                  // Profile Avatar
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          child: _pickedImage != null
                              ? ClipOval(
                                  child: Image.file(
                                    File(_pickedImage!.path),
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : (authProvider.userData?['avatar'] != null
                                    ? ClipOval(
                                        child: Image.network(
                                          authProvider.userData!['avatar'],
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Center(
                                                    child: Text(
                                                      authProvider
                                                              .userName
                                                              .isNotEmpty
                                                          ? authProvider
                                                                .userName[0]
                                                                .toUpperCase()
                                                          : 'U',
                                                      style: const TextStyle(
                                                        fontSize: 36,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                        ),
                                      )
                                    : Text(
                                        authProvider.userName.isNotEmpty
                                            ? authProvider.userName[0]
                                                  .toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      )),
                        ),
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: _isLoading
                                    ? null
                                    : _pickAndUploadPhoto,
                                icon: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Profile Information
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Personal Information',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          FormBuilderTextField(
                            name: 'name',
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Icon(Icons.person),
                            ),
                            initialValue: authProvider.userName,
                            validator: FormBuilderValidators.required(),
                          ),
                          const SizedBox(height: 16),
                          FormBuilderTextField(
                            name: 'email',
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email),
                            ),
                            initialValue: authProvider.userEmail,
                            enabled:
                                false, // Email usually shouldn't be editable
                          ),
                          const SizedBox(height: 16),
                          FormBuilderTextField(
                            name: 'phone_number',
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              prefixIcon: Icon(Icons.phone),
                            ),
                            initialValue:
                                authProvider.userData?['phone_number'] ?? '',
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(),
                              FormBuilderValidators.match(
                                RegExp(r'^\+?[\d\s\-\(\)]+$'),
                                errorText: 'Please enter a valid phone number',
                              ),
                            ]),
                          ),
                          const SizedBox(height: 16),
                          FormBuilderDateTimePicker(
                            name: 'birth_date',
                            decoration: const InputDecoration(
                              labelText: 'Birth Date',
                              prefixIcon: Icon(Icons.cake),
                            ),
                            initialValue:
                                authProvider.userData?['birth_date'] != null
                                ? DateTime.tryParse(
                                    authProvider.userData!['birth_date'],
                                  )
                                : null,
                            inputType: InputType.date,
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          ),
                          const SizedBox(height: 16),
                          FormBuilderDropdown<String>(
                            name: 'gender',
                            decoration: const InputDecoration(
                              labelText: 'Gender',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            initialValue:
                                authProvider.userGender ??
                                authProvider.userData?['gender'],
                            items: const [
                              DropdownMenuItem(
                                value: 'male',
                                child: Text('Male'),
                              ),
                              DropdownMenuItem(
                                value: 'female',
                                child: Text('Female'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Church Information
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Church Information',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoTile(
                            context,
                            'Role',
                            authProvider.getRoleDisplayName(),
                            Icons.badge,
                          ),
                          if (authProvider.userData?['branch'] != null)
                            _buildInfoTile(
                              context,
                              'Branch',
                              authProvider.userData!['branch']['name'] ??
                                  'No Branch',
                              Icons.account_tree,
                            ),
                          if (authProvider.userData?['mc'] != null)
                            _buildInfoTile(
                              context,
                              'Missional Community',
                              authProvider.userData!['mc']['name'] ?? 'No MC',
                              Icons.groups,
                            ),
                          _buildInfoTile(
                            context,
                            'Member Since',
                            authProvider.userData?['created_at'] != null
                                ? _formatDate(
                                    DateTime.parse(
                                      authProvider.userData!['created_at'],
                                    ),
                                  )
                                : 'Unknown',
                            Icons.calendar_today,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Account Actions
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Account Actions',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            leading: const Icon(Icons.lock),
                            title: const Text('Change Password'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _showChangePasswordDialog,
                          ),
                          ListTile(
                            leading: Icon(
                              Icons.logout,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            title: Text(
                              'Logout',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _showLogoutDialog(authProvider),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoTile(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final formValues = _formKey.currentState!.value;
        final authProvider = context.read<AuthProvider>();

        final updateData = {
          'name': formValues['name'],
          'email': formValues['email'],
          'phone_number': formValues['phone'],
          'birth_date': formValues['birthDate']?.toIso8601String().split(
            'T',
          )[0],
          'gender': formValues['gender'],
        };

        await ApiService.put('/users/${authProvider.userId}', data: updateData);

        // Update the local user data
        await authProvider.updateUser(updateData);

        setState(() {
          _isEditing = false;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update profile: $e')),
          );
        }
      }
    }
  }

  void _showChangePasswordDialog() {
    showDialog(context: context, builder: (context) => _PasswordChangeDialog());
  }

  void _showLogoutDialog(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final goRouter = GoRouter.of(context);
              navigator.pop();
              await authProvider.logout();
              if (mounted) {
                goRouter.goNamed('login');
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _PasswordChangeDialog extends StatefulWidget {
  @override
  State<_PasswordChangeDialog> createState() => _PasswordChangeDialogState();
}

class _PasswordChangeDialogState extends State<_PasswordChangeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();

      await ApiService.put(
        '/users/${authProvider.userId}/password',
        data: {
          'current_password': _currentPasswordController.text,
          'new_password': _newPasswordController.text,
          'new_password_confirmation': _confirmPasswordController.text,
        },
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error changing password: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxHeight = MediaQuery.of(context).size.height * 0.85;
          return Container(
            constraints: BoxConstraints(maxWidth: 400, maxHeight: maxHeight),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lock,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      // Ensure the title can wrap or shrink instead of causing overflow
                      Expanded(
                        child: Text(
                          'Change Password',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Current Password Field
                        TextFormField(
                          controller: _currentPasswordController,
                          obscureText: _obscureCurrentPassword,
                          decoration: InputDecoration(
                            labelText: 'Current Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureCurrentPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () => setState(
                                () => _obscureCurrentPassword =
                                    !_obscureCurrentPassword,
                              ),
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your current password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // New Password Field
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: _obscureNewPassword,
                          decoration: InputDecoration(
                            labelText: 'New Password',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureNewPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () => setState(
                                () =>
                                    _obscureNewPassword = !_obscureNewPassword,
                              ),
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a new password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            if (value == _currentPasswordController.text) {
                              return 'New password must be different from current password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Confirm Password Field
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: 'Confirm New Password',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () => setState(
                                () => _obscureConfirmPassword =
                                    !_obscureConfirmPassword,
                              ),
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your new password';
                            }
                            if (value != _newPasswordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _isLoading ? null : _changePassword,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Change Password'),
                        ),
                      ),
                    ],
                  ),
                ],
              ), // end Column (dialog content)
            ), // end SingleChildScrollView
          ); // end returned Container from builder
        }, // end builder
      ), // end LayoutBuilder
    ); // end Dialog
  }
}
