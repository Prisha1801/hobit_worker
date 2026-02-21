import 'package:flutter/material.dart';
import 'package:hobit_worker/utils/app_bar.dart';
import '../l10n/app_localizations.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final loc = AppLocalizations.of(context)!;
    return Scaffold(

      backgroundColor: Colors.white,
     appBar: CommonAppBar(title: loc.aboutUs),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ===== APP LOGO / TITLE =====
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 36,
                    backgroundColor: Color(0xFFF6F7FF),
                    child: Icon(
                      Icons.home_repair_service,
                      size: 36,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    loc.appTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loc.aboutTagline,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            /// ===== ABOUT CARD =====
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
              child: Text(
                loc.aboutDescription,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Colors.black87,
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// ===== INFO LIST =====
            _infoTile(loc.version, "1.0.0"),
            _infoTile(loc.company, loc.companyName),
            _infoTile(loc.supportEmail,loc.supportEmailValue),
            _infoTile(loc.website, loc.websiteValue),

            const SizedBox(height: 32),

            /// ===== FOOTER =====
            Center(
              child: Text(
                loc.copyright,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

