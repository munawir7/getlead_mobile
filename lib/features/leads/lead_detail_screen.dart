import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import 'create_lead_screen.dart';
import 'lead_list_controller.dart';
import 'lead_model.dart';
import 'leads_repository.dart';

class LeadDetailScreen extends ConsumerStatefulWidget {
  final String leadId;

  const LeadDetailScreen({
    super.key,
    required this.leadId,
  });

  @override
  ConsumerState<LeadDetailScreen> createState() =>
      _LeadDetailScreenState();
}

class _LeadDetailScreenState
    extends ConsumerState<LeadDetailScreen> {
  LeadModel? _lead;

  bool _isLoading = true;
  bool _isDeleting = false;
  bool _isLoadingNotes = false;
  bool _isSavingNote = false;
  bool _isUploading = false;
  bool _isRecording = false;
  bool _isRecordingBusy = false;

  String? _errorMessage;

  int _selectedTab = 0;

  final TextEditingController _noteController =
      TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<Map<String, dynamic>> _notes = [];

  String? _recordingPath;
  String _recordedFileExtension = 'm4a';
  Timer? _recordingTimer;
  int _recordingDurationSeconds = 0;

  String? _currentlyPlayingUrl;
  bool _isPlayingAudio = false;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _loadLead();
    _loadNotes();
    _listenToAudioPlayer();
  }

  void _listenToAudioPlayer() {
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          _isPlayingAudio = false;
          _currentlyPlayingUrl = null;
        });
      } else {
        setState(() {
          _isPlayingAudio = state.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _playerStateSubscription?.cancel();
    _noteController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD LEAD
  // ============================================================

  Future<void> _loadLead() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final lead = await ref
          .read(leadsRepositoryProvider)
          .getLeadDetail(widget.leadId);

      if (!mounted) return;

      setState(() {
        _lead = lead;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // ============================================================
  // LOAD NOTES
  // ============================================================

  Future<void> _loadNotes() async {
    if (!mounted) return;

    setState(() {
      _isLoadingNotes = true;
    });

    try {
      final result = await ref
          .read(leadsRepositoryProvider)
          .getLeadNotes(leadId: widget.leadId);

      if (!mounted) return;

      setState(() {
        _notes = result;
        _isLoadingNotes = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingNotes = false;
      });

      _showMessage('Unable to load notes: $e');
    }
  }

  // ============================================================
  // SAVE TEXT NOTE
  // ============================================================

  Future<void> _saveTextNote() async {
    final content = _noteController.text.trim();

    if (content.isEmpty || _isSavingNote) return;

    setState(() {
      _isSavingNote = true;
    });

    try {
      await ref
          .read(leadsRepositoryProvider)
          .createLeadNote(
            leadId: widget.leadId,
            content: content,
          );

      if (!mounted) return;

      _noteController.clear();

      await _loadNotes();

      if (!mounted) return;

      _showMessage('Note saved successfully.');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Unable to save note: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSavingNote = false;
        });
      }
    }
  }

  // ============================================================
  // ATTACHMENT MENU
  // ============================================================

 void _showAttachmentMenu() {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      return SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Add attachment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Camera and Gallery
                Row(
                  children: [
                    Expanded(
                      child: _AttachmentOption(
                        icon: Icons.camera_alt_outlined,
                        label: 'Camera',
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _pickImage(ImageSource.camera);
                        },
                      ),
                    ),
                    Expanded(
                      child: _AttachmentOption(
                        icon: Icons.photo_library_outlined,
                        label: 'Gallery',
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _pickImage(ImageSource.gallery);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // PDF and Audio
                Row(
                  children: [
                    Expanded(
                      child: _AttachmentOption(
                        icon: Icons.picture_as_pdf_outlined,
                        label: 'PDF',
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _pickPdf();
                        },
                      ),
                    ),
                    Expanded(
                      child: _AttachmentOption(
                        icon: Icons.audio_file_outlined,
                        label: 'Audio',
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _pickAudio();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

  // ============================================================
  // CAMERA / GALLERY
  // ============================================================
Future<void> _pickImage(ImageSource source) async {
  try {
    final image = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (image == null) return;

    // Read image bytes directly.
    final bytes = await image.readAsBytes();

    // Pass the image bytes and path to the upload workflow.
    await _uploadAttachment(
      file_picker.PlatformFile(
        name: image.name,
        path: image.path,
        size: bytes.length,
        bytes: bytes,
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('========== IMAGE SELECTION ERROR ==========');
    debugPrint('Error: $e');
    debugPrint('Stack trace: $stackTrace');
    debugPrint('============================================');

    if (!mounted) return;

    _showMessage('Unable to select image: ${_cleanErrorMessage(e)}');
  }
}
  // ============================================================
  // PICK AUDIO
  // ============================================================

  Future<void> _pickAudio() async {
    try {
      final result = await file_picker.FilePicker.pickFiles(
        type: file_picker.FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final selectedFile = result.files.first;

      if (selectedFile.size == 0) {
        _showMessage('The selected audio file is empty.');
        return;
      }

      await _uploadAttachment(selectedFile);
    } catch (e, stackTrace) {
      debugPrint('========== AUDIO SELECTION ERROR ==========');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('============================================');

      if (!mounted) return;

      _showMessage('Unable to select audio: ${_cleanErrorMessage(e)}');
    }
  }
  // ============================================================
  // UPLOAD ATTACHMENT
  // ============================================================

  Future<void> _uploadAttachment(
    file_picker.PlatformFile file, {
    String? defaultTitle,
  }) async {
    if (_isUploading) return;

    final titleController = TextEditingController(
      text: defaultTitle ?? file.name,
    );

    final contentController = TextEditingController();

    final shouldUpload = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add attachment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                file.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('Upload'),
            ),
          ],
        );
      },
    );

    if (shouldUpload != true) {
      titleController.dispose();
      contentController.dispose();
      return;
    }

    if (!mounted) {
      titleController.dispose();
      contentController.dispose();
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      await ref
          .read(leadsRepositoryProvider)
          .uploadLeadAttachment(
            leadId: widget.leadId,
            file: file,
            title: titleController.text,
            content: contentController.text,
          );

      if (!mounted) return;

      await _loadNotes();

      if (!mounted) return;

      _showMessage('Attachment uploaded successfully.');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Attachment upload failed: ${_cleanErrorMessage(e)}');
    } finally {
      titleController.dispose();
      contentController.dispose();

      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  // ============================================================
  // VOICE RECORDING
  // ============================================================

  Future<void> _toggleRecording() async {
    if (_isRecordingBusy) return;

    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    if (_isRecordingBusy) return;
    _isRecordingBusy = true;

    try {
      // 1. Microphone permission
      if (kIsWeb) {
        // On Web, AudioRecorder.hasPermission() requests browser permission
        final hasPermission = await _audioRecorder.hasPermission();
        if (!hasPermission) {
          if (!mounted) return;
          _showMessage('Microphone permission was not granted by browser.');
          return;
        }
      } else {
        // On Mobile, use permission_handler
        bool hasMicPermission = await Permission.microphone.isGranted;
        if (!hasMicPermission) {
          final status = await Permission.microphone.request();
          hasMicPermission = status.isGranted;
          if (!hasMicPermission) {
            if (!mounted) return;
            if (status.isPermanentlyDenied) {
              _showMessage(
                'Microphone permission is permanently denied. Please enable it in Settings.',
              );
              await openAppSettings();
            } else {
              _showMessage('Microphone permission was not granted.');
            }
            return;
          }
        }
      }

      // 2. Stop any existing playback or recording safely
      try {
        if (await _audioRecorder.isRecording()) {
          await _audioRecorder.stop();
        }
      } catch (_) {}

      try {
        if (_audioPlayer.playing) {
          await _audioPlayer.stop();
        }
      } catch (_) {}

      // 3. Encoder selection and path
      String path = '';
      AudioEncoder encoder = AudioEncoder.aacLc;
      _recordedFileExtension = 'm4a';

      if (kIsWeb) {
        // In browser (Chrome/Edge/Safari/Firefox)
        if (await _audioRecorder.isEncoderSupported(AudioEncoder.aacLc)) {
          encoder = AudioEncoder.aacLc;
          _recordedFileExtension = 'm4a';
        } else if (await _audioRecorder.isEncoderSupported(AudioEncoder.wav)) {
          encoder = AudioEncoder.wav;
          _recordedFileExtension = 'wav';
        } else if (await _audioRecorder.isEncoderSupported(AudioEncoder.opus)) {
          encoder = AudioEncoder.opus;
          _recordedFileExtension = 'webm';
        }
        path = ''; // Web doesn't use file system paths
      } else {
        // Mobile (Android / iOS)
        final directory = await getTemporaryDirectory();
        path =
            '${directory.path}/lead_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
        encoder = AudioEncoder.aacLc;
        _recordedFileExtension = 'm4a';
      }

      // 4. Start recording with mono channel (1 channel)
      try {
        await _audioRecorder.start(
          RecordConfig(
            encoder: encoder,
            numChannels: 1,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: path,
        );
      } catch (startError) {
        debugPrint('Standard RecordConfig failed: $startError, falling back to minimal config');
        await _audioRecorder.start(
          RecordConfig(
            encoder: encoder,
            numChannels: 1,
          ),
          path: path,
        );
      }

      if (!mounted) return;

      setState(() {
        _recordingPath = path;
        _isRecording = true;
        _recordingDurationSeconds = 0;
      });

      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _recordingDurationSeconds++;
        });
      });
    } catch (e, stackTrace) {
      debugPrint('========== START RECORDING ERROR ==========');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('===========================================');

      if (!mounted) return;
      _showMessage('Unable to start recording: ${_cleanErrorMessage(e)}');
    } finally {
      _isRecordingBusy = false;
    }
  }

  Future<void> _cancelRecording() async {
    if (!_isRecording && !_isRecordingBusy) return;
    _isRecordingBusy = true;
    _recordingTimer?.cancel();
    _recordingTimer = null;

    try {
      final path = await _audioRecorder.stop();
      if (!kIsWeb) {
        final filePath = path ?? _recordingPath;
        if (filePath != null) {
          final file = File(filePath);
          if (await file.exists()) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Error cancelling recording: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _recordingPath = null;
          _recordingDurationSeconds = 0;
        });
      }
      _isRecordingBusy = false;
    }
  }

  Future<void> _stopRecording() async {
    if (_isRecordingBusy) return;
    _isRecordingBusy = true;
    _recordingTimer?.cancel();
    _recordingTimer = null;

    try {
      final path = await _audioRecorder.stop();

      // Brief delay to allow the OS/browser to finalize
      await Future<void>.delayed(const Duration(milliseconds: 150));

      if (!mounted) return;

      final filePath = path ?? _recordingPath;

      setState(() {
        _isRecording = false;
        _recordingPath = filePath;
        _recordingDurationSeconds = 0;
      });

      if (filePath == null || filePath.isEmpty) {
        _showMessage('Recording file was not created.');
        return;
      }

      final Uint8List bytes;

      if (kIsWeb) {
        // In Flutter Web, filePath is a blob: URL
        try {
          final dio = Dio();
          final response = await dio.get<List<int>>(
            filePath,
            options: Options(responseType: ResponseType.bytes),
          );
          if (response.data == null || response.data!.isEmpty) {
            _showMessage('Recording is empty. Please try again.');
            return;
          }
          bytes = Uint8List.fromList(response.data!);
        } catch (fetchError) {
          debugPrint('Failed to read blob URL on web: $fetchError');
          _showMessage('Unable to read recorded audio: ${_cleanErrorMessage(fetchError)}');
          return;
        }
      } else {
        // Mobile (Android / iOS)
        final file = File(filePath);
        if (!await file.exists()) {
          _showMessage('Recording file was not found.');
          return;
        }
        final size = await file.length();
        if (size == 0) {
          _showMessage('Recording is empty. Please try again.');
          try {
            if (await file.exists()) {
              await file.delete();
            }
          } catch (_) {}
          return;
        }
        bytes = await file.readAsBytes();
      }

      if (bytes.isEmpty) {
        _showMessage('Recording is empty. Please try again.');
        return;
      }

      final now = DateTime.now();
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final formattedTime =
          '${twoDigits(now.day)}/${twoDigits(now.month)}/${now.year} ${twoDigits(now.hour)}:${twoDigits(now.minute)}';

      await _uploadAttachment(
        file_picker.PlatformFile(
          name: 'voice_note_${now.millisecondsSinceEpoch}.$_recordedFileExtension',
          path: kIsWeb ? null : filePath,
          size: bytes.length,
          bytes: bytes,
        ),
        defaultTitle: 'Voice Note - $formattedTime',
      );
    } catch (e, stackTrace) {
      debugPrint('========== STOP RECORDING ERROR ==========');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('==========================================');

      if (!mounted) return;
      _showMessage('Unable to finish recording: ${_cleanErrorMessage(e)}');
    } finally {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _recordingDurationSeconds = 0;
        });
      }
      _isRecordingBusy = false;
    }
  }

  // ============================================================
  // PLAY AUDIO & OPEN LINKS
  // ============================================================

  Future<void> _togglePlayAudio(String url) async {
    try {
      if (_currentlyPlayingUrl == url && _isPlayingAudio) {
        await _audioPlayer.pause();
        setState(() {
          _isPlayingAudio = false;
        });
        return;
      }

      if (_currentlyPlayingUrl != url) {
        await _audioPlayer.stop();
        _currentlyPlayingUrl = url;
        await _audioPlayer.setUrl(url);
      }

      setState(() {
        _isPlayingAudio = true;
      });

      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Audio playback error: $e');
      if (!mounted) return;
      _showMessage('Unable to play audio: ${_cleanErrorMessage(e)}');
    }
  }

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showMessage('Could not open file link.');
      }
    } catch (e) {
      _showMessage('Unable to open file link: $e');
    }
  }

  // ============================================================
  // EDIT LEAD
  // ============================================================

  Future<void> _editLead() async {
    final lead = _lead;

    if (lead == null) return;

    final result = await Navigator.push<Object?>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateLeadScreen(lead: lead),
      ),
    );

    if (!mounted) return;

    if (result is LeadModel) {
      setState(() {
        _lead = result;
      });

      _showMessage('Lead details updated successfully.');
    } else if (result == true) {
      await _loadLead();

      if (!mounted) return;

      _showMessage('Lead details updated successfully.');
    }
  }

  // ============================================================
  // DELETE LEAD
  // ============================================================

  Future<void> _deleteLead() async {
    final lead = _lead;

    if (lead == null || _isDeleting) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Lead'),
          content: Text(
            'Are you sure you want to delete "${lead.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      await ref
          .read(leadListControllerProvider.notifier)
          .deleteLead(leadId: lead.id);

      if (!mounted) return;

      _showMessage('Lead deleted successfully.');

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isDeleting = false;
      });

      _showMessage('Failed to delete lead: $e');
    }
  }

  // ============================================================
  // MAIN BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lead Details'),
        actions: [
          if (_lead != null)
            IconButton(
              onPressed: _isDeleting ? null : _editLead,
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Lead',
            ),
          if (_lead != null)
            IconButton(
              onPressed: _isDeleting ? null : _deleteLead,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete Lead',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildError()
              : _lead == null
                  ? const Center(child: Text('Lead not found.'))
                  : _buildTabbedBody(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Unable to load lead.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadLead,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TABS
  // ============================================================

  Widget _buildTabbedBody() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            children: [
              _TabButton(
                label: 'Info',
                selected: _selectedTab == 0,
                onTap: () => setState(() => _selectedTab = 0),
              ),
              _TabButton(
                label: 'Notes',
                selected: _selectedTab == 1,
                onTap: () {
                  setState(() => _selectedTab = 1);
                  _loadNotes();
                },
              ),
              _TabButton(
                label: 'Activities',
                selected: _selectedTab == 2,
                onTap: () => setState(() => _selectedTab = 2),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: IndexedStack(
            index: _selectedTab,
            children: [
              _buildInfoTab(),
              _buildNotesTab(),
              _buildActivitiesTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // INFO TAB
  // ============================================================

  Widget _buildInfoTab() {
    final lead = _lead!;

    return RefreshIndicator(
      onRefresh: _loadLead,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lead.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lead ID: ${lead.id}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contact Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (lead.phoneNumbers.isNotEmpty)
                    _InfoRow(
                      icon: Icons.phone,
                      title: 'Phone',
                      value: lead.phoneNumbers.join(', '),
                    ),
                  if (lead.email != null && lead.email!.isNotEmpty)
                    _InfoRow(
                      icon: Icons.email_outlined,
                      title: 'Email',
                      value: lead.email!,
                    ),
                  if (lead.phoneNumbers.isEmpty &&
                      (lead.email == null || lead.email!.isEmpty))
                    const Text('No contact information available.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lead Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (lead.source != null)
                    _InfoRow(
                      icon: Icons.source_outlined,
                      title: 'Source',
                      value: lead.source!.name,
                    ),
                  if (lead.status != null)
                    _InfoRow(
                      icon: Icons.flag_outlined,
                      title: 'Status',
                      value: lead.status!.name,
                    ),
                  if (lead.purposes.isNotEmpty)
                    _InfoRow(
                      icon: Icons.category_outlined,
                      title: 'Purpose',
                      value: lead.purposes.join(', '),
                    ),
                  _InfoRow(
                    icon: Icons.star_outline,
                    title: 'Score',
                    value: lead.score.toString(),
                  ),
                ],
              ),
            ),
          ),
          if (lead.notes != null && lead.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Legacy Notes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(lead.notes!),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _isDeleting ? null : _deleteLead,
              icon: _isDeleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
              label: Text(
                _isDeleting ? 'Deleting...' : 'Delete Lead',
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ============================================================
  // NOTES TAB
  // ============================================================

  Widget _buildNotesTab() {
    return Column(
      children: [
        Expanded(
          child: _isLoadingNotes && _notes.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _notes.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _loadNotes,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        children: const [
                          SizedBox(height: 100),
                          Icon(
                            Icons.sticky_note_2_outlined,
                            size: 60,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Center(
                            child: Text(
                              'No notes yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Center(
                            child: Text(
                              'Add a note or attachment below.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadNotes,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(12),
                        itemCount: _notes.length,
                        itemBuilder: (context, index) {
                          return _buildNoteCard(_notes[index]);
                        },
                      ),
                    ),
        ),
        if (_isUploading)
          const LinearProgressIndicator(minHeight: 3),
        _buildComposer(),
      ],
    );
  }

  Widget _buildNoteCard(Map<String, dynamic> note) {
    final title = note['title']?.toString() ?? 'Note';
    final content = note['content']?.toString() ?? '';
    final type = note['type']?.toString() ?? 'note';
    final createdAt = (note['created_at'] ?? note['createdAt'] ?? note['date'])?.toString() ?? '';
    final fileName = (note['file_name'] ?? note['fileName'] ?? note['name'])?.toString();
    final fileMimeType = (note['file_mime_type'] ?? note['mime_type'] ?? note['fileMimeType'])?.toString();
    final fileUrl = (note['file_url'] ?? note['fileUrl'] ?? note['url'] ?? note['file_path'] ?? note['filePath'])?.toString();

    IconData icon = Icons.sticky_note_2_outlined;
    final ext = fileName?.split('.').last.toLowerCase() ?? '';
    final bool isAudio = fileMimeType?.startsWith('audio/') == true ||
        ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'webm'].contains(ext);

    if (type == 'file' || fileName != null) {
      if (fileMimeType?.startsWith('image/') == true ||
          ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
        icon = Icons.image_outlined;
      } else if (isAudio) {
        icon = Icons.audio_file_outlined;
      } else if (fileMimeType == 'application/pdf' || ext == 'pdf') {
        icon = Icons.picture_as_pdf_outlined;
      } else {
        icon = Icons.attach_file;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.red.withValues(alpha: 0.08),
                  child: Icon(icon, color: Colors.red),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(createdAt),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (content.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(content),
            ],
            if (fileName != null && fileName.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isAudio
                      ? Colors.red.withValues(alpha: 0.05)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: isAudio
                      ? Border.all(color: Colors.red.withValues(alpha: 0.2))
                      : null,
                ),
                child: Row(
                  children: [
                    if (isAudio && fileUrl != null && fileUrl.isNotEmpty) ...[
                      IconButton(
                        onPressed: () => _togglePlayAudio(fileUrl),
                        icon: Icon(
                          _currentlyPlayingUrl == fileUrl && _isPlayingAudio
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_fill,
                          color: Colors.red,
                          size: 32,
                        ),
                        tooltip: _currentlyPlayingUrl == fileUrl && _isPlayingAudio
                            ? 'Pause'
                            : 'Play audio',
                      ),
                      const SizedBox(width: 4),
                    ] else ...[
                      const Icon(Icons.attach_file),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          if (isAudio && _currentlyPlayingUrl == fileUrl)
                            Text(
                              _isPlayingAudio ? 'Playing...' : 'Paused',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (fileUrl != null && fileUrl.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.open_in_new, size: 18),
                        onPressed: () => _openUrl(fileUrl),
                        tooltip: 'Open file',
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // COMPOSER
  // ============================================================

  Widget _buildComposer() {
    if (_isRecording) {
      final minutes =
          (_recordingDurationSeconds ~/ 60).toString().padLeft(2, '0');
      final seconds =
          (_recordingDurationSeconds % 60).toString().padLeft(2, '0');

      return SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            border: Border(
              top: BorderSide(color: Colors.red.shade200),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: _isRecordingBusy ? null : _cancelRecording,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Cancel recording',
              ),
              const SizedBox(width: 6),
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Recording  $minutes:$seconds',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _isRecordingBusy ? null : _stopRecording,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Save'),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton.filled(
              onPressed: _isUploading ? null : _showAttachmentMenu,
              style: IconButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
              ),
              icon: const Icon(Icons.add),
              tooltip: 'Add attachment',
            ),
            Expanded(
              child: TextField(
                controller: _noteController,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Add your notes here...',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: _isSavingNote || _isUploading
                  ? null
                  : _toggleRecording,
              icon: Icon(
                Icons.mic_none,
                color: Colors.grey.shade700,
              ),
              tooltip: 'Record voice note',
            ),
            IconButton(
              onPressed: _isSavingNote ? null : _saveTextNote,
              icon: _isSavingNote
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send, color: Colors.red),
              tooltip: 'Save note',
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ACTIVITIES TAB
  // ============================================================

  Widget _buildActivitiesTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_note_outlined,
              size: 56,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 12),
            const Text(
              'Activities',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Activity history can be connected when its API is available.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _formatDate(String value) {
    if (value.isEmpty) return '';

    final parsed = DateTime.tryParse(value);

    if (parsed == null) return value;

    final local = parsed.toLocal();

    String twoDigits(int number) => number.toString().padLeft(2, '0');

    return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _pickPdf() async {
    try {
      final result = await file_picker.FilePicker.pickFiles(
        type: file_picker.FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'xls',
          'xlsx',
          'txt',
          'csv',
        ],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final selectedFile = result.files.first;

      if (selectedFile.size == 0) {
        _showMessage('The selected file is empty.');
        return;
      }

      await _uploadAttachment(selectedFile);
    } catch (e, stackTrace) {
      debugPrint('========== FILE SELECTION ERROR ==========');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('==========================================');

      if (!mounted) return;

      _showMessage('Unable to select file: ${_cleanErrorMessage(e)}');
    }
  }

  String _cleanErrorMessage(Object error) {
    final str = error.toString();
    if (str.startsWith('Exception: ')) {
      return str.substring('Exception: '.length);
    }
    return str;
  }
}

// ================================================================
// TAB BUTTON
// ================================================================

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.red : Colors.grey.shade700;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.red.withValues(alpha: 0.08) : null,
            borderRadius: BorderRadius.circular(8),
            border: selected
                ? const Border(
                    bottom: BorderSide(
                      color: Colors.red,
                      width: 2,
                    ),
                  )
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// ATTACHMENT OPTION
// ================================================================

class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.red.withValues(alpha: 0.08),
              child: Icon(icon, color: Colors.red),
            ),
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// INFO ROW
// ================================================================

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 22,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}