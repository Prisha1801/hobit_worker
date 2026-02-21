import 'dart:io';
import 'package:dio/dio.dart';
import 'package:hobit_worker/colors/appcolors.dart';
import 'package:hobit_worker/utils/app_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import '../api_services/api_services.dart';
import '../api_services/urls.dart';
import '../auth/signup_page.dart';
import '../l10n/app_localizations.dart';
import '../models/get_profile_model.dart';
import 'package:flutter/material.dart';
import '../models/sign_up_model.dart';
import '../prefs/app_preference.dart';
import '../prefs/preference_key.dart';

class WorkerApi {
  static Future<WorkerProfileModel> getMyProfile() async {
    final token = AppPreference().getString(PreferencesKey.token);
    final res = await ApiService.getRequest(
      getPersonalInfoUrl,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return WorkerProfileModel.fromJson(res.data);
  }

  static Future updateWorker({
    required int workerId,
    required Map<String, dynamic> body,
  }) async {
    final token = AppPreference().getString(PreferencesKey.token);

    return await ApiService.putRequest(
      '/api/admin/worker/$workerId/update',
      body,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json', // 🔥 IMPORTANT
          'Content-Type': 'application/json',
        },
        followRedirects: false,
        validateStatus: (status) =>
            status != null && status < 500,
      ),
    );
  }
  static Future uploadKycDocuments({
    required int workerId,
    required String aadhaarNumber,
    required String policeNumber,
    required String aadhaarFrontPath,
    required String aadhaarBackPath,
    required String policeFrontPath,
    required String policeBackPath,
  }) async {
    final token = AppPreference().getString(PreferencesKey.token);

    FormData formData = FormData();

    /// ---------- Aadhaar ----------
    formData.fields.addAll([
      const MapEntry('id_type[]', 'aadhar'),
      MapEntry('id_number[]', aadhaarNumber),
    ]);

    formData.files.addAll([
      MapEntry(
        'id_front[]',
        await MultipartFile.fromFile(aadhaarFrontPath),
      ),
      MapEntry(
        'id_back[]',
        await MultipartFile.fromFile(aadhaarBackPath),
      ),
    ]);

    /// ---------- Police Verification ----------
    formData.fields.addAll([
      const MapEntry('id_type[]', 'police_verification'),
      MapEntry('id_number[]', policeNumber),
    ]);

    formData.files.addAll([
      MapEntry(
        'id_front[]',
        await MultipartFile.fromFile(policeFrontPath),
      ),
      MapEntry(
        'id_back[]',
        await MultipartFile.fromFile(policeBackPath),
      ),
    ]);

    return await ApiService.postRequest(
      '/api/worker/$workerId/docs',
      formData ,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',

        },
      ),
    );
  }

}

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({Key? key}) : super(key: key);

  @override
  State<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _referController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _policeIdController = TextEditingController();

  File? aadhaarFrontFile;
  File? aadhaarBackFile;
  File? policeFrontFile;
  File? policeBackFile;


  bool isLoading = true;
  WorkerProfileModel? profile;

  List<IdNameModel> categories = [];
  List<IdNameModel> services = [];
  List<IdNameModel> cities = [];
  List<IdNameModel> zones = [];
  List<IdNameModel> areas = [];

  List<IdNameModel> filteredServices = [];
  List<IdNameModel> filteredZones = [];
  List<IdNameModel> filteredAreas = [];

  List<IdNameModel> selectedCategories = [];
  List<IdNameModel> selectedServices = [];

  IdNameModel? selectedCity;
  IdNameModel? selectedZone;
  IdNameModel? selectedArea;

  List<int> categoryIds = [];
  List<int> serviceIds = [];

  List<String> availableDates = [];
  List<Map<String, String>> availableTimes = [];

  Future<void> fetchAllData() async {
    categories = await SignupApi.getCategories();
    services = await SignupApi.getServices();
    cities = await SignupApi.getCities();
    zones = await SignupApi.getZones();
    areas = await SignupApi.getAreas();
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
      profile!.documents.firstWhere((e) => e.type == type);
      return isFront ? doc.frontUrl : doc.backUrl;
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  final ImagePicker _picker = ImagePicker();

  Future<void> pickAndUpload({
    required String docType,
    required bool isFront,
  }) async {
    final XFile? picked =
    await _picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    setState(() => isLoading = true);

    try {
      if (docType == "aadhar") {
        if (isFront) {
          aadhaarFrontFile = File(picked.path);
        } else {
          aadhaarBackFile = File(picked.path);
        }
      } else {
        if (isFront) {
          policeFrontFile = File(picked.path);
        } else {
          policeBackFile = File(picked.path);
        }
      }

      // 🔥 CALL API IMMEDIATELY
      await WorkerApi.uploadKycDocuments(
        workerId: profile!.id,
        aadhaarNumber: _aadhaarController.text,
        policeNumber: _policeIdController.text,
        aadhaarFrontPath:
        aadhaarFrontFile?.path ?? "",
        aadhaarBackPath:
        aadhaarBackFile?.path ?? "",
        policeFrontPath:
        policeFrontFile?.path ?? "",
        policeBackPath:
        policeBackFile?.path ?? "",
      );

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

  void openImagePreview(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          backgroundColor: Colors.black,
          body: Center(
            child: InteractiveViewer(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return const CircularProgressIndicator(color: Colors.white);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> fetchProfile() async {
    try {
      await fetchAllData();

      profile = await WorkerApi.getMyProfile();

      _nameController.text = profile!.name;
      _emailController.text = profile!.email;
      _mobileController.text = profile!.phone;
      _aadhaarController.text = getDocumentNumber('aadhar');
      _policeIdController.text = getDocumentNumber('police_verification');


      /// Categories
      selectedCategories = categories
          .where((c) => profile!.categories.any((pc) => pc.id == c.id))
          .toList();

      categoryIds = selectedCategories.map((e) => e.id).toList();

      /// Services
      filteredServices = services
          .where((s) => categoryIds.contains(s.categoryId))
          .toList();

      selectedServices = filteredServices
          .where((s) => profile!.services.any((ps) => ps.id == s.id))
          .toList();

      serviceIds = selectedServices.map((e) => e.id).toList();

      /// City
      selectedCity = cities.firstWhere((c) => c.id == profile!.city.id);

      /// Zones
      filteredZones = zones.where((z) => z.cityId == selectedCity!.id).toList();

      selectedZone = filteredZones.firstWhere((z) => z.id == profile!.zone.id);

      /// Areas
      filteredAreas = areas.where((a) => a.zoneId == selectedZone!.id).toList();

      selectedArea = filteredAreas.firstWhere((a) => a.id == profile!.area?.id);

      /// Availability
      if (profile!.workerAvailability.isNotEmpty) {
        final av = profile!.workerAvailability.first;
        availableDates = List.from(av.availableDates);

        availableTimes = av.availableTimes
            .map((e) => {"start": e.start, "end": e.end})
            .toList();
      }

      setState(() => isLoading = false);
    } catch (e) {
      debugPrint("Profile error: $e");
      setState(() => isLoading = false);
    }
  }


  /// For both categories and services, we can use the same multi-select bottom sheet
  // Future<void> showMultiSelectSheet({
  //   required String title,
  //   required List<IdNameModel> items,
  //   required List<IdNameModel> selectedItems,
  //   required Function(List<IdNameModel>) onDone,
  // }) async {
  //   final tempSelected = List<IdNameModel>.from(selectedItems);
  //
  //   await showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  //     ),
  //     builder: (_) {
  //       return StatefulBuilder(
  //         builder: (context, setModalState) {
  //           return Padding(
  //             padding: const EdgeInsets.all(16),
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(title,
  //                     style: const TextStyle(
  //                         fontSize: 16, fontWeight: FontWeight.w600)),
  //                 const SizedBox(height: 12),
  //
  //                 Expanded(
  //                   child: ListView.builder(
  //                     itemCount: items.length,
  //                     itemBuilder: (_, index) {
  //                       final item = items[index];
  //                       final isChecked =
  //                       tempSelected.any((e) => e.id == item.id);
  //
  //                       return CheckboxListTile(
  //                         value: isChecked,
  //                         title: Text(item.name),
  //                         onChanged: (val) {
  //                           setModalState(() {
  //                             if (val == true) {
  //                               tempSelected.add(item);
  //                             } else {
  //                               tempSelected
  //                                   .removeWhere((e) => e.id == item.id);
  //                             }
  //                           });
  //                         },
  //                       );
  //                     },
  //                   ),
  //                 ),
  //
  //                 SizedBox(
  //                   width: double.infinity,
  //                   child: ElevatedButton(
  //                     onPressed: () {
  //                       onDone(tempSelected);
  //                       Navigator.pop(context);
  //                     },
  //                     child: const Text("Done"),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  /// For both categories and services, we can use the same multi-select bottom sheet
  Future<void> showMultiSelectSheet({
    required String title,
    required List<IdNameModel> items,
    required List<IdNameModel> selectedItems,
    required Function(List<IdNameModel>) onDone,
    String emptyMessage = "No data available",
  }) async {
    final loc = AppLocalizations.of(context)!;

    final tempSelected = List<IdNameModel>.from(selectedItems);

    await showModalBottomSheet(
      backgroundColor: kWhite,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 35),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                if (items.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        emptyMessage,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (_, index) {
                        final item = items[index];
                        final isSelected = tempSelected.any(
                          (e) => e.id == item.id,
                        );

                        return ListTile(
                          title: Text(item.name),
                          trailing: isSelected
                              ? const Icon(Icons.check, color: kBlack)
                              : null,
                          onTap: () {
                            setModalState(() {
                              if (isSelected) {
                                tempSelected.removeWhere(
                                  (e) => e.id == item.id,
                                );
                              } else {
                                tempSelected.add(item);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    height: 48,
                    width: double.infinity,

                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: kBlack, shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5), // 🔥 Radius 5
                      ),),
                      onPressed: () {
                        onDone(tempSelected);
                        Navigator.pop(context);
                      },
                      child: Text(loc.done, style: const TextStyle(color: kWhite),),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// For City, Zone, Area selection - single select bottom sheet
  Future<IdNameModel?> showSingleSelectSheet({
    required String title,
    required List<IdNameModel> items,
    IdNameModel? selectedItem,
    String emptyMessage = "No data available",
  }) async {
    return await showModalBottomSheet<IdNameModel>(
      context: context,
      backgroundColor: kWhite,
      isScrollControlled: true, // 🔥 IMPORTANT
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 24,
          ),
          child: Column(
            children: [
              /// Header
              SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      emptyMessage,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                )
              else
                /// List
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (_, index) {
                      final item = items[index];
                      final isSelected = selectedItem?.id == item.id;

                      return ListTile(
                        title: Text(item.name),
                        trailing: isSelected
                            ? const Icon(Icons.check, color: kBlack)
                            : null,
                        onTap: () {
                          Navigator.pop(context, item);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }


  /// For adding availability dates - show date picker and maintain list of selected dates
  Future<void> addAvailabilityDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      final formatted =
          "${pickedDate.year.toString().padLeft(4, '0')}-"
          "${pickedDate.month.toString().padLeft(2, '0')}-"
          "${pickedDate.day.toString().padLeft(2, '0')}";

      if (!availableDates.contains(formatted)) {
        setState(() {
          availableDates.add(formatted);
        });
      }
    }
  }

  Future<void> showAvailabilityDatesSheet() async {
    final loc = AppLocalizations.of(context)!;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              children: [
                const SizedBox(height: 20),
                Text(
                loc.selectAvailableDates,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: availableDates.isEmpty
                      ? Center(
                    child: Text(
                      loc.noDatesAdded,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                      : ListView.builder(
                    itemCount: availableDates.length,
                    itemBuilder: (_, index) {
                      return ListTile(
                        title: Text(availableDates[index]),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setModalState(() {
                              availableDates.removeAt(index);
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () async {
                            await addAvailabilityDate();
                            setModalState(() {});
                          },
                          child: Text(loc.addDate),
                        ),
                      ),
                      const SizedBox(height: 8),
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
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            loc.done,
                            style: const TextStyle(color: kWhite),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
  String formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  Future<Map<String, String>?> pickTimeSlot() async {
    final start = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (start == null) return null;

    final end = await showTimePicker(
      context: context,
      initialTime: start,
    );
    if (end == null) return null;

    // return {
    //   "start": start.format(context),
    //   "end": end.format(context),
    // };
    return {
      "start": formatTimeOfDay(start), // ✅ HH:mm
      "end": formatTimeOfDay(end),     // ✅ HH:mm
    };
  }

  Future<void> showAvailabilityTimeSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        final loc = AppLocalizations.of(context)!;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  loc.selectTimeSlots,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: availableTimes.isEmpty
                      ? Center(
                    child: Text(
            loc.noTimeSlots,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                      : ListView.builder(
                    itemCount: availableTimes.length,
                    itemBuilder: (_, index) {
                      final slot = availableTimes[index];
                      return ListTile(
                        title:
                        Text("${slot['start']} - ${slot['end']}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setModalState(() {
                              availableTimes.removeAt(index);
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () async {
                            final slot = await pickTimeSlot();
                            if (slot != null) {
                              setModalState(() {
                                availableTimes.add(slot);
                              });
                            }
                          },
                          child: Text(loc.addTimeSlot),
                        ),
                      ),
                      const SizedBox(height: 8),
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
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Done",
                            style: TextStyle(color: kWhite),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }


  /// For City, Zone, Area selection - single select bottom sheet
  // Future<IdNameModel?> showSingleSelectSheet({
  //   required String title,
  //   required List<IdNameModel> items,
  //   IdNameModel? selectedItem,
  // }) async {
  //   return await showModalBottomSheet<IdNameModel>(
  //     context: context,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  //     ),
  //     builder: (_) {
  //       return Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           const SizedBox(height: 12),
  //           Text(title,
  //               style:
  //               const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
  //           const SizedBox(height: 12),
  //
  //           Flexible(
  //             child: ListView.builder(
  //               shrinkWrap: true,
  //               itemCount: items.length,
  //               itemBuilder: (_, index) {
  //                 final item = items[index];
  //                 final isSelected = selectedItem?.id == item.id;
  //
  //                 return ListTile(
  //                   title: Text(item.name),
  //                   trailing: isSelected
  //                       ? const Icon(Icons.check, color: Colors.green)
  //                       : null,
  //                   onTap: () => Navigator.pop(context, item),
  //                 );
  //               },
  //             ),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  Future<void> updateProfile() async {
    final loc = AppLocalizations.of(context)!;

    final body = {
      "name": _nameController.text,
      "email": _emailController.text,
      "phone": _mobileController.text,
      "category_ids": categoryIds,
      "service_ids": serviceIds,
      "is_active": profile!.isActive,
      "city_id": selectedCity?.id,
      "zone_id": selectedZone?.id,
      "area_id": selectedArea?.id,


      "available_dates": availableDates.isNotEmpty
          ? availableDates
          : profile!.workerAvailability.first.availableDates,

      "available_times": availableTimes.isNotEmpty
          ? availableTimes
          : profile!.workerAvailability.first.availableTimes
                .map((e) => {"start": e.start, "end": e.end})
                .toList(),
    };

    try {
      setState(() {
        isLoading = true; // 🔥 PAGE REFRESH START
      });
      await WorkerApi.updateWorker(workerId: profile!.id, body: body);
      await fetchProfile();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.profileUpdated)),
      );
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Update error: $e");
    }
  }

  Future<void> uploadKyc() async {
      final loc = AppLocalizations.of(context)!;
    if (aadhaarFrontFile == null ||
        aadhaarBackFile == null ||
        policeFrontFile == null ||
        policeBackFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.uploadAllDocs)),
      );
      return;
    }

    try {
      setState(() => isLoading = true);

      await WorkerApi.uploadKycDocuments(
        workerId: profile!.id,
        aadhaarNumber: _aadhaarController.text,
        policeNumber: _policeIdController.text,
        aadhaarFrontPath: aadhaarFrontFile!.path,
        aadhaarBackPath: aadhaarBackFile!.path,
        policeFrontPath: policeFrontFile!.path,
        policeBackPath: policeBackFile!.path,
      );

      await fetchProfile(); // 🔥 documents refresh

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.kycUploaded)),
      );
    } catch (e) {
      debugPrint("KYC Upload Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ---------------- UI HELPERS ----------------

  Widget _buildInput({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hint,
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

  Widget _buildDropdown({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          child: Container(
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
                    value.isEmpty ? 'Select $label' : value,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAvailability() {
    final loc = AppLocalizations.of(context)!;

    if (profile!.workerAvailability.isEmpty) {
      return Text(loc.noAvailability);
    }

    final availability = profile!.workerAvailability.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Text(
    loc.workerAvailability,
    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        _buildDropdown(
          label: loc.availableDates,
          value: availableDates.join(', '),
          onTap: showAvailabilityDatesSheet,
        ),

        _buildDropdown(
          label: loc.availableTimeSlots,
          value: availableTimes
              .map((e) => "${e['start']} - ${e['end']}")
              .join(', '),
          onTap: showAvailabilityTimeSheet,
        ),

      ],
    );
  }

  /// File Picker Widget
  Widget _filePicker({
    required String label,
    required String docType,
    required bool isFront,
    String? fileUrl,
  }) {
    final loc = AppLocalizations.of(context)!;

    final hasFile = fileUrl != null && fileUrl.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
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
                  hasFile ? loc.documentUploaded : loc.uploadDocument,
                  style: TextStyle(
                    color: hasFile ? Colors.black : Colors.grey,
                  ),
                ),
              ),

              /// 👁 Preview
              if (hasFile)
                IconButton(
                  icon: const Icon(Icons.visibility, color: kBlack),
                  onPressed: () => openImagePreview(fileUrl!),
                ),

              /// ⬆ Upload Icon
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


  // Widget _filePicker({
  //   required String label,
  //   String? fileUrl,
  // }) {
  //   final hasFile = fileUrl != null && fileUrl.isNotEmpty;
  //
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         label,
  //         style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
  //       ),
  //       const SizedBox(height: 6),
  //       Container(
  //         height: 48,
  //         padding: const EdgeInsets.symmetric(horizontal: 12),
  //         decoration: BoxDecoration(
  //           color: const Color(0xFFF6F7FF),
  //           borderRadius: BorderRadius.circular(8),
  //         ),
  //         child: Row(
  //           children: [
  //             Expanded(
  //               child: Text(
  //                 hasFile ? "Document uploaded" : "Choose file",
  //                 style: TextStyle(
  //                   color: hasFile ? Colors.black : Colors.grey,
  //                 ),
  //               ),
  //             ),
  //
  //             if (hasFile)
  //               IconButton(
  //                 icon: const Icon(Icons.visibility, color: kBlack),
  //                 onPressed: () => openImagePreview(fileUrl),
  //               )
  //             else
  //               const Icon(Icons.upload_file),
  //           ],
  //         ),
  //       ),
  //       const SizedBox(height: 16),
  //     ],
  //   );
  // }

  // Widget _filePicker(String label) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         label,
  //         style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
  //       ),
  //       const SizedBox(height: 6),
  //       Container(
  //         height: 48,
  //         padding: const EdgeInsets.symmetric(horizontal: 12),
  //         decoration: BoxDecoration(
  //           color: const Color(0xFFF6F7FF),
  //           borderRadius: BorderRadius.circular(8),
  //         ),
  //         child: Row(
  //           children: const [
  //             Expanded(
  //               child: Text(
  //                 "Choose file",
  //                 style: TextStyle(color: Colors.grey),
  //               ),
  //             ),
  //             Icon(Icons.upload_file),
  //           ],
  //         ),
  //       ),
  //       const SizedBox(height: 16),
  //     ],
  //   );
  // }

  // ---------------- BUILD ----------------

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (isLoading) {
      return Scaffold(
        backgroundColor: kWhite,
        appBar: CommonAppBar(title: loc.personalInformation),
        body: const PersonalInfoShimmer(),
      );
    }


    return Scaffold(
      backgroundColor: kWhite,
      appBar: CommonAppBar(title: loc.personalInformation),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),

            /// PROFILE CARD
            SizedBox(
              width:
                  MediaQuery.of(context).size.width -
                  40, // left + right padding
              height: 125,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0x0D000000)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 4,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// TOP LABEL
                    Text(
                      loc.profilePhoto,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 12),

                    /// AVATAR + NAME
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 46,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                          child: const Icon(Icons.person, size: 26),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            profile!.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            Text(
                loc.basicInformation,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 12),
            _buildInput(
              label: loc.name,
              hint: loc.name,
              controller: _nameController,
            ),
            _buildInput(
              label: loc.email,
              hint: loc.email,
              controller: _emailController,
            ),
            _buildInput(
              label: loc.mobile,
              hint: loc.mobile,
              controller: _mobileController,
            ),
            // _buildInput(
            //   label: "Refer By",
            //   hint: "Refer Code",
            //   controller: _referController,
            //   readOnly: true,
            // ),
            _buildDropdown(
              label: loc.categories,
              value: selectedCategories.map((e) => e.name).join(', '),
              onTap: () async {
                if (categories.isEmpty) {
                  categories = await SignupApi.getCategories();
                }

                showMultiSelectSheet(
                  title: "Select Categories",
                  items: categories,
                  selectedItems: selectedCategories,
                  onDone: (list) {
                    setState(() {
                      selectedCategories = list;
                      categoryIds = list.map((e) => e.id).toList();

                      // filter services based on selected categories
                      filteredServices = services
                          .where((s) => categoryIds.contains(s.categoryId))
                          .toList();

                      selectedServices.clear();
                      serviceIds.clear();
                    });
                  },
                );
              },
            ),

            _buildDropdown(
              label: loc.services,
              value: selectedServices.map((e) => e.name).join(', '),
              onTap: () async {
                if (services.isEmpty) {
                  services = await SignupApi.getServices();
                }

                showMultiSelectSheet(
                  title: "Select Services",
                  items: filteredServices,
                  selectedItems: selectedServices,
                  onDone: (list) {
                    setState(() {
                      selectedServices = list;
                      serviceIds = list.map((e) => e.id).toList();
                    });
                  },
                );
              },
            ),

            _buildDropdown(
              label: loc.availabilityStatus,
              value: profile!.isActive == 1 ? "Available" : "Unavailable",
               //onTap: () {},
                onTap: () {
                  showSingleSelectSheet(
                    title: "Select Availability",
                    items:  [
                      IdNameModel(id: 1, name: "Available"),
                      IdNameModel(id: 0, name: "Unavailable"),
                    ],
                    selectedItem: profile!.isActive == 1
                        ? IdNameModel(id: 1, name: "Available")
                        : IdNameModel(id: 0, name: "Unavailable"),
                  )
                      .then((result) {
                    if (result != null) {
                      setState(() {
                        profile = WorkerProfileModel(
                          id: profile!.id,
                          workerId: profile!.workerId,
                          name: profile!.name,
                          email: profile!.email,
                          phone: profile!.phone,
                          isActive: result.id,
                          isAssigned: profile!.isAssigned,
                          categories: profile!.categories,
                          services: profile!.services,
                          city: profile!.city,
                          zone: profile!.zone,
                          area: profile!.area,
                          walletBalance: profile!.walletBalance,
                          kycStatus: profile!.kycStatus,
                          documents: profile!.documents,
                          workerAvailability:
                          profile!.workerAvailability,
                          averageRatings:
                          profile!.averageRatings,
                          ratingCount:
                          profile!.ratingCount,
                          jobsCompleted: profile!.jobsCompleted,
                        );
                      });
                    }
                  });
              },
            ),

            _buildDropdown(
              label: loc.city,
              value: selectedCity?.name ?? "Select City",
              onTap: () async {
                if (cities.isEmpty) {
                  cities = await SignupApi.getCities();
                }

                final result = await showSingleSelectSheet(
                  title: "Select City",
                  items: cities,
                  selectedItem: selectedCity,
                );

                if (result != null) {
                  setState(() {
                    selectedCity = result;

                    // reset dependent fields
                    selectedZone = null;
                    selectedArea = null;

                    filteredZones = zones
                        .where((z) => z.cityId == selectedCity!.id)
                        .toList();
                    filteredAreas = [];
                  });
                }
              },
            ),

            // _buildDropdown("Zone", profile!.zone.name),
            _buildDropdown(
              label: loc.zone,
              value: selectedZone?.name ?? "Select Zone",
              onTap: () async {
                if (selectedCity == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please select city first")),
                  );
                  return;
                }

                final result = await showSingleSelectSheet(
                  title: "Select Zone",
                  items: filteredZones,
                  selectedItem: selectedZone,
                );

                if (result != null) {
                  setState(() {
                    selectedZone = result;

                    // reset area
                    selectedArea = null;
                    filteredAreas = areas
                        .where((a) => a.zoneId == selectedZone!.id)
                        .toList();
                  });
                }
              },
            ),

            // _buildDropdown("Serviceable Area", profile!.area?.name ?? ""),
            _buildDropdown(
              label: loc.area,
              value: selectedArea?.name ?? "Select Area",
              onTap: () async {
                if (selectedZone == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please select zone first")),
                  );
                  return;
                }

                final result = await showSingleSelectSheet(
                  title: "Select Area",
                  items: filteredAreas,
                  selectedItem: selectedArea,
                );

                if (result != null) {
                  setState(() {
                    selectedArea = result;
                  });
                }
              },
            ),

            const SizedBox(height: 8),

            /// AVAILABILITY SECTION
            _buildAvailability(),

            const SizedBox(height: 8),
            Text(
              loc.kycDetails,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 12),
            _buildInput(
              label: loc.aadhaarNumber,
              hint: loc.enterAadhaarNumber,
              controller: _aadhaarController,
            ),
            _buildInput(
              label: loc.policeId,
              hint: loc.enterPoliceId,
              controller: _policeIdController,
            ),

            _filePicker(
              label: loc.aadhaarFront,
              docType: "aadhar",
              isFront: true,
              fileUrl: getDocumentUrl("aadhar", true),
            ),

            _filePicker(
              label: loc.aadhaarBack,
              docType: "aadhar",
              isFront: false,
              fileUrl: getDocumentUrl("aadhar", false),
            ),

            _filePicker(
              label: loc.policeFront,
              docType: "police_verification",
              isFront: true,
              fileUrl: getDocumentUrl("police_verification", true),
            ),

            _filePicker(
              label: loc.policeBack,
              docType: "police_verification",
              isFront: false,
              fileUrl: getDocumentUrl("police_verification", false),
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: kBlack, shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),),
                // onPressed: updateProfile,
                onPressed: () async {
                  await updateProfile();
                  await uploadKyc();
                },

                child: Text(
                    loc.saveChanges,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}



/// Shimmer Widget for loading state

class PersonalInfoShimmer extends StatelessWidget {
  const PersonalInfoShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            /// 🔹 PROFILE CARD SHIMMER
            Container(
              height: 125,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kWhite,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _shimmerBox(height: 16, width: 120),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          color: kWhite,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _shimmerBox(height: 14)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// 🔹 SECTION TITLE
            _shimmerBox(height: 14, width: 140),
            const SizedBox(height: 12),

            /// 🔹 INPUT FIELDS SHIMMER
            for (int i = 0; i < 6; i++) ...[
              _shimmerBox(height: 14, width: 100),
              const SizedBox(height: 6),
              _shimmerBox(height: 48),
              const SizedBox(height: 16),
            ],

            /// 🔹 BUTTON SHIMMER
            _shimmerBox(
              height: 48,
              radius: BorderRadius.circular(5),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// 🔸 COMMON SHIMMER BOX
  Widget _shimmerBox({
    double height = 16,
    double width = double.infinity,
    BorderRadius? radius,
  }) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: radius ?? BorderRadius.circular(8),
      ),
    );
  }
}
