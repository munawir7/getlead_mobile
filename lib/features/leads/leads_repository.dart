import 'dart:io';


import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:getlead_mobile/features/auth/auth_controller.dart';

import '../../api/api_client.dart';
import '../../api/endpoints.dart';
import '../../core/constants.dart';
import 'lead_model.dart';

// ============================================================
// RIVERPOD PROVIDER
// ============================================================

final leadsRepositoryProvider = Provider<LeadsRepository>((ref) {
  return LeadsRepository(
    apiClient: ref.read(apiClientProvider),
  );
});

// ============================================================
// LEADS PAGE MODEL
// ============================================================

class LeadsPage {
  const LeadsPage({
    required this.leads,
    required this.nextCursor,
    this.total,
  });

  final List<LeadModel> leads;
  final String? nextCursor;
  final int? total;
}

// ============================================================
// LEAD METADATA MODEL
// ============================================================

class LeadMeta {
  const LeadMeta({
    required this.sources,
    required this.statuses,
  });

  final List<LeadSource> sources;
  final List<LeadStatus> statuses;
}

// ============================================================
// LEADS REPOSITORY
// ============================================================

class LeadsRepository {
  LeadsRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  // ============================================================
  // DEBUG HELPERS
  // ============================================================

  void _logRequest(String label, String endpoint) {
    if (!kDebugMode) return;

    debugPrint('========== $label ==========');
    debugPrint('Business ID: ${AppConstants.businessId}');
    debugPrint('Endpoint: $endpoint');
  }

  void _logError(String label, Object error) {
    if (!kDebugMode) return;

    debugPrint('========== $label ERROR ==========');
    debugPrint(error.toString());
    debugPrint('==================================');
  }

  // ============================================================
  // GET LEADS
  // ============================================================

