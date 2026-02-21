import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:hobit_worker/utils/app_bar.dart';
import '../api_services/api_services.dart';
import '../api_services/urls.dart';
import '../l10n/app_localizations.dart';
import '../prefs/app_preference.dart';
import '../prefs/preference_key.dart';
import 'package:shimmer/shimmer.dart';

class AddBankScreen extends StatefulWidget {
  const AddBankScreen({Key? key}) : super(key: key);

  @override
  State<AddBankScreen> createState() => _AddBankScreenState();
}

class _AddBankScreenState extends State<AddBankScreen> {
  final _accountHolderController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _ifscController = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getBankDetails();
  }

  @override
  void dispose() {
    _accountHolderController.dispose();
    _accountNumberController.dispose();
    _bankNameController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  /// 🔹 GET BANK DETAILS
  Future<void> getBankDetails() async {
    setState(() => isLoading = true);

    try {
      final token = AppPreference().getString(PreferencesKey.token);

      final res = await ApiService.getRequest(
        getBankDetailsUrl,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      );

      final data = res.data;

      if (data != null && data["status"] == true) {
        final bank = data["data"];

        _accountHolderController.text =
            bank["account_holder_name"] ?? "";
        _accountNumberController.text =
            bank["account_no"] ?? "";
        _bankNameController.text =
            bank["bank_name"] ?? "";
        _ifscController.text =
            bank["ifsc_code"] ?? "";
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// 🔹 UPDATE BANK DETAILS
  Future<void> updateBankDetails() async {
    final loc = AppLocalizations.of(context)!;
    if (_accountHolderController.text.isEmpty ||
        _accountNumberController.text.isEmpty ||
        _bankNameController.text.isEmpty ||
        _ifscController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.fillAllFields)),
      );

      return;
    }

    setState(() => isLoading = true);

    try {
      final token = AppPreference().getString(PreferencesKey.token);

      final res = await ApiService.putRequest(
        putBankDetailsUrl,
        {
          "account_holder_name":
          _accountHolderController.text.trim(),
          "account_no":
          _accountNumberController.text.trim(),
          "bank_name":
          _bankNameController.text.trim(),
          "ifsc_code":
          _ifscController.text.trim(),
        },
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      );

      final data = res.data;

      if (data != null && data["status"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data["message"] ?? "Bank details updated",
            ),
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// 🔹 COMMON INPUT FIELD
  Widget _buildInput({
    required String label,
    required String hint,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(title: loc.addBank ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    /// 🔹 CARD
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0D000000),
                            offset: Offset(0, 4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: isLoading
                          ? bankFormShimmer()
                          : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              loc.addBankTitle,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          _buildInput(
                            label: loc.accountHolderName,
                            hint: loc.accountHolderHint,
                            controller: _accountHolderController,
                          ),
                          _buildInput(
                            label:loc.accountNumber,
                            hint: loc.accountNumberHint,
                            controller: _accountNumberController,
                          ),
                          _buildInput(
                            label: loc.bankName,
                            hint: loc.bankNameHint,
                            controller: _bankNameController,
                          ),
                          _buildInput(
                            label: loc.ifscCode,
                            hint: loc.ifscCodeHint,
                            controller: _ifscController,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 50,),
                    /// 🔹 SAVE BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed:
                        isLoading ? null : updateBankDetails,
                        child: isLoading
                            ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                            : Text(
                          loc.save,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

}


Widget bankFormShimmer() {
  return Shimmer.fromColors(
    baseColor: Colors.grey.shade300,
    highlightColor: Colors.grey.shade100,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(4, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 12,
                width: 140,
                color: Colors.white,
              ),
              const SizedBox(height: 8),
              Container(
                height: 48,
                width: double.infinity,
                color: Colors.white,
              ),
            ],
          ),
        );
      }),
    ),
  );
}
