import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api_services/api_services.dart';
import '../api_services/urls.dart';
import '../colors/appcolors.dart';
import '../l10n/app_localizations.dart';
import '../models/sign_up_model.dart';
import 'login_page.dart';

class SignupApi {

  static Future<List<IdNameModel>> getCategories() async {
    final res = await ApiService.getRequest(serviceCategoriesUrl);
    return (res.data as List)
        .map((e) => IdNameModel.fromJson(e))
        .toList();
  }

  static Future<List<IdNameModel>> getServices() async {
    final res = await ApiService.getRequest(serviceUrl);
    return (res.data as List)
        .map((e) => IdNameModel.fromJson(e))
        .toList();
  }

  static Future<List<IdNameModel>> getCities() async {
    final res = await ApiService.getRequest(citiesUrl);
    return (res.data as List)
        .map((e) => IdNameModel.fromJson(e))
        .toList();
  }

  static Future<List<IdNameModel>> getZones() async {
    final res = await ApiService.getRequest(zonesUrl);
    return (res.data as List)
        .map((e) => IdNameModel.fromJson(e))
        .toList();
  }

  static Future<List<IdNameModel>> getAreas() async {
    final res = await ApiService.getRequest(serviceAreaUrl);
    return (res.data as List)
        .map((e) => IdNameModel.fromJson(e))
        .toList();
  }