  Future<LeadsPage> getLeads({
    String? cursor,
  }) async {
    final endpoint = ApiEndpoints.leads(
      AppConstants.businessId,
    );

    final queryParameters = <String, dynamic>{
      'per_page': AppConstants.pageSize,
    };

    if (cursor != null && cursor.isNotEmpty) {
      queryParameters['cursor'] = cursor;
    }

    _logRequest('GET LEADS', endpoint);

    try {
      final response = await _apiClient.get(
        endpoint,
        queryParameters: queryParameters,
      );

      final responseData = response.data;

      if (responseData is! Map) {
        throw Exception('Invalid leads response.');
      }

      final data = responseData['data'];

      if (data is! List) {
        throw Exception('Invalid leads data.');
      }

      final leads = data
          .whereType<Map>()
          .map(
            (item) => LeadModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();

      String? nextCursor;
      int? total;

      final meta = responseData['meta'];

      if (meta is Map) {
        final cursorValue = meta['next_cursor'];

        if (cursorValue != null) {
          final value = cursorValue.toString().trim();

          if (value.isNotEmpty) {
            nextCursor = value;
          }
        }

        final totalValue =
            meta['total'] ??
            meta['total_leads'] ??
            meta['count'];

        if (totalValue != null) {
          total = int.tryParse(totalValue.toString());
        }
      }

      if (total == null && responseData['total'] != null) {
        total = int.tryParse(
          responseData['total'].toString(),
        );
      }

      return LeadsPage(
        leads: leads,
        nextCursor: nextCursor,
        total: total,
      );
    } catch (error) {
      _logError('GET LEADS', error);
      rethrow;
    }
  }

  // ============================================================
  // GET LEAD DETAIL
  // ============================================================

  Future<LeadModel> getLeadDetail(String leadId) async {
    final endpoint = ApiEndpoints.leadDetail(
      AppConstants.businessId,
      leadId,
    );

    _logRequest('GET LEAD DETAIL', endpoint);

    try {
      final response = await _apiClient.get(endpoint);
      final responseData = response.data;

      if (responseData is! Map) {
        throw Exception('Invalid lead response.');
      }

      final data = responseData['data'];

      if (data is Map) {
        return LeadModel.fromJson(
          Map<String, dynamic>.from(data),
        );
      }

      // Some endpoints may return the lead directly.
      if (responseData['id'] != null) {
        return LeadModel.fromJson(
          Map<String, dynamic>.from(responseData),
        );
      }

      throw Exception('Lead details were not returned.');
    } catch (error) {
      _logError('GET LEAD DETAIL', error);
      rethrow;
    }
  }

  // ============================================================
  // GET LEAD METADATA
  // ============================================================

  Future<LeadMeta> getLeadMeta() async {
    final endpoint = ApiEndpoints.leadMeta(
      AppConstants.businessId,
    );

    _logRequest('GET LEAD METADATA', endpoint);

    try {
      final response = await _apiClient.get(endpoint);
      final responseData = response.data;

      if (responseData is! Map) {
        throw Exception('Invalid lead metadata response.');
      }

      final rawData = responseData['data'];

      final Map<dynamic, dynamic> metaData;

      if (rawData is Map) {
        metaData = rawData;
      } else {
        metaData = responseData;
      }

      final sources = <LeadSource>[];
      final rawSources = metaData['sources'];

      if (rawSources is List) {
        for (final item in rawSources) {
          if (item is Map) {
            sources.add(
              LeadSource.fromJson(
                Map<String, dynamic>.from(item),
              ),
            );
          }
        }
      }

      final statuses = <LeadStatus>[];
      final rawStatuses = metaData['statuses'];

      if (rawStatuses is List) {
        for (final item in rawStatuses) {
          if (item is Map) {
            statuses.add(
              LeadStatus.fromJson(
                Map<String, dynamic>.from(item),
              ),
            );
          }
        }
      }

      return LeadMeta(
        sources: sources,
        statuses: statuses,
      );
    } catch (error) {
      _logError('GET LEAD METADATA', error);
      rethrow;
    }
  }

  // ============================================================
  // CREATE LEAD
  // ============================================================

  Future<LeadModel> createLead({
    required String name,
    required String phoneNumber,
    String? email,
    required String sourceId,
    String? statusId,
    String? notes,
  }) async {
    final endpoint = ApiEndpoints.leads(
      AppConstants.businessId,
    );

    final data = <String, dynamic>{
      'name': name.trim(),
      'phone_numbers': [
        {
          'phone_number': phoneNumber.trim(),
        },
      ],
      'source_id': sourceId,
    };

    if (email != null && email.trim().isNotEmpty) {
      data['email'] = email.trim();
    }

    if (statusId != null && statusId.trim().isNotEmpty) {
      data['status_id'] = statusId.trim();
    }

    if (notes != null && notes.trim().isNotEmpty) {
      data['notes'] = notes.trim();
    }

    _logRequest('CREATE LEAD', endpoint);

    try {
      final response = await _apiClient.post(
        endpoint,
        data: data,
      );

      final responseData = response.data;

      if (responseData is! Map) {
        throw Exception('Invalid create lead response.');
      }

      final responseLead = responseData['data'];

      if (responseLead is Map) {
        return LeadModel.fromJson(
          Map<String, dynamic>.from(responseLead),
        );
      }

      final leadId = responseData['id'];

      if (leadId != null &&
          leadId.toString().trim().isNotEmpty) {
        return getLeadDetail(leadId.toString());
      }

      throw Exception(
        'Created lead ID was not returned by the server.',
      );
    } catch (error) {
      _logError('CREATE LEAD', error);
      rethrow;
    }
  }

  // ============================================================
  // EDIT LEAD
  // ============================================================

  Future<LeadModel> editLead({
    required String leadId,
    required String name,
    required String phoneNumber,
    String? email,
    required String sourceId,
    String? statusId,
    String? notes,
  }) async {
    final endpoint = ApiEndpoints.updateLead(
      AppConstants.businessId,
      leadId,
    );

    final data = <String, dynamic>{
      'name': name.trim(),
      'source_id': sourceId,
      'phone_numbers': [
        {
          'phone_number': phoneNumber.trim(),
        },
      ],
      'email': email?.trim().isNotEmpty == true
          ? email!.trim()
          : null,
      'status_id': statusId?.trim().isNotEmpty == true
          ? statusId!.trim()
          : null,
      'notes': notes?.trim().isNotEmpty == true
          ? notes!.trim()
          : null,
    };

    _logRequest('EDIT LEAD', endpoint);

    try {
      final response = await _apiClient.put(
        endpoint,
        data: data,
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        // Fetch complete lead details after updating.
        return getLeadDetail(leadId);
      }

      throw Exception('Failed to update lead.');
    } catch (error) {
      _logError('EDIT LEAD', error);
      rethrow;
    }
  }

  // ============================================================
  // PATCH LEAD
  // ============================================================

  Future<LeadModel> patchLead({
    required String leadId,
    required Map<String, dynamic> changes,
  }) async {
    if (changes.isEmpty) {
      return getLeadDetail(leadId);
    }

    final endpoint = ApiEndpoints.patchLead(
      AppConstants.businessId,
      leadId,
    );

    _logRequest('PATCH LEAD', endpoint);

    try {
      final response = await _apiClient.patch(
        endpoint,
        data: changes,
      );

      final responseData = response.data;

      if (responseData is Map) {
        final dataValue = responseData['data'];

        if (dataValue is Map) {
          return LeadModel.fromJson(
            Map<String, dynamic>.from(dataValue),
          );
        }

        if (responseData['id'] != null) {
          return getLeadDetail(leadId);
        }
      }

      return getLeadDetail(leadId);
    } catch (error) {
      _logError('PATCH LEAD', error);
      rethrow;
    }
  }

  // ============================================================
  // UPDATE LEAD STATUS
  // ============================================================

  Future<LeadModel> updateLeadStatus({
    required String leadId,
    required String statusId,
  }) async {
    final endpoint = ApiEndpoints.updateLeadStatus(
      AppConstants.businessId,
      leadId,
    );

    _logRequest('UPDATE LEAD STATUS', endpoint);

    try {
      final response = await _apiClient.patch(
        endpoint,
        data: {
          'status_id': statusId,
        },
      );

      final responseData = response.data;

      if (responseData is Map) {
        final dataValue = responseData['data'];

        if (dataValue is Map) {
          return LeadModel.fromJson(
            Map<String, dynamic>.from(dataValue),
          );
        }
      }

      return getLeadDetail(leadId);
    } catch (error) {
      _logError('UPDATE LEAD STATUS', error);
      rethrow;
    }
  }

  // ============================================================
  // TOGGLE LEAD STAR
  // ============================================================

  Future<LeadModel> toggleLeadStar({
    required String leadId,
  }) async {
    final endpoint = ApiEndpoints.toggleLeadStar(
      AppConstants.businessId,
      leadId,
    );

    _logRequest('TOGGLE LEAD STAR', endpoint);

    try {
      final response = await _apiClient.patch(endpoint);
      final responseData = response.data;

      if (responseData is Map) {
        final dataValue = responseData['data'];

        if (dataValue is Map) {
          return LeadModel.fromJson(
            Map<String, dynamic>.from(dataValue),
          );
        }
      }

      return getLeadDetail(leadId);
    } catch (error) {
      _logError('TOGGLE LEAD STAR', error);
      rethrow;
    }
  }

  // ============================================================
  // DELETE LEAD
  // ============================================================

  Future<void> deleteLead({
    required String leadId,
  }) async {
    final endpoint = ApiEndpoints.deleteLead(
      AppConstants.businessId,
      leadId,
    );

    _logRequest('DELETE LEAD', endpoint);

    try {
      await _apiClient.delete(endpoint);
    } catch (error) {
      _logError('DELETE LEAD', error);
      rethrow;
    }
  }

  // ============================================================
  // GET LEAD NOTES
  // ============================================================

  Future<List<Map<String, dynamic>>> getLeadNotes({
    required String leadId,
  }) async {
    final endpoint = ApiEndpoints.leadNotes(
      AppConstants.businessId,
      leadId,
    );

    _logRequest('GET LEAD NOTES', endpoint);

    try {
      final response = await _apiClient.get(endpoint);
      final responseData = response.data;

      // Your notes API returns a list directly.
      if (responseData is List) {
        return responseData
            .whereType<Map>()
            .map(
              (item) => Map<String, dynamic>.from(item),
            )
            .toList();
      }

      // Also support a wrapped response if the API returns one.
      if (responseData is Map) {
        final data = responseData['data'];

        if (data is List) {
          return data
              .whereType<Map>()
              .map(
                (item) => Map<String, dynamic>.from(item),
              )
              .toList();
        }
      }

      throw Exception('Invalid lead notes response.');
    } catch (error) {
      _logError('GET LEAD NOTES', error);
      rethrow;
    }
  }

  // ============================================================
  // CREATE TEXT NOTE
  // ============================================================

  Future<String> createLeadNote({
    required String leadId,
    required String content,
    String? title,
  }) async {
    final endpoint = ApiEndpoints.createLeadNote(
      AppConstants.businessId,
      leadId,
    );

    final trimmedContent = content.trim();

    if (trimmedContent.isEmpty) {
      throw Exception('Please enter a note.');
    }

    final data = <String, dynamic>{
      'type': 'note',
      'content': trimmedContent,
    };

    if (title != null && title.trim().isNotEmpty) {
      data['title'] = title.trim();
    }

    _logRequest('CREATE LEAD NOTE', endpoint);

    try {
      final response = await _apiClient.post(
        endpoint,
        data: data,
      );

      final responseData = response.data;

      if (responseData is Map) {
        final noteData = responseData['data'];

        if (noteData is Map) {
          final noteId =
              noteData['note_id'] ?? noteData['id'];

          if (noteId != null) {
            return noteId.toString();
          }
        }

        final noteId =
            responseData['note_id'] ?? responseData['id'];

        if (noteId != null) {
          return noteId.toString();
        }
      }

      // The request may succeed even if the API omits the ID.
      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        return '';
      }

      throw Exception('Failed to create lead note.');
    } catch (error) {
      _logError('CREATE LEAD NOTE', error);
      rethrow;
    }
  }

