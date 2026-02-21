// import 'package:flutter/material.dart';
// import 'package:hobit_worker/utils/app_bar.dart';
//
// class MyEarningsScreen extends StatelessWidget {
//   const MyEarningsScreen({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//      appBar: CommonAppBar(title: 'My Earning'),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             /// ===== CURRENT EARNINGS CARD =====
//             Container(
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: const Color(0xFFFFF2FD),
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Column(
//                 children: [
//                   const Text(
//                     "Current Earnings",
//                     style: TextStyle(fontSize: 13, color: Colors.black54),
//                   ),
//                   const SizedBox(height: 6),
//                   const Text(
//                     "₹ 11,299",
//                     style: TextStyle(
//                       fontSize: 26,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 14),
//                   SizedBox(
//                     width: double.infinity,
//                     height: 42,
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.black,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       onPressed: () {},
//                       child: const Text(
//                         "Withdraw Request",
//                         style: TextStyle(
//                           fontWeight: FontWeight.w600,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//             const SizedBox(height: 16),
//
//             /// ===== SMALL STATS =====
//             Row(
//               children: [
//                 _smallCard("₹ 1,299", "Today's Earning"),
//                 const SizedBox(width: 12),
//                 _smallCard("₹ 9,299", "This Week's"),
//               ],
//             ),
//
//             const SizedBox(height: 24),
//
//             /// ===== PREVIOUS TRANSACTIONS =====
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   "Previous Transactions",
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 GestureDetector(
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => const AllTransactionsScreen(),
//                       ),
//                     );
//                   },
//                   child: const Text(
//                     "View All",
//                     style: TextStyle(
//                       color: Colors.blue,
//                       fontSize: 13,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//
//             const SizedBox(height: 12),
//
//             _transactionTile(isCredit: true),
//             _transactionTile(isCredit: true),
//             _transactionTile(isCredit: true),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _smallCard(String amount, String title) {
//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: const Color(0xFFF6F7FF),
//           borderRadius: BorderRadius.circular(14),
//         ),
//         child: Column(
//           children: [
//             Text(
//               amount,
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               title,
//               style: const TextStyle(fontSize: 12, color: Colors.black54),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _transactionTile({required bool isCredit}) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 10),
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: const [
//           BoxShadow(
//             color: Color(0x0D000000),
//             offset: Offset(0, 4),
//             blurRadius: 4,
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           const CircleAvatar(
//             radius: 18,
//             backgroundColor: Color(0xFFF6F7FF),
//             child: Icon(Icons.home, size: 18),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: const [
//                 Text(
//                   "Utensils Washing",
//                   style: TextStyle(fontWeight: FontWeight.w600),
//                 ),
//                 SizedBox(height: 2),
//                 Text(
//                   "2 Feb 2026",
//                   style: TextStyle(fontSize: 12, color: Colors.black54),
//                 ),
//               ],
//             ),
//           ),
//           Text(
//             isCredit ? "+ ₹6,500.00" : "- ₹6,500.00",
//             style: TextStyle(
//               fontWeight: FontWeight.w600,
//               color: isCredit ? Colors.green : Colors.red,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
// class AllTransactionsScreen extends StatelessWidget {
//   const AllTransactionsScreen({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.white,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//         centerTitle: true,
//         title: const Text(
//           "All Transactions",
//           style: TextStyle(
//             color: Colors.black,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             /// TOTAL EARNINGS
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: const Color(0xFFFFF2FD),
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Column(
//                 children: const [
//                   Text(
//                     "₹12,400.00",
//                     style: TextStyle(
//                       fontSize: 26,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   SizedBox(height: 4),
//                   Text(
//                     "My Total Earnings",
//                     style: TextStyle(fontSize: 13, color: Colors.black54),
//                   ),
//                 ],
//               ),
//             ),
//
//             const SizedBox(height: 24),
//
//             const Text(
//               "Withdraw History",
//               style: TextStyle(fontWeight: FontWeight.w600),
//             ),
//             const SizedBox(height: 12),
//
//             _historyTile(isCredit: false),
//             _historyTile(isCredit: false),
//
//             const SizedBox(height: 24),
//
//             const Text(
//               "Credited History",
//               style: TextStyle(fontWeight: FontWeight.w600),
//             ),
//             const SizedBox(height: 12),
//
//             _historyTile(isCredit: true),
//             _historyTile(isCredit: true),
//             _historyTile(isCredit: true),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _historyTile({required bool isCredit}) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 10),
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: const [
//           BoxShadow(
//             color: Color(0x0D000000),
//             offset: Offset(0, 4),
//             blurRadius: 4,
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           const CircleAvatar(
//             radius: 18,
//             backgroundColor: Color(0xFFF6F7FF),
//             child: Icon(Icons.home, size: 18),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: const [
//                 Text(
//                   "Utensils Washing",
//                   style: TextStyle(fontWeight: FontWeight.w600),
//                 ),
//                 SizedBox(height: 2),
//                 Text(
//                   "2 Feb 2026",
//                   style: TextStyle(fontSize: 12, color: Colors.black54),
//                 ),
//               ],
//             ),
//           ),
//           Text(
//             isCredit ? "+ ₹6,500.00" : "- ₹6,500.00",
//             style: TextStyle(
//               fontWeight: FontWeight.w600,
//               color: isCredit ? Colors.green : Colors.red,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hobit_worker/screens/personal_info.dart';
import 'package:shimmer/shimmer.dart';
import '../api_services/api_services.dart';
import '../l10n/app_localizations.dart';
import '../models/get_profile_model.dart';
import '../models/withdrawal_model.dart';
import '../prefs/app_preference.dart';
import '../prefs/preference_key.dart';
import '../utils/app_bar.dart';

/// ================= API =================
class WithdrawalApi {
  static Future<List<WithdrawalHistoryModel>> getHistory(int workerId) async {
    final token = AppPreference().getString(PreferencesKey.token);
    final res = await ApiService.getRequest(
      "/api/withdrawal/$workerId/history",
      options: Options(
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      ),
    );

    final List data = res.data['data'];
    return data
        .map((e) => WithdrawalHistoryModel.fromJson(e))
        .toList();
  }

  static Future<String> submitWithdraw({
    required int amount,
    required String requestNote,
  }) async {
    final token = AppPreference().getString(PreferencesKey.token);
    final res = await ApiService.postRequest(
      "/api/worker/withdraw",
      {
        "amount": amount,
        "request_note": requestNote,
      },
      options: Options(
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      ),
    );

    return res.data["message"];
  }
}


/// ================= SCREEN =================
class MyEarningsScreen extends StatefulWidget {
  const MyEarningsScreen({super.key});

  @override
  State<MyEarningsScreen> createState() => _MyEarningsScreenState();
}

class _MyEarningsScreenState extends State<MyEarningsScreen> {
  bool loading = true;
  late Future<WorkerProfileModel> _profileFuture;
  List<WithdrawalHistoryModel> history = [];

  @override
  void initState() {
    super.initState();
    _profileFuture = WorkerApi.getMyProfile();
    loadHistory();
  }

  Future<void> loadHistory() async {
    try {
      history = await WithdrawalApi.getHistory(
        AppPreference().getInt(PreferencesKey.userId),
      );
    } catch (e) {
      debugPrint("History error: $e");
    }
    setState(() => loading = false);
  }

  /// STATUS COLOR
  Color statusColor(String status) {
    switch (status) {
      case "approved":
        return Colors.green;
      case "rejected":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  /// MONTH NAME
  String _month(int m) {
    const months = [
      "Jan","Feb","Mar","Apr","May","Jun",
      "Jul","Aug","Sep","Oct","Nov","Dec"
    ];
    return months[m - 1];
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(title: loc.myEarnings),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// ================= CURRENT EARNINGS =================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF2FD),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                   loc.walletBalance,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 6),
                  FutureBuilder<WorkerProfileModel>(
                    future: _profileFuture,
                    builder: (context, snapshot) {
                      // if (snapshot.connectionState == ConnectionState.waiting) {
                      //   return const CircularProgressIndicator();
                      // }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CommonShimmer(
                          height: 30,
                          width: 120,
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Text("₹ 0");
                      }

                      final profile = snapshot.data!;

                      return Text(
                        "₹ ${profile.walletBalance}",
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WithdrawRequestScreen(),
                          ),
                        );

                        if (result == true) {
                          setState(() {
                            _profileFuture = WorkerApi.getMyProfile();
                            loading = true;
                          });
                          loadHistory(); // 🔥 refresh history
                        }
                      },

                      child: Text(
                       loc.withdrawRequest,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// ================= PREVIOUS TRANSACTIONS =================
            Text(
             loc.withdrawHistory,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 16),

            if (loading)
              const WithdrawHistoryShimmer()
            else if (history.isEmpty)
              Center(
                child: Text(
                loc.noWithdrawHistory,
                  style: const TextStyle(color: Colors.black54),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final item = history[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        /// TOP ROW
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.requestNote,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor(item.status)
                                    .withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                item.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor(item.status),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        /// DATE
                        Text(
                          "${item.createdAt.day} "
                              "${_month(item.createdAt.month)} "
                              "${item.createdAt.year}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),

                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),

                        /// AMOUNT
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              loc.amount,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              "₹${item.approvedAmount ?? item.amount}",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: statusColor(item.status),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ================= WITHDRAW REQUEST SCREEN =================
class WithdrawRequestScreen extends StatefulWidget {
  const WithdrawRequestScreen({super.key});

  @override
  State<WithdrawRequestScreen> createState() =>
      _WithdrawRequestScreenState();
}

class _WithdrawRequestScreenState extends State<WithdrawRequestScreen> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  bool loading = false;

  Future<void> submitWithdraw() async {
    final loc = AppLocalizations.of(context)!;
    final amountText = amountController.text.trim();
    final noteText = noteController.text.trim();

    if (amountText.isEmpty) {
      showMessage(loc.enterAmount);
      return;
    }

    final amount = int.tryParse(amountText);
    if (amount == null || amount <= 0) {
      showMessage(loc.enterValidAmount);
      return;
    }

    setState(() => loading = true);

    try {
      final message = await WithdrawalApi.submitWithdraw(
        amount: amount,
        requestNote: noteText.isEmpty ? loc.withdrawDefaultNote : noteText,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

      Navigator.pop(context, true);

    } catch (e) {
      if (e is ApiException) {
        showMessage(e.message);
      }
      else {
        showMessage("Something went wrong");
      }
    }
    setState(() => loading = false);
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(title: loc.withdrawRequest),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// Amount
            // TextField(
            //   controller: amountController,
            //   keyboardType: TextInputType.number,
            //   decoration: const InputDecoration(
            //     labelText: "Amount",
            //     border: OutlineInputBorder(),
            //   ),
            // ),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: loc.amount,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), // 🔥 radius here
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black, width: 1.5),
                ),
              ),
            ),


            const SizedBox(height: 16),

            /// Note
            // TextField(
            //   controller: noteController,
            //   maxLines: 3,
            //   decoration: const InputDecoration(
            //     labelText: "Request Note",
            //     hintText: "Weekly payout",
            //     border: OutlineInputBorder(),
            //   ),
            // ),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: loc.requestNote,
                hintText: loc.weeklyPayout,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black, width: 1.5),
                ),
              ),
            ),


            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),

                onPressed: loading ? null : submitWithdraw,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  loc.submitRequest,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



//shimmer effect can be added to the history list when loading is true, to enhance user experience.


class CommonShimmer extends StatelessWidget {
  final double height;
  final double width;
  final BorderRadius borderRadius;

  const CommonShimmer({
    super.key,
    required this.height,
    this.width = double.infinity,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}


class WithdrawHistoryShimmer extends StatelessWidget {
  const WithdrawHistoryShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (_, __) {
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              CommonShimmer(height: 14, width: 160),
              SizedBox(height: 10),
              CommonShimmer(height: 12, width: 100),
              SizedBox(height: 16),
              CommonShimmer(height: 18, width: 80),
            ],
          ),
        );
      },
    );
  }
}
