import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get_storage/get_storage.dart';

final ValueNotifier<bool> darkModeNotifier = ValueNotifier<bool>(false);

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _smsPermissionGranted = false;
  bool _galleryPermissionGranted = false;
  bool _isDarkMode = false;
  final _storage = GetStorage();

  @override
  void initState() {
    super.initState();
    _loadDarkModePreference();
    _checkPermissions();
    darkModeNotifier.value = _isDarkMode; // Sync initial state
  }

  void _loadDarkModePreference() {
    setState(() {
      _isDarkMode = _storage.read('isDarkMode') ?? false;
    });
  }

  void _toggleDarkMode(bool value) {
    setState(() {
      _isDarkMode = value;
    });
    _storage.write('isDarkMode', value);
    darkModeNotifier.value = value; // Notify the app
  }

  Future<void> _checkPermissions() async {
    final smsStatus = await Permission.sms.status;
    final galleryStatus = await Permission.photos.status;

    if (mounted) {
      setState(() {
        _smsPermissionGranted = smsStatus.isGranted;
        _galleryPermissionGranted = galleryStatus.isGranted;
      });
    }
    print('Initial SMS Status: $smsStatus');
    print('Initial Gallery Status: $galleryStatus');
  }

  Future<void> _requestSmsPermission() async {
    final status = await Permission.sms.request();
    print('SMS Permission Status: $status');
    if (status.isGranted) {
      setState(() {
        _smsPermissionGranted = true;
      });
    } else if (status.isPermanentlyDenied) {
      _showRevokePermissionDialog('SMS');
    } else {
      _showSnackBar('SMS permission denied');
    }
    await _checkPermissions();
  }

  Future<void> _requestGalleryPermission() async {
    var status = await Permission.photos.request();
    print('Photos Permission Status: $status');

    if (!status.isGranted && await Permission.storage.request().isGranted) {
      status = await Permission.storage.status;
      print('Storage Permission Status: $status');
    }

    if (status.isGranted) {
      setState(() {
        _galleryPermissionGranted = true;
      });
    } else if (status.isPermanentlyDenied) {
      _showRevokePermissionDialog('Gallery');
    } else {
      _showSnackBar('Gallery permission denied');
    }
    await _checkPermissions();
  }

  void _handleSmsToggle(bool value) {
    if (value) {
      _requestSmsPermission();
    } else {
      setState(() {
        _smsPermissionGranted = false;
      });
      _showRevokePermissionDialog('SMS');
    }
  }

  void _handleGalleryToggle(bool value) {
    if (value) {
      _requestGalleryPermission();
    } else {
      setState(() {
        _galleryPermissionGranted = false;
      });
      _showRevokePermissionDialog('Gallery');
    }
  }

  void _showRevokePermissionDialog(String permissionType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Revoke $permissionType Permission'),
        content: Text(
          'To revoke $permissionType permission, please go to your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Permissions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: const Text('SMS Permission'),
                    value: _smsPermissionGranted,
                    activeColor: Colors.teal.shade700,
                    onChanged: _handleSmsToggle,
                  ),
                  SwitchListTile(
                    title: const Text('Gallery Permission'),
                    value: _galleryPermissionGranted,
                    activeColor: Colors.teal.shade700,
                    onChanged: _handleGalleryToggle,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Dark Mode'),
              value: _isDarkMode,
              activeColor: Colors.teal.shade700,
              onChanged: _toggleDarkMode,
            ),
          ],
        ),
      ),
    );
  }
}