import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../api_services/api_services.dart';
import '../../api_services/urls.dart';
import '../../colors/appcolors.dart';
import '../../models/get_profile_model.dart';
import '../../prefs/app_preference.dart';
import '../../prefs/preference_key.dart';
import '../../utils/app_bar.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({Key? key}) : super(key: key);

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  final _aadhaarController = TextEditingController();
  final _policeController = TextEditingController();

  File? aadhaarFrontFile;
  File? aadhaarBackFile;
  File? policeFrontFile;
  File? policeBackFile;

  WorkerProfileModel? profile;
  bool isLoading = true;

  final ImagePicker _picker = ImagePicker();

  // ================= GET PROFILE (KYC DATA) =================

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    try {
      final token = AppPreference().getString(PreferencesKey.token);

      final res = await ApiService.getRequest(
        getPersonalInfoUrl,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      profile = WorkerProfileModel.fromJson(res.data);

      _aadhaarController.text = getDocumentNumber('aadhar');
      _policeController.text = getDocumentNumber('police_verification');
    } catch (e) {
      debugPrint("KYC fetch error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  String getDocumentNumber(String type) {
    try {
      return profile!.documents
          .firstWhere((doc) => doc.type == type)
          .number;
    } catch (_) {
      return '';
    }
  }

  String? getDocumentUrl(String type, bool isFront) {
    try {
      final doc =
      profile!.documents.firstWhere((doc) => doc.type == type);
      return isFront ? doc.frontUrl : doc.backUrl;
    } catch (_) {
      return null;
    }
  }

  // ================= IMAGE PICK & UPLOAD =================

  Future<void> pickAndUpload({
    required String docType,
    required bool isFront,
  }) async {
    final XFile? picked =
    await _picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    setState(() => isLoading = true);

    try {
      if (docType == 'aadhar') {
        isFront
            ? aadhaarFrontFile = File(picked.path)
            : aadhaarBackFile = File(picked.path);
      } else {
        isFront
            ? policeFrontFile = File(picked.path)
            : policeBackFile = File(picked.path);
      }

      await uploadKycDocuments();
      await fetchProfile();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Document uploaded successfully")),
      );
    } catch (e) {
      debugPrint("Upload error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ================= UPLOAD API =================

  Future<void> uploadKycDocuments() async {
    final token = AppPreference().getString(PreferencesKey.token);

    FormData formData = FormData();

    /// Aadhaar
    formData.fields.addAll([
      const MapEntry('id_type[]', 'aadhar'),
      MapEntry('id_number[]', _aadhaarController.text),
    ]);

    formData.files.addAll([
      if (aadhaarFrontFile != null)
        MapEntry('id_front[]',
            await MultipartFile.fromFile(aadhaarFrontFile!.path)),
      if (aadhaarBackFile != null)
        MapEntry('id_back[]',
            await MultipartFile.fromFile(aadhaarBackFile!.path)),
    ]);

    /// Police Verification
    formData.fields.addAll([
      const MapEntry('id_type[]', 'police_verification'),
      MapEntry('id_number[]', _policeController.text),
    ]);

    formData.files.addAll([
      if (policeFrontFile != null)
        MapEntry('id_front[]',
            await MultipartFile.fromFile(policeFrontFile!.path)),
      if (policeBackFile != null)
        MapEntry('id_back[]',
            await MultipartFile.fromFile(policeBackFile!.path)),
    ]);

    await ApiService.postRequest(
      '/api/worker/${profile!.id}/docs',
      formData,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ),
    );
  }

  // ================= UI HELPERS =================

  Widget _input({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF6F7FF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _filePicker({
    required String label,
    required String docType,
    required bool isFront,
    String? fileUrl,
  }) {
    final hasFile = fileUrl != null && fileUrl.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F7FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  hasFile ? "Document uploaded" : "Upload document",
                  style: TextStyle(
                      color: hasFile ? Colors.black : Colors.grey),
                ),
              ),
              if (hasFile)
                IconButton(
                  icon: const Icon(Icons.visibility, color: kBlack),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          backgroundColor: Colors.black,
                          appBar: AppBar(
                            backgroundColor: Colors.black,
                          ),
                          body: Center(
                            child: Image.network(fileUrl),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              IconButton(
                icon: const Icon(Icons.upload, color: kBlack),
                onPressed: () =>
                    pickAndUpload(docType: docType, isFront: isFront),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        appBar: CommonAppBar(title: 'KYC Verification'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: kWhite,
      appBar: CommonAppBar(title: 'KYC Verification'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _input(
              label: "Aadhaar Number",
              controller: _aadhaarController,
            ),
            _input(
              label: "Police Verification ID",
              controller: _policeController,
            ),

            _filePicker(
              label: "Aadhaar Card (Front)",
              docType: "aadhar",
              isFront: true,
              fileUrl: getDocumentUrl("aadhar", true),
            ),
            _filePicker(
              label: "Aadhaar Card (Back)",
              docType: "aadhar",
              isFront: false,
              fileUrl: getDocumentUrl("aadhar", false),
            ),
            _filePicker(
              label: "Police Verification (Front)",
              docType: "police_verification",
              isFront: true,
              fileUrl: getDocumentUrl("police_verification", true),
            ),
            _filePicker(
              label: "Police Verification (Back)",
              docType: "police_verification",
              isFront: false,
              fileUrl: getDocumentUrl("police_verification", false),
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBlack,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                onPressed: uploadKycDocuments,
                child: const Text(
                  "Submit KYC",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