  // ============================================================
  // UPLOAD LEAD ATTACHMENT
  //
  // Step 1: Request a presigned upload URL.
  // Step 2: Upload the raw bytes to cloud storage.
  // Step 3: Save the attachment as a lead note.
  // ============================================================
Future<String> uploadLeadAttachment({
  required String leadId,
  required PlatformFile file,
  required String title,
  required String content,
}) async {
  final fileName = file.name;
  final mimeType = _getMimeType(fileName);

  // Read bytes in a web and mobile compatible way.
  final Uint8List fileBytes;

  if (file.bytes != null && file.bytes!.isNotEmpty) {
    fileBytes = file.bytes!;
  } else if (file.path != null && file.path!.isNotEmpty) {
    final localFile = File(file.path!);
    if (!await localFile.exists()) {
      throw Exception('Selected file could not be found on device.');
    }
    fileBytes = await localFile.readAsBytes();
  } else {
    throw Exception(
      'File data is unavailable. Please select the file again.',
    );
  }

  if (fileBytes.isEmpty) {
    throw Exception('The selected file is empty.');
  }

  _logRequest(
    'UPLOAD LEAD ATTACHMENT',
    ApiEndpoints.presignedUploadUrl(AppConstants.businessId),
  );

  try {
    // STEP 1: Request the presigned upload URL.
    debugPrint('UPLOAD STEP 1: Requesting presigned URL');
    debugPrint('File name: $fileName');
    debugPrint('MIME type: $mimeType');
    debugPrint('File size: ${fileBytes.length}');

    final presignedResponse = await _apiClient.post(
      ApiEndpoints.presignedUploadUrl(AppConstants.businessId),
      data: {
        'resource_type': 'notes',
        'file_name': fileName,
        'mime_type': mimeType,
        'file_size': fileBytes.length,
      },
    );

    final presignedResponseData = presignedResponse.data;

    if (presignedResponseData is! Map) {
      throw Exception('Invalid presigned upload response from server.');
    }

    // Handle nested 'data' map if present (standard GetLead API response format)
    final Map<dynamic, dynamic> dataMap = (presignedResponseData['data'] is Map)
        ? presignedResponseData['data'] as Map
        : presignedResponseData;

    final uploadUrl = (dataMap['upload_url'] ??
            dataMap['url'] ??
            dataMap['signed_url'] ??
            dataMap['presigned_url'] ??
            dataMap['uploadUrl'] ??
            presignedResponseData['upload_url'] ??
            presignedResponseData['url'])
        ?.toString();

    final storageFilePath = (dataMap['file_path'] ??
            dataMap['path'] ??
            dataMap['key'] ??
            dataMap['filePath'] ??
            dataMap['storage_path'] ??
            dataMap['file_url'] ??
            presignedResponseData['file_path'] ??
            presignedResponseData['path'])
        ?.toString();

    final method = (dataMap['method'] ?? presignedResponseData['method'] ?? 'PUT')
        .toString()
        .toUpperCase();

    if (uploadUrl == null || uploadUrl.isEmpty) {
      throw Exception('The server did not return an upload URL.');
    }

    if (storageFilePath == null || storageFilePath.isEmpty) {
      throw Exception(
        'The server did not return the storage file path.',
      );
    }

    // STEP 2: Upload raw bytes to cloud storage.
    // Do not send the API Bearer token to the presigned URL.
    debugPrint('UPLOAD STEP 2: Uploading file to storage via $method');

    final storageDio = Dio();

    try {
      if (method == 'POST') {
        final formMap = <String, dynamic>{};
        if (dataMap['fields'] is Map) {
          final fields = dataMap['fields'] as Map;
          fields.forEach((k, v) => formMap[k.toString()] = v);
        }
        formMap['file'] = MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
        );
        final formData = FormData.fromMap(formMap);
        await storageDio.post<dynamic>(
          uploadUrl,
          data: formData,
          options: Options(
            validateStatus: (status) =>
                status != null && status >= 200 && status < 300,
          ),
        );
      } else {
        final uploadHeaders = <String, dynamic>{
          'Content-Type': mimeType,
          'Content-Length': fileBytes.length,
        };

        if (dataMap['headers'] is Map) {
          final serverHeaders = dataMap['headers'] as Map;
          serverHeaders.forEach((key, value) {
            if (key != null && value != null) {
              uploadHeaders[key.toString()] = value.toString();
            }
          });
        }

        final uploadResponse = await storageDio.put<dynamic>(
          uploadUrl,
          data: Stream.fromIterable([fileBytes]),
          options: Options(
            headers: uploadHeaders,
            responseType: ResponseType.plain,
            validateStatus: (status) =>
                status != null && status >= 200 && status < 300,
          ),
        );

        debugPrint(
          'Storage upload status: ${uploadResponse.statusCode}',
        );
      }
    } catch (storageError) {
      debugPrint('Cloud storage upload error: $storageError');
      final isCorsError = kIsWeb &&
          storageError is DioException &&
          (storageError.type == DioExceptionType.connectionError ||
              storageError.message?.contains('CORS') == true ||
              storageError.message?.contains('XMLHttpRequest') == true);

      if (isCorsError) {
        debugPrint(
          'Web CORS detected. Attempting direct multipart upload fallback to API...',
        );
        try {
          final directFormData = FormData.fromMap({
            'type': 'file',
            'title': title.trim().isNotEmpty ? title.trim() : fileName,
            'content': content.trim(),
            'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
            'attachment': MultipartFile.fromBytes(fileBytes, filename: fileName),
            'file_name': fileName,
            'file_mime_type': mimeType,
          });
          final fallbackResponse = await _apiClient.post(
            ApiEndpoints.createLeadNote(AppConstants.businessId, leadId),
            data: directFormData,
          );
          if (fallbackResponse.statusCode == 200 ||
              fallbackResponse.statusCode == 201 ||
              fallbackResponse.statusCode == 204) {
            final fallbackData = fallbackResponse.data;
            if (fallbackData is Map) {
              final nData = fallbackData['data'];
              final nId = (nData is Map ? (nData['note_id'] ?? nData['id']) : null) ??
                  fallbackData['note_id'] ??
                  fallbackData['id'];
              return nId?.toString() ?? '';
            }
            return '';
          }
        } catch (fallbackError) {
          debugPrint('Direct multipart fallback also failed: $fallbackError');
        }

        throw Exception(
          'Browser CORS blocked upload to cloud storage in Chrome.\n\n'
          'To test on Chrome, launch with web security disabled:\n'
          'flutter run -d chrome --web-browser-flag "--disable-web-security" --web-browser-flag "--user-data-dir=C:/tmp/chrome_dev"\n\n'
          'Or test on an Android emulator/device where browser CORS does not apply.',
        );
      }
      rethrow;
    }

    // STEP 3: Create the lead note.
    debugPrint('UPLOAD STEP 3: Saving lead note');

    final noteResponse = await _apiClient.post(
      ApiEndpoints.createLeadNote(
        AppConstants.businessId,
        leadId,
      ),
      data: {
        'type': 'file',
        'title': title.trim().isNotEmpty ? title.trim() : fileName,
        'content': content.trim(),
        'file_path': storageFilePath,
        'path': storageFilePath,
        'file_name': fileName,
        'file_mime_type': mimeType,
        'mime_type': mimeType,
      },
    );

    final noteResponseData = noteResponse.data;

    if (noteResponseData is Map) {
      final noteData = noteResponseData['data'];

      if (noteData is Map) {
        final noteId = noteData['note_id'] ?? noteData['id'];

        if (noteId != null) {
          return noteId.toString();
        }
      }

      final noteId =
          noteResponseData['note_id'] ?? noteResponseData['id'];

      if (noteId != null) {
        return noteId.toString();
      }
    }

    if (noteResponse.statusCode == 200 ||
        noteResponse.statusCode == 201 ||
        noteResponse.statusCode == 204) {
      return '';
    }

    throw Exception(
      'The file was uploaded, but the note was not saved.',
    );
  } catch (error, stackTrace) {
    String detail = error.toString();
    if (error is DioException) {
      final resData = error.response?.data;
      if (resData is Map && resData['message'] != null) {
        detail = resData['message'].toString();
        if (resData['errors'] is Map) {
          final errs = (resData['errors'] as Map)
              .values
              .expand((e) => e is List ? e : [e])
              .join(', ');
          if (errs.isNotEmpty) detail += ' ($errs)';
        }
      } else if (error.response?.statusCode != null) {
        detail = 'Server error (${error.response!.statusCode}): ${error.message}';
      }
    }
    debugPrint('========== UPLOAD LEAD ATTACHMENT ERROR ==========');
    debugPrint('Details: $detail');
    debugPrint('Stack trace: $stackTrace');
    debugPrint('===================================================');

    _logError('UPLOAD LEAD ATTACHMENT', error);
    throw Exception(detail);
  }
}

  // ============================================================
  // GET MIME TYPE
  // ============================================================

  String _getMimeType(String fileName) {
    final extension = fileName
        .split('.')
        .last
        .toLowerCase();

    switch (extension) {
      case 'pdf':
        return 'application/pdf';

      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';

      case 'png':
        return 'image/png';

      case 'gif':
        return 'image/gif';

      case 'webp':
        return 'image/webp';

      case 'mp3':
        return 'audio/mpeg';

      case 'wav':
        return 'audio/wav';

      case 'm4a':
        return 'audio/mp4';

      case 'aac':
        return 'audio/aac';

      case 'ogg':
        return 'audio/ogg';

      case 'webm':
        return 'audio/webm';

      case 'mp4':
        return 'video/mp4';

      case 'mov':
        return 'video/quicktime';

      default:
        return 'application/octet-stream';
    }
  }
}