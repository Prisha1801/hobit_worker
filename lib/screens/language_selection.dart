//
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:hobit_worker/colors/appcolors.dart';
// import '../l10n/app_localizations.dart';
// import '../language_selection/language_provider.dart';
// import '../utils/app_bar.dart';
//
// class LanguageSelectionScreen extends ConsumerStatefulWidget {
//   const LanguageSelectionScreen({Key? key}) : super(key: key);
//
//   @override
//   ConsumerState<LanguageSelectionScreen> createState() =>
//       _LanguageSelectionScreenState();
// }
//
// class _LanguageSelectionScreenState
//     extends ConsumerState<LanguageSelectionScreen> {
//
//   String selectedLanguage = "";
//
//   final List<Map<String, String>> languages = [
//     {"name": "English", "code": "en"},
//     {"name": "Hindi", "code": "hi"},
//     {"name": "Marathi", "code": "mr"},
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     final locale = ref.read(localeProvider);
//
//     selectedLanguage = languages.firstWhere(
//           (lang) => lang['code'] == locale.languageCode,
//       orElse: () => languages.first,
//     )['name']!;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final loc = AppLocalizations.of(context)!;
//
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: CommonAppBar(title: loc.languageSelection),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               loc.chooseLanguage,
//               style: const TextStyle(fontSize: 13, color: Colors.black54),
//             ),
//             const SizedBox(height: 20),
//
//             ...languages.map(
//                   (lang) => _languageTile(
//                 title: lang["name"]!,
//                 code: lang["code"]!,
//               ),
//             ),
//
//             const Spacer(),
//
//             SizedBox(
//               width: double.infinity,
//               height: 48,
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: kkblack,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 onPressed: () => Navigator.pop(context),
//                 child: Text(loc.save,
//                   style: TextStyle(
//                   fontSize: 15,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.white,
//                 ),),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _languageTile({
//     required String title,
//     required String code,
//   }) {
//     final isSelected = selectedLanguage == title;
//
//     return GestureDetector(
//       onTap: () {
//         setState(() => selectedLanguage = title);
//         ref.read(localeProvider.notifier).changeLanguage(code);
//       },
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 12),
//         padding: const EdgeInsets.all(14),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(
//             color: isSelected ? Colors.black : Colors.grey.shade300,
//           ),
//         ),
//         child: Row(
//           children: [
//             Expanded(child: Text(title)),
//             if (isSelected)
//               const Icon(Icons.check_circle, color: Colors.black)
//           ],
//         ),
//       ),
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hobit_worker/colors/appcolors.dart';
import '../l10n/app_localizations.dart';
import '../language_selection/language_provider.dart';
import '../utils/app_bar.dart';

class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState
    extends ConsumerState<LanguageSelectionScreen> {

  /// store selected language CODE
  String selectedLanguageCode = "en";

  /// languages list from localization
  List<Map<String, String>> _languages(AppLocalizations loc) {
    return [
      {"name": loc.languageEnglish, "code": "en"},
      {"name": loc.languageHindi, "code": "hi"},
      {"name": loc.languageMarathi, "code": "mr"},
    ];
  }

  @override
  void initState() {
    super.initState();

    final locale = ref.read(localeProvider);

    /// get current selected language
    selectedLanguageCode = locale.languageCode;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final languages = _languages(loc);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(title: loc.languageSelection),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// title
            Text(
              loc.chooseLanguage,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 20),

            /// language list
            ...languages.map(
                  (lang) => _languageTile(
                title: lang["name"]!,
                code: lang["code"]!,
              ),
            ),

            const Spacer(),

            /// save button
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
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
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
    );
  }

  /// language tile
  Widget _languageTile({
    required String title,
    required String code,
  }) {

    final isSelected = selectedLanguageCode == code;

    return GestureDetector(
      onTap: () {

        setState(() {
          selectedLanguageCode = code;
        });

        ref.read(localeProvider.notifier).changeLanguage(code);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [

            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 15),
              ),
            ),

            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.black,
              )
          ],
        ),
      ),
    );
  }
}