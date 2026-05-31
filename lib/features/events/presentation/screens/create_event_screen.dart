import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_theme.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();

  String _selectedCategory = 'Music';
  DateTime _selectedDate =
      DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  bool _isOnline = false;
  bool _isLoading = false;

  String? _pickedImageDataUrl;
  int _imageTab = 0;

  final List<String> _categories = [
    'Music', 'Tech', 'Sports', 'Art', 'Food', 'Business', 'Education'
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.lime,
            onPrimary: AppColors.primary,
            surface: AppColors.darkSurface,
            onSurface: AppColors.darkText,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.lime,
            onPrimary: AppColors.primary,
            surface: AppColors.darkSurface,
            onSurface: AppColors.darkText,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.bytes == null) return;
      final base64Str = base64Encode(file.bytes!);
      final ext = (file.extension ?? 'jpg').toLowerCase();
      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
      setState(() {
        _pickedImageDataUrl = 'data:$mime;base64,$base64Str';
        _imageUrlCtrl.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Could not pick image: $e'),
            behavior: SnackBarBehavior.floating));
      }
    }
  }

  String _resolveImage(int seed) {
    if (_imageTab == 1 && _pickedImageDataUrl != null) {
      return _pickedImageDataUrl!;
    }
    final url = _imageUrlCtrl.text.trim();
    if (url.isNotEmpty) return url;
    return 'https://picsum.photos/seed/$seed/800/400';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not signed in');

      final eventDate = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day,
        _selectedTime.hour, _selectedTime.minute,
      );
      final now = Timestamp.now();
      final imageStr = _resolveImage(now.millisecondsSinceEpoch);

      await FirebaseFirestore.instance.collection('events').add({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'category': _selectedCategory,
        'image': imageStr,
        'location':
            _isOnline ? 'Online' : _locationCtrl.text.trim(),
        'isOnline': _isOnline,
        'date': eventDate.toIso8601String(),
        'time': _selectedTime.format(context),
        'attendees': 0,
        'interested': 0,
        'isPublic': true,
        'hostId': user.uid,
        'hostName':
            user.displayName ?? user.email ?? 'Anonymous',
        'hostAvatar': user.photoURL ?? '',
        'tags': <String>[],
        'createdAt': now,
      }).timeout(
        const Duration(seconds: 15),
        onTimeout: () =>
            throw Exception('Request timed out. Check your connection.'),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Event created! 🎉'),
        backgroundColor: AppColors.lime,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Failed: ${e.toString().replaceAll('Exception: ', '')}'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 5),
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
    final timeStr = _selectedTime.format(context);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded,
              color: AppColors.darkText),
          onPressed:
              _isLoading ? null : () => Navigator.of(context).pop(),
        ),
        title: const Text('Create Event',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.darkText)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _isLoading
                ? const Center(
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.lime)))
                : GestureDetector(
                    onTap: _submit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.lime,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Post',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [

            _label('Event Title'),
            _field(
              controller: _titleCtrl,
              hint: 'e.g. Flutter Workshop Lahore',
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Title is required'
                  : null,
            ),
            const SizedBox(height: 20),

            _label('Description'),
            _field(
              controller: _descCtrl,
              hint: "What's this event about?",
              maxLines: 4,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Description is required'
                  : null,
            ),
            const SizedBox(height: 20),

            _label('Category'),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  final sel = cat == _selectedCategory;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.lime
                            : AppColors.darkSurface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(cat,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: sel
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                              color: sel
                                  ? AppColors.primary
                                  : AppColors.darkTextSecondary)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            _label('Date & Time'),
            Row(children: [
              Expanded(
                  child: _tapTile(
                      icon: Icons.calendar_today_rounded,
                      label: dateStr,
                      onTap: _pickDate)),
              const SizedBox(width: 12),
              Expanded(
                  child: _tapTile(
                      icon: Icons.access_time_rounded,
                      label: timeStr,
                      onTap: _pickTime)),
            ]),
            const SizedBox(height: 20),

            // Online toggle
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                const Icon(Icons.videocam_rounded,
                    color: AppColors.lime, size: 22),
                const SizedBox(width: 12),
                const Expanded(
                    child: Text('Online Event',
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                            color: AppColors.darkText))),
                Switch.adaptive(
                  value: _isOnline,
                  activeTrackColor: AppColors.lime,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _isOnline = v),
                ),
              ]),
            ),
            const SizedBox(height: 20),

            if (!_isOnline) ...[
              _label('Location'),
              _field(
                controller: _locationCtrl,
                hint: 'e.g. Lahore, Pakistan',
                prefixIcon: Icons.location_on_rounded,
                validator: (v) => !_isOnline &&
                        (v == null || v.trim().isEmpty)
                    ? 'Location is required'
                    : null,
              ),
              const SizedBox(height: 20),
            ],

            _label('Cover Image'),
            _buildImagePicker(),
            const SizedBox(height: 32),

            // Submit button
            GestureDetector(
              onTap: _isLoading ? null : _submit,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 56,
                decoration: BoxDecoration(
                  color: _isLoading
                      ? AppColors.lime.withValues(alpha: 0.5)
                      : AppColors.lime,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: _isLoading
                      ? []
                      : [
                          BoxShadow(
                            color:
                                AppColors.lime.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.primary))
                      : const Text('Create Event 🚀',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.darkTextSecondary)),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    IconData? prefixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: AppColors.darkText, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            color: AppColors.darkTextSecondary, fontSize: 14),
        filled: true,
        fillColor: AppColors.darkSurface,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon,
                color: AppColors.darkTextSecondary, size: 20)
            : null,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.lime, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.error)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.error, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _tapTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Icon(icon, color: AppColors.lime, size: 18),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.darkText)),
        ]),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(children: [
                _imageTabBtn(0, Icons.link_rounded, 'URL'),
                const SizedBox(width: 8),
                _imageTabBtn(
                    1, Icons.photo_library_rounded, 'Gallery'),
              ]),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: _imageTab == 0
                  ? _buildUrlTab()
                  : _buildGalleryTab(),
            ),
          ]),
    );
  }

  Widget _imageTabBtn(int index, IconData icon, String label) {
    final selected = _imageTab == index;
    return GestureDetector(
      onTap: () => setState(() => _imageTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.lime : AppColors.darkBackground,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              size: 16,
              color: selected
                  ? AppColors.primary
                  : AppColors.darkTextSecondary),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? AppColors.primary
                      : AppColors.darkTextSecondary)),
        ]),
      ),
    );
  }

  Widget _buildUrlTab() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
      TextFormField(
        controller: _imageUrlCtrl,
        keyboardType: TextInputType.url,
        style: const TextStyle(
            color: AppColors.darkText, fontSize: 14),
        onChanged: (_) {
          if (_pickedImageDataUrl != null) {
            setState(() => _pickedImageDataUrl = null);
          }
        },
        decoration: InputDecoration(
          hintText: 'https://example.com/image.jpg',
          hintStyle: const TextStyle(
              color: AppColors.darkTextSecondary, fontSize: 14),
          filled: true,
          fillColor: AppColors.darkBackground,
          prefixIcon: const Icon(Icons.image_rounded,
              color: AppColors.darkTextSecondary, size: 20),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: AppColors.lime, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
        ),
      ),
      if (_imageUrlCtrl.text.trim().isNotEmpty) ...[
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            _imageUrlCtrl.text.trim(),
            height: 140,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 60,
              color: AppColors.darkBackground,
              child: const Center(
                  child: Text('Invalid image URL',
                      style: TextStyle(
                          color: AppColors.darkTextSecondary,
                          fontSize: 13))),
            ),
          ),
        ),
      ],
      const SizedBox(height: 6),
      const Text('Leave empty to use a random placeholder',
          style: TextStyle(
              fontSize: 11, color: AppColors.darkTextSecondary)),
    ]);
  }

  Widget _buildGalleryTab() {
    return Column(children: [
      if (_pickedImageDataUrl != null) ...[
        Stack(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Builder(builder: (_) {
              try {
                final bytes =
                    base64Decode(_pickedImageDataUrl!.split(',').last);
                return Image.memory(bytes,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover);
              } catch (_) {
                return const SizedBox(
                    height: 160,
                    child: Center(
                        child: Text('Preview unavailable',
                            style: TextStyle(
                                color: AppColors.darkTextSecondary))));
              }
            }),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () =>
                  setState(() => _pickedImageDataUrl = null),
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle),
                child: const Icon(Icons.close,
                    color: Colors.white, size: 18),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _pickImageFromGallery,
          icon: const Icon(Icons.photo_library_rounded,
              size: 18, color: AppColors.lime),
          label: const Text('Change photo',
              style: TextStyle(color: AppColors.lime)),
        ),
      ] else ...[
        GestureDetector(
          onTap: _pickImageFromGallery,
          child: Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.lime.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.lime.withValues(alpha: 0.3)),
            ),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                        color: AppColors.lime.withValues(alpha: 0.15),
                        shape: BoxShape.circle),
                    child: const Icon(
                        Icons.add_photo_alternate_rounded,
                        color: AppColors.lime,
                        size: 26),
                  ),
                  const SizedBox(height: 10),
                  const Text('Tap to choose from gallery',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.lime)),
                  const SizedBox(height: 4),
                  const Text('JPG, PNG supported',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.darkTextSecondary)),
                ]),
          ),
        ),
      ],
    ]);
  }
}
