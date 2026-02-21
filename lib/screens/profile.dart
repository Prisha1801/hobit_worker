import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hobit_worker/colors/appcolors.dart';
import 'package:hobit_worker/screens/personal_info.dart';
import 'package:hobit_worker/screens/support.dart';
import 'package:hobit_worker/utils/app_bar.dart';
import '../auth/logout.dart';
import '../l10n/app_localizations.dart';
import '../models/get_profile_model.dart';
import 'about_us.dart';
import 'add_bank_details.dart';
import 'kyc_screen.dart';
import 'language_selection.dart';
import 'my_earning.dart';


class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {

  late Future<WorkerProfileModel> _profileFuture;


  @override
  void initState() {
    super.initState();
    _profileFuture = WorkerApi.getMyProfile();
  }
  void refreshProfile() {
    setState(() {
      _profileFuture = WorkerApi.getMyProfile(); // 🔥 RELOAD
    });
  }
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(title: loc.profile, showBackButton: false),
      body: Column(
        children: [
          FutureBuilder<WorkerProfileModel>(
            future: _profileFuture,
          //  future: WorkerApi.getMyProfile(),
            builder: (context, snapshot) {

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                );
              }

              if (!snapshot.hasData) {
                return const SizedBox();
              }

              final profile = snapshot.data!;

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                decoration: BoxDecoration(
                  color: kWhite,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(28),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    /// 👤 Greeting
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                          child: const Icon(Icons.person, size: 26),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.helloWelcome,
                              style: const TextStyle(fontSize: 14, color: Colors.black54),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              profile.name, // ✅ NAME
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// 📊 Cards
                    Row(
                      children: [

                        /// Jobs Completed
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  profile.jobsCompleted.toString(), // ✅ JOBS
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                loc.jobsCompleted,
                                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 14),

                        /// Wallet
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '₹ ${profile.walletBalance}', // ✅ WALLET
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                 loc.wallet,
                                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          // 🔽 SCROLLABLE MENU ITEMS ONLY
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _buildMenuItem(
                    icon: Icons.person_outline,
                    title: loc.personalInfo,
                    subtitle: loc.personalInfoSub,
                    onTap: () async {
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) => PersonalInformationScreen(),
                      //   ),
                      // );
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PersonalInformationScreen(),
                        ),
                      );

                      if (updated == true) {
                        refreshProfile(); // 🔥 INSTANT REFRESH
                      }
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.account_balance,
                    title: loc.addBank,
                    subtitle: loc.addBankSub,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddBankScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.currency_rupee,
                    title:loc.earnings,
                    subtitle: loc.earningsSub,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyEarningsScreen(),
                        ),
                      );
                    },
                  ),

                  _buildMenuItem(
                    icon: Icons.help_outline,
                    title: loc.helpSupport,
                    subtitle: loc.helpSupportSub,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HelpSupportScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.language,
                    title: loc.languageSelection,
                    subtitle: loc.languageSelectionSub,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LanguageSelectionScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.info_outline,
                    title: loc.aboutUs,
                    subtitle: loc.aboutUsSub,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutUsScreen(),
                        ),
                      );
                    },
                  ),

                  // _buildMenuItem(
                  //   icon: Icons.info_outline,
                  //   title: 'kyc update',
                  //   subtitle: 'kyc update',
                  //   onTap: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(
                  //         builder: (context) => const KycScreen(),
                  //       ),
                  //     );
                  //   },
                  // ),
                  _buildMenuItem(
                    icon: Icons.logout,
                    title: loc.logout,
                    subtitle:loc.logoutSub,
                    onTap: () {
                      showLogoutDialog(context,  ref);
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle, // 🔹 NEW
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.06),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                /// Icon Box (Left)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? Colors.grey.shade200
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isDestructive ? Colors.grey[600] : Colors.black87,
                    size: 22,
                  ),
                ),

                const SizedBox(width: 14),

                /// Title + Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isDestructive
                              ? Colors.grey[700]
                              : Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                /// Arrow
                Icon(Icons.chevron_right, color: Colors.grey[500], size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget _buildDivider() {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 20),
  //     child: Divider(color: Colors.grey[300], height: 1, thickness: 1),
  //   );
  // }
}
