
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../plugins/adapters/quantum_github_adapter.dart';
import '../plugins/adapters/quantum_imagekit_adapter.dart';

import '../plugins/quantum_api_engine.dart';

class BasicLocalStore implements LocalStore {
  final Map<String, String> _memory = {};
  @override
  Future<String?> read(String key) async => _memory[key];
  @override
  Future<void> write(String key, String value) async => _memory[key] = value;
  @override
  Future<void> delete(String key) async => _memory.remove(key);
  @override
  Future<void> clear({String? prefix}) async {
    if (prefix == null) {
      _memory.clear();
    } else {
      _memory.removeWhere((k, v) => k.startsWith(prefix));
    }
  }
  @override
  Future<void> init() async {}
  @override
  Future<List<String>> keys({String? prefix}) async {
    if (prefix == null) return _memory.keys.toList();
    return _memory.keys.where((k) => k.startsWith(prefix)).toList();
  }
  @override
  Future<int> size() async => _memory.length;
}

class MediaShowcaseScreen extends StatefulWidget {
  const MediaShowcaseScreen({Key? key}) : super(key: key);

  @override
  State<MediaShowcaseScreen> createState() => _MediaShowcaseScreenState();
}

class _MediaShowcaseScreenState extends State<MediaShowcaseScreen> {
  bool _isGithub = true;

  // GitHub Controllers
  final _ghOwner = TextEditingController(text: '3reeb');
  final _ghRepo = TextEditingController(text: 'flutter_app');
  final _ghBranch = TextEditingController(text: 'main');
  final _ghToken = TextEditingController();

  // ImageKit Controllers
  final _ikEndpoint = TextEditingController();
  final _ikPublicKey = TextEditingController();
  final _ikPrivateKey = TextEditingController();

  String _statusMessage = 'Ready.';
  List<MediaFileInfo> _files = [];
  bool _isLoading = false;

  QuantumMediaAdapter _getAdapter() {
    final config = MediaBackendConfig(
      githubOwner: _ghOwner.text.trim(),
      githubRepo: _ghRepo.text.trim(),
      githubBranch: _ghBranch.text.trim(),
      githubToken: _ghToken.text.trim(),
      imagekitUrlEndpoint: _ikEndpoint.text.trim(),
      imagekitPublicKey: _ikPublicKey.text.trim(),
      imagekitPrivateKey: _ikPrivateKey.text.trim(),
    );

    if (_isGithub) {
      final adapter = GithubMediaAdapter(store: BasicLocalStore());
      adapter.configure(config);
      return adapter;
    } else {
      final adapter = ImageKitMediaAdapter(store: BasicLocalStore());
      adapter.configure(config);
      return adapter;
    }
  }

  void _toast(String msg) {
    setState(() {
      _statusMessage = msg;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _listFiles() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Listing files...';
    });
    try {
      final adapter = _getAdapter();
      final path = _isGithub ? '/' : '/'; // root
      final files = await adapter.listFiles(path: path, limit: 100);
      setState(() {
        _files = files;
        _isLoading = false;
        _statusMessage = 'Found ${files.length} files.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  Future<void> _uploadDummyFile() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Creating dummy file...';
    });
    try {
      final adapter = _getAdapter();

      // Create dummy file
      final tempDir = await getTemporaryDirectory();
      final file =
          File('${tempDir.path}/dummy_upload_${Random().nextInt(9999)}.txt');
      await file
          .writeAsString('Hello Quantum Media! Upload time: ${DateTime.now()}');

      final remotePath = 'test_uploads/dummy_${Random().nextInt(9999)}.txt';

      final session = await adapter.createUploadSession(
          localFilePath: file.path,
          remotePath: remotePath,
          mimeType: 'text/plain');

      session.progress.listen((p) {
        setState(() {
          _statusMessage =
              'Uploading: ${(p.progress * 100).toStringAsFixed(1)}%';
        });
      }, onError: (e) {
        _toast('Upload Stream Error: $e');
      });

      await session.resume();
      await session.done;

      setState(() {
        _isLoading = false;
      });
      _toast('Upload complete! URL: ${session.resultUrl}');

      _listFiles(); // Refresh list
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Upload Error: $e';
      });
    }
  }

  Widget _buildConfigForm() {
    if (_isGithub) {
      return Column(
        children: [
          TextField(
              controller: _ghOwner,
              decoration: const InputDecoration(labelText: 'GitHub Owner')),
          TextField(
              controller: _ghRepo,
              decoration: const InputDecoration(labelText: 'GitHub Repo')),
          TextField(
              controller: _ghBranch,
              decoration: const InputDecoration(labelText: 'Branch')),
          TextField(
              controller: _ghToken,
              decoration: const InputDecoration(
                  labelText: 'GitHub PAT Token (required for upload)'),
              obscureText: true),
        ],
      );
    } else {
      return Column(
        children: [
          TextField(
              controller: _ikEndpoint,
              decoration:
                  const InputDecoration(labelText: 'ImageKit Endpoint URL')),
          TextField(
              controller: _ikPublicKey,
              decoration:
                  const InputDecoration(labelText: 'ImageKit Public Key')),
          TextField(
              controller: _ikPrivateKey,
              decoration:
                  const InputDecoration(labelText: 'ImageKit Private Key'),
              obscureText: true),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quantum Media Showcase'),
        backgroundColor: Colors.indigo,
      ),
      body: Row(
        children: [
          // Left Side: Config
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFFF1F5F9),
              child: ListView(
                children: [
                  const Text('Select Provider',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ToggleButtons(
                    isSelected: [_isGithub, !_isGithub],
                    onPressed: (index) {
                      setState(() {
                        _isGithub = index == 0;
                        _files = [];
                      });
                    },
                    children: const [
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('GitHub')),
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('ImageKit')),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Configuration',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  _buildConfigForm(),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.list),
                    label: const Text('List Files'),
                    onPressed: _isLoading ? null : _listFiles,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.upload),
                    label: const Text('Upload Dummy File'),
                    onPressed: _isLoading ? null : _uploadDummyFile,
                  ),
                  const SizedBox(height: 24),
                  Text(_statusMessage,
                      style: const TextStyle(
                          color: Colors.indigo, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),

          // Right Side: Results
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('File Browser',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (_isLoading && _files.isEmpty)
                    const Center(child: CircularProgressIndicator()),
                  if (!_isLoading && _files.isEmpty)
                    const Center(
                        child: Text('No files loaded. Click "List Files".')),
                  if (_files.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        itemCount: _files.length,
                        itemBuilder: (context, index) {
                          final file = _files[index];
                          final isDir = file.mimeType == 'inode/directory';
                          return ListTile(
                            leading: Icon(
                                isDir ? Icons.folder : Icons.insert_drive_file,
                                color: isDir ? Colors.amber : Colors.indigo),
                            title: Text(file.path),
                            subtitle: Text(file.url ?? 'No URL'),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
