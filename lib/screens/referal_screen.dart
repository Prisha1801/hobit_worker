import 'package:flutter/material.dart';
import 'package:hobit_worker/screens/referal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import '../l10n/app_localizations.dart';
import '../models/referal_model.dart';
import '../utils/app_bar.dart';
import '../colors/appcolors.dart';


class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {

  late Future<ReferralEarningModel?> referralFuture;
  String? referralCode;

  Future<void> refreshReferral() async {
    setState(() {
      referralFuture = ReferralApi.getReferralEarnings();
    });

    await referralFuture;
    await loadReferralCode();
  }

  @override
  void initState() {
    super.initState();
    referralFuture = ReferralApi.getReferralEarnings();
    loadReferralCode();
  }

  Future<void> loadReferralCode() async {
    final code = await ReferralApi.getReferralCode();
    setState(() {
      referralCode = code;
    });
  }

  // void shareCode() {
  //   if (referralCode != null) {
  //     Share.share(
  //       "Use my Hobit referral code and earn rewards 🎁\n\nCode: $referralCode",
  //     );
  //   }
  // }
  void shareCode() {
    if (referralCode != null) {
      Share.share(
        "🚀 Join Hobit Partner & start earning!\n\n"
            "Use my referral code to get rewards 🎁\n\n"
            "👉 Code: $referralCode\n\n"
            "📲 Download App:\n"
            "https://play.google.com/store/apps/details?id=com.hobit.hobit_worker",
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: CommonAppBar(title: loc.referAndEarn),
      backgroundColor: Colors.white,

      body: RefreshIndicator(
        color: kkblack,
        onRefresh: refreshReferral,
        child: FutureBuilder<ReferralEarningModel?>(
          future: referralFuture,
          builder: (context, snapshot) {
        
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const ReferralShimmer();
            }
            if (!snapshot.hasData) {
              return Center(child: Text(loc.noReferralsFound));
            }
            final data = snapshot.data!;
        
            return Column(
              children: [
        
                /// REFERRAL CODE CARD
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: kkblack,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
        
                      Text(
                  loc.yourReferralCode,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
        
                      const SizedBox(height: 8),
        
                      Text(
                        referralCode ?? "----",
                        style: const TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
        
                      const SizedBox(height: 12),
        
                      ElevatedButton.icon(
                        onPressed: shareCode,
                        icon: const Icon(Icons.share),
                        label:  Text(loc.shareCode),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
        
                /// POINTS + REFERRALS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
        
                      Expanded(
                        child: _statCard(
                         loc.pointsEarned,
                          data.referralPoints.toString(),
                          Icons.stars,
                        ),
                      ),
        
                      const SizedBox(width: 12),
        
                      Expanded(
                        child: _statCard(
                        loc.totalReferrals ,
                          data.referralsCount.toString(),
                          Icons.people,
                        ),
                      ),
                    ],
                  ),
                ),
        
                const SizedBox(height: 20),
        
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                     loc.referralHistory,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
        
                const SizedBox(height: 10),
        
                /// REFERRAL LIST
                Expanded(
                  child: ListView.builder(
                    itemCount: data.referrals.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
        
                      final r = data.referrals[index];
        
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.05),
                              blurRadius: 6,
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Colors.black,
                              child: Icon(Icons.person, color: Colors.white,),
                            ),
        
                            const SizedBox(width: 12),
        
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
        
                                  Text(
                                    r.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
        
                                  const SizedBox(height: 2),
        
                                  Text(
                                    r.phone,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
        
                            Text(
                              "+${r.points}",
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) {

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 6,
          )
        ],
      ),
      child: Column(
        children: [

          Icon(icon, color: Colors.orange),

          const SizedBox(height: 6),

          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}



class ReferralShimmer extends StatelessWidget {
  const ReferralShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [

        /// REFERRAL CARD
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),

        const SizedBox(height: 16),

        /// STATS CARDS
        Row(
          children: [
            Expanded(
              child: Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        /// LIST SHIMMER
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 5,
          itemBuilder: (_, __) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}