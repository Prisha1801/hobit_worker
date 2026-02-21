import 'package:flutter/material.dart';
import 'package:hobit_worker/utils/app_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

Future<void> _callSupport() async {
  final Uri phoneUri = Uri(
    scheme: 'tel',
    path: '77578720230',
  );

  if (await canLaunchUrl(phoneUri)) {
    await launchUrl(phoneUri);
  } else {
    throw 'Could not launch dialer';
  }
}

Future<void> _emailSupport() async {
  final Uri emailUri = Uri(
    scheme: 'mailto',
    path: 'rathodprathamesh23@gmail.com',
    queryParameters: {
      'subject': 'Help & Support',
      'body': 'Hello Support Team,',
    },
  );

  if (await canLaunchUrl(emailUri)) {
    await launchUrl(emailUri);
  } else {
    throw 'Could not launch email app';
  }
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(title: loc.helpSupport),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ===== HEADER CARD =====
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F7FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.support_agent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      loc.needHelpHeader,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// ===== QUICK ACTIONS =====
            Text(
            loc.quickSupport,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            _supportTile(
              icon: Icons.call,
              title: loc.callSupport,
              subtitle: loc.callSupportSubtitle,
              onTap: _callSupport,
            ),

            _supportTile(
              icon: Icons.email,
              title: loc.emailSupport,
              subtitle: loc.emailSupportSubtitle,
              onTap: _emailSupport,
            ),

            // _supportTile(
            //   icon: Icons.chat,
            //   title: "Live Chat",
            //   subtitle: "Chat with support team",
            //   onTap: () {},
            // ),

            const SizedBox(height: 24),
            //
            // /// ===== FAQ =====
            // const Text(
            //   "Frequently Asked Questions",
            //   style: TextStyle(
            //     fontSize: 14,
            //     fontWeight: FontWeight.w600,
            //   ),
            // ),
            // const SizedBox(height: 12),
            //
            // _faqTile(
            //   "How do I start a service?",
            //   "Go to Home → Assigned Job → Start Service → Enter OTP.",
            // ),
            // _faqTile(
            //   "When will I receive my payment?",
            //   "Payments are credited after job completion as per policy.",
            // ),
            // _faqTile(
            //   "How can I update my bank details?",
            //   "Go to Profile → Banking Details → Update.",
            // ),
            // _faqTile(
            //   "What if a customer cancels the job?",
            //   "Cancelled jobs will be shown in your bookings section.",
            // ),

            const SizedBox(height: 32),

            /// ===== FOOTER =====
            // Center(
            //   child: Text(
            //     "Support available Mon–Sat, 9 AM to 6 PM",
            //     style: TextStyle(
            //       fontSize: 12,
            //       color: Colors.grey.shade600,
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  /// ===== SUPPORT TILE =====
  Widget _supportTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFF6F7FF),
          child: Icon(icon, color: Colors.black),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