  static Future registerWorker(Map<String, dynamic> body) async {
    return await ApiService.postRequest(
      signUpUrl,
      body,
    );

  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // Controllers
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _refer = TextEditingController();
  final _date = TextEditingController();
  final _time = TextEditingController();

  void showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(child: Text(msg)),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
  bool validateForm() {
    if (_name.text.trim().isEmpty) {
      showSnack("Please enter your name");
      return false;
    }

    if (_email.text.trim().isEmpty) {
      showSnack("Please enter your email");
      return false;
    }

    if (!_email.text.contains("@")) {
      showSnack("Please enter valid email");
      return false;
    }

    if (_phone.text.trim().isEmpty) {
      showSnack("Please enter phone number");
      return false;
    }

    if (_phone.text.length < 10) {
      showSnack("Phone number must be 10 digits");
      return false;
    }

    if (_password.text.trim().isEmpty) {
      showSnack("Please enter password");
      return false;
    }

    if (_password.text.length < 6) {
      showSnack("Password must be at least 6 characters");
      return false;
    }

    if (selectedCategories.isEmpty) {
      showSnack("Please select at least one category");
      return false;
    }

    if (selectedServices.isEmpty) {
      showSnack("Please select at least one service");
      return false;
    }

    if (selectedCity == null) {
      showSnack("Please select city");
      return false;
    }

    if (selectedZone == null) {
      showSnack("Please select zone");
      return false;
    }

    if (selectedArea == null) {
      showSnack("Please select area");
      return false;
    }

    if (availableDates.isEmpty) {
      showSnack("Please select available dates");
      return false;
    }

    if (availableTimes.isEmpty) {
      showSnack("Please select available time slots");
      return false;
    }

    if (!accept) {
      showSnack("Please accept Terms & Conditions");
      return false;
    }

    return true;
  }


  bool obscure = true;
  bool accept = false;
  bool loading = false;

  // Data
  List<IdNameModel> categories = [];
  List<IdNameModel> services = [];
  List<IdNameModel> filteredServices = [];

  List<IdNameModel> cities = [];
  List<IdNameModel> zones = [];
  List<IdNameModel> areas = [];

  List<IdNameModel> filteredZones = [];
  List<IdNameModel> filteredAreas = [];

  // Selected
  List<IdNameModel> selectedCategories = [];
  // IdNameModel? selectedService;
  List<IdNameModel> selectedServices = [];
  bool serviceOpen = false;

  IdNameModel? selectedCity;
  IdNameModel? selectedZone;
  IdNameModel? selectedArea;

  bool categoryOpen = false;

  List<int> categoryIds = [];
  List<int> serviceIds = [];

  int isActive = 1;

  List<String> availableDates = [];
  List<Map<String, String>> availableTimes = [];

  void filterZonesByCity() {
    if (selectedCity == null) {
      filteredZones = [];
      filteredAreas = [];
      selectedZone = null;
      selectedArea = null;
      return;
    }

    filteredZones =
        zones.where((z) => z.cityId == selectedCity!.id).toList();

    selectedZone = null;
    selectedArea = null;
    filteredAreas = [];

    setState(() {});
  }

  void filterAreasByZone() {
    if (selectedZone == null) {
      filteredAreas = [];
      selectedArea = null;
      return;
    }

    filteredAreas =
        areas.where((a) => a.zoneId == selectedZone!.id).toList();

    selectedArea = null;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    categories = await SignupApi.getCategories();
    services = await SignupApi.getServices();
    cities = await SignupApi.getCities();
    zones = await SignupApi.getZones();
    areas = await SignupApi.getAreas();
    setState(() {});
  }

  void filterServices() {
    final ids = selectedCategories.map((e) => e.id).toList();

    filteredServices =
        services.where((s) => ids.contains(s.categoryId)).toList();

    // ❗ Reset invalid selected services
    selectedServices.removeWhere(
          (s) => !filteredServices.contains(s),
    );

    serviceIds = selectedServices.map((e) => e.id).toList();
  }



  Widget serviceMultiDropdown() {
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.services),
        const SizedBox(height: 6),

        GestureDetector(
          onTap: () => setState(() => serviceOpen = !serviceOpen),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedServices.isEmpty
                        ? loc.selectServices
                        : selectedServices.map((e) => e.name).join(", "),
                    style: TextStyle(
                      color: selectedServices.isEmpty
                          ? Colors.grey
                          : Colors.black,
                    ),
                  ),
                ),
                Icon(serviceOpen
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down),
              ],
            ),
          ),
        ),

        if (serviceOpen)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: filteredServices.map((s) {
                final selected = selectedServices.contains(s);
                return CheckboxListTile(
                  dense: true,
                  title: Text(s.name),
                  value: selected,
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        selectedServices.add(s);
                      } else {
                        selectedServices.remove(s);
                      }
                      serviceIds =
                          selectedServices.map((e) => e.id).toList();
                    });
                  },
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  // UI helpers
  Widget input(String label, TextEditingController c,
      {String? hint, bool readOnly = false, VoidCallback? onTap, Widget? suffix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffix,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget dropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    String? hint,
    required Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          dropdownColor: kWhite,
          value: value,
          hint: hint != null ? Text(hint) : null, // 👈 ADD
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget categoryMultiDropdown() {
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.category),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => setState(() => categoryOpen = !categoryOpen),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedCategories.isEmpty
                        ? loc.selectCategories
                        : selectedCategories.map((e) => e.name).join(", "),
                    style: TextStyle(
                      color: selectedCategories.isEmpty
                          ? Colors.grey
                          : Colors.black,
                    ),
                  ),
                ),
                Icon(categoryOpen
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down),
              ],
            ),
          ),
        ),
        if (categoryOpen)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: categories.map((c) {
                final selected = selectedCategories.contains(c);
                return CheckboxListTile(
                  dense: true,
                  title: Text(c.name),
                  value: selected,
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        selectedCategories.add(c);
                      } else {
                        selectedCategories.remove(c);
                      }
                      categoryIds =
                          selectedCategories.map((e) => e.id).toList();
                      filterServices();
                    });
                  },
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> pickDate() async {
    final d = await showDatePicker(

      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      initialDate: DateTime.now(),
    );

    if (d != null) {
      final f = DateFormat("yyyy-MM-dd").format(d);
      if (!availableDates.contains(f)) {
        availableDates.add(f);
        _date.text = availableDates.join(", ");
      }
    }
  }

  String formatTime(TimeOfDay t) {
    final now = DateTime.now();
    return DateFormat("HH:mm")
        .format(DateTime(now.year, now.month, now.day, t.hour, t.minute));
  }

  Future<void> pickTime() async {
    final s = await showTimePicker(
        context: context, initialTime: TimeOfDay.now());
    if (s == null) return;
    final e = await showTimePicker(context: context, initialTime: s);
    if (e == null) return;

    availableTimes.add({
      "start": formatTime(s),
      "end": formatTime(e),
    });

    _time.text = availableTimes
        .map((e) => "${e['start']} - ${e['end']}")
        .join(", ");
  }

  Future<void> register() async {
    if (!validateForm()) return;

    final body = {
      "name": _name.text,
      "email": _email.text,
      "phone": _phone.text,
      "password": _password.text,
      "category_ids": categoryIds,
      "service_ids": serviceIds,
      "city_id": selectedCity?.id,
      "zone_id": selectedZone?.id,
      "area_id": selectedArea?.id,
      "is_active": isActive,
      "available_dates": availableDates,
      "available_times": availableTimes,
    };

    if (_refer.text.trim().isNotEmpty) {
      final v = _refer.text.trim();
      body[v.startsWith("HOBIT") ? "ref" : "refer_by"] = v;
    }

    setState(() => loading = true);

    try {
      await SignupApi.registerWorker(body);
      showSnack("Registration successful");

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
    } catch (e) {
      if (e is ApiException) {
        final data = e.details;

        if (data is Map && data["errors"] != null) {
          final errors = data["errors"];

          if (errors["email"] != null && errors["email"].isNotEmpty) {
            showSnack(errors["email"][0]);
          } else if (errors["phone"] != null && errors["phone"].isNotEmpty) {
            showSnack(errors["phone"][0]);
          } else {
            showSnack(data["message"] ?? e.message);
          }
        } else {
          showSnack(e.message);
        }
      } else {
        showSnack("Email or phone already exists");
      }
    }
    setState(() => loading = false);
  }

  // Future<void> register() async {
  //   final body = {
  //     "name": _name.text,
  //     "email": _email.text,
  //     "phone": _phone.text,
  //     "password": _password.text,
  //     "category_ids": categoryIds,
  //     "service_ids": serviceIds,
  //     "city_id": selectedCity?.id,
  //     "zone_id": selectedZone?.id,
  //     "area_id": selectedArea?.id,
  //     "is_active": isActive,
  //     "available_dates": availableDates,
  //     "available_times": availableTimes,
  //   };
  //
  //   if (_refer.text.trim().isNotEmpty) {
  //     final v = _refer.text.trim();
  //     body[v.startsWith("HOBIT") ? "ref" : "refer_by"] = v;
  //   }
  //
  //   setState(() => loading = true);
  //   await SignupApi.registerWorker(body);
  //   setState(() => loading = false);
  //
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(builder: (_) => const LocationPermissionScreen()),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: kWhite,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text(loc.signUp, style: const TextStyle(fontSize: 22)),
            input(loc.name, _name, hint: loc.enterFullName),
            input(loc.email, _email, hint: "example@gmail.com"),
            input(loc.phone, _phone, hint: "10 digit mobile number"),

            input(
             loc.password,
              _password,

              suffix: IconButton(
                icon:
                Icon(obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => obscure = !obscure),
              ),
                hint:loc.minPassword
            ),

            categoryMultiDropdown(),
            serviceMultiDropdown(),
            dropdown(
              label: loc.availability,
              value: isActive,
              items: [
                DropdownMenuItem(value: 1, child: Text(loc.available)),
                DropdownMenuItem(value: 0, child: Text(loc.unavailable)),
              ],
              onChanged: (v) => setState(() => isActive = v!),
            ),

            input(loc.referCode, _refer, hint: loc.referHint),

            dropdown(
              label: loc.city,
              hint: loc.selectCity,
              value: selectedCity,
              items: cities
                  .map((e) =>
                  DropdownMenuItem(value: e, child: Text(e.name)))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  selectedCity = v;
                });
                filterZonesByCity();
              },
            ),

            dropdown(
              label: loc.zone,
              hint: loc.selectZone,
              value: selectedZone,
              items: filteredZones
                  .map((e) =>
                  DropdownMenuItem(value: e, child: Text(e.name)))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  selectedZone = v;
                });
                filterAreasByZone();
              },
            ),

            dropdown(
              label: loc.area,
              hint: loc.selectArea,
              value: selectedArea,
              items: filteredAreas
                  .map((e) =>
                  DropdownMenuItem(value: e, child: Text(e.name)))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  selectedArea = v;
                });
              },
            ),
            input(loc.availableDates, _date,
                hint: loc.selectDates,
                readOnly: true,
                onTap: pickDate,
                suffix: const Icon(Icons.calendar_today)),

            input(loc.availableTimeSlots, _time,
                hint: loc.selectTimeSlots,
                readOnly: true,
                onTap: pickTime,
                suffix: const Icon(Icons.access_time)),
            Row(
              children: [
                Checkbox(
                    value: accept,
                    onChanged: (v) => setState(() => accept = v!)),
                Expanded(child: Text(loc.acceptTerms)),
              ],
            ),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kkblack,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: loading ? null : register,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(loc.signUp,   style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),),
              ),
            ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(loc.haveAccount),
                GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen())),
                  child:
                  Text(loc.login, style: TextStyle(color: kkblack)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
