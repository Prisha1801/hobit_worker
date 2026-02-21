// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:hobit_worker/utils/app_bar.dart';
// class LanguageSelectionScreen extends ConsumerStatefulWidget {
//   const LanguageSelectionScreen({Key? key}) : super(key: key);
//
//   @override
//   ConsumerState<LanguageSelectionScreen> createState() =>
//       _LanguageSelectionScreenState();
// }
//
// class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
//   String selectedLanguage = "English";
//
//   final List<Map<String, String>> languages = [
//     {"name": "English", "code": "en"},
//     {"name": "Hindi", "code": "hi"},
//     {"name": "Marathi", "code": "mr"},
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: CommonAppBar(title: 'Language Selection'),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             /// INFO TEXT
//             const Text(
//               "Choose your preferred language",
//               style: TextStyle(
//                 fontSize: 13,
//                 color: Colors.black54,
//               ),
//             ),
//
//             const SizedBox(height: 20),
//
//             /// LANGUAGE LIST
//             ...languages.map((lang) => _languageTile(
//               title: lang["name"]!,
//             )),
//
//             const Spacer(),
//
//             /// SAVE BUTTON
//             SizedBox(
//               width: double.infinity,
//               height: 48,
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.black,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 onPressed: () {
//                   debugPrint("Selected Language: $selectedLanguage");
//                   Navigator.pop(context);
//                 },
//                 child: const Text(
//                   "Save",
//                   style: TextStyle(
//                     fontSize: 15,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   /// ===== LANGUAGE TILE =====
//   Widget _languageTile({required String title}) {
//     final bool isSelected = selectedLanguage == title;
//
//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           selectedLanguage = title;
//         });
//       },
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 12),
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(
//             color: isSelected ? Colors.black : Colors.grey.shade300,
//             width: 1,
//           ),
//           boxShadow: const [
//             BoxShadow(
//               color: Color(0x0D000000),
//               offset: Offset(0, 4),
//               blurRadius: 4,
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             Expanded(
//               child: Text(
//                 title,
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                   color: isSelected ? Colors.black : Colors.black87,
//                 ),
//               ),
//             ),
//             Container(
//               width: 20,
//               height: 20,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 border: Border.all(
//                   color: isSelected ? Colors.black : Colors.grey,
//                   width: 2,
//                 ),
//               ),
//               child: isSelected
//                   ? Center(
//                 child: Container(
//                   width: 10,
//                   height: 10,
//                   decoration: const BoxDecoration(
//                     color: Colors.black,
//                     shape: BoxShape.circle,
//                   ),
//                 ),
//               )
//                   : null,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  String selectedLanguage = "";

  final List<Map<String, String>> languages = [
    {"name": "English", "code": "en"},
    {"name": "Hindi", "code": "hi"},
    {"name": "Marathi", "code": "mr"},
  ];

  @override
  void initState() {
    super.initState();
    final locale = ref.read(localeProvider);

    selectedLanguage = languages.firstWhere(
          (lang) => lang['code'] == locale.languageCode,
      orElse: () => languages.first,
    )['name']!;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(title: loc.languageSelection),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.chooseLanguage,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 20),

            ...languages.map(
                  (lang) => _languageTile(
                title: lang["name"]!,
                code: lang["code"]!,
              ),
            ),

            const Spacer(),

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
                onPressed: () => Navigator.pop(context),
                child: Text(loc.save,
                  style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _languageTile({
    required String title,
    required String code,
  }) {
    final isSelected = selectedLanguage == title;

    return GestureDetector(
      onTap: () {
        setState(() => selectedLanguage = title);
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
            Expanded(child: Text(title)),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.black)
          ],
        ),
      ),
    );
  }
}
