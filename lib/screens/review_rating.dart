// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import '../api_services/api_services.dart';
// import '../l10n/app_localizations.dart';
// import '../models/review_model.dart';
// import '../prefs/app_preference.dart';
// import '../prefs/preference_key.dart';
// import '../utils/app_bar.dart';
//
// class RatingApi {
//
//   static Future<Map<String, dynamic>> getRatings() async {
//
//     final token = AppPreference().getString(PreferencesKey.token);
//     final workerId = AppPreference().getString(PreferencesKey.userId);
//
//     final res = await ApiService.getRequest(
//       "/api/workers/$workerId/ratings",
//       options: Options(
//         headers: {
//           "Authorization": "Bearer $token",
//           "Accept": "application/json",
//         },
//       ),
//     );
//
//     final summary = RatingSummary.fromJson(res.data['summary']);
//
//     final List ratingsJson = res.data['ratings']['data'];
//
//     final ratings =
//     ratingsJson.map((e) => RatingModel.fromJson(e)).toList();
//
//     return {
//       "summary": summary,
//       "ratings": ratings,
//     };
//   }
// }
//
// class RatingsScreen extends StatefulWidget {
//   const RatingsScreen({super.key});
//
//   @override
//   State<RatingsScreen> createState() => _RatingsScreenState();
// }
//
// class _RatingsScreenState extends State<RatingsScreen> {
//
//   late Future<Map<String, dynamic>> ratingsFuture;
//
//   @override
//   void initState() {
//     super.initState();
//
//     /// dynamic API call
//     ratingsFuture = RatingApi.getRatings();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final loc = AppLocalizations.of(context)!;
//     return Scaffold(
//       appBar: CommonAppBar(title: loc.reviewRatings),
//       backgroundColor: Colors.white,
//       body: FutureBuilder<Map<String, dynamic>>(
//         future: ratingsFuture,
//         builder: (context, snapshot) {
//
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           if (!snapshot.hasData) {
//             return const Center(child: Text("No Ratings Found"));
//           }
//
//           final summary = snapshot.data!["summary"] as RatingSummary;
//           final List<RatingModel> ratings =
//           snapshot.data!["ratings"];
//
//           return Column(
//             children: [
//
//               /// ⭐ SUMMARY CARD
//               Container(
//                 margin: const EdgeInsets.all(16),
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   color: Colors.black,
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: Row(
//                   children: [
//
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           summary.averageRating.toString(),
//                           style: const TextStyle(
//                             fontSize: 34,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                         ),
//
//                         Row(
//                           children: List.generate(
//                             5,
//                                 (index) => Icon(
//                               index < summary.averageRating
//                                   ? Icons.star
//                                   : Icons.star_border,
//                               color: Colors.orange,
//                               size: 20,
//                             ),
//                           ),
//                         ),
//
//                         const SizedBox(height: 4),
//
//                         Text(
//                           "${summary.totalRatings} ratings",
//                           style: const TextStyle(
//                             color: Colors.white70,
//                           ),
//                         ),
//                       ],
//                     ),
//
//                     const Spacer(),
//
//                     const Icon(
//                       Icons.star_rate_rounded,
//                       color: Colors.orange,
//                       size: 60,
//                     )
//                   ],
//                 ),
//               ),
//
//               /// ⭐ REVIEWS LIST
//               Expanded(
//                 child: ListView.builder(
//                   padding: const EdgeInsets.symmetric(horizontal: 16),
//                   itemCount: ratings.length,
//                   itemBuilder: (context, index) {
//
//                     final rating = ratings[index];
//
//                     return Container(
//                       margin: const EdgeInsets.only(bottom: 12),
//                       padding: const EdgeInsets.all(14),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(14),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(.05),
//                             blurRadius: 6,
//                           )
//                         ],
//                       ),
//                       child: Column(
//                         crossAxisAlignment:
//                         CrossAxisAlignment.start,
//                         children: [
//
//                           Row(
//                             children: [
//
//                               const CircleAvatar(
//                                 child: Icon(Icons.person),
//                               ),
//
//                               const SizedBox(width: 10),
//
//                               Column(
//                                 crossAxisAlignment:
//                                 CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     rating.customerName,
//                                     style: const TextStyle(
//                                       fontWeight:
//                                       FontWeight.w600,
//                                     ),
//                                   ),
//
//                                   Row(
//                                     children: List.generate(
//                                       rating.rating,
//                                           (index) => const Icon(
//                                         Icons.star,
//                                         color: Colors.orange,
//                                         size: 16,
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               )
//                             ],
//                           ),
//
//                           const SizedBox(height: 8),
//
//                           Text(
//                             rating.description,
//                             style: const TextStyle(
//                               color: Colors.black87,
//                             ),
//                           ),
//
//                           const SizedBox(height: 6),
//
//                           Text(
//                             rating.createdAt.substring(0, 10),
//                             style: const TextStyle(
//                               color: Colors.grey,
//                               fontSize: 12,
//                             ),
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                 ),
//               )
//             ],
//           );
//         },
//       ),
//     );
//   }
// }



import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../api_services/api_services.dart';
import '../l10n/app_localizations.dart';
import '../models/review_model.dart';
import '../prefs/app_preference.dart';
import '../prefs/preference_key.dart';
import '../utils/app_bar.dart';

class RatingApi {

  static Future<Map<String, dynamic>> getRatings() async {

    final token = AppPreference().getString(PreferencesKey.token);
    final workerId = AppPreference().getString(PreferencesKey.userId);

    final res = await ApiService.getRequest(
      "/api/workers/$workerId/ratings",
      options: Options(
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      ),
    );

    final summary = RatingSummary.fromJson(res.data['summary']);

    final List ratingsJson = res.data['ratings']['data'];

    final ratings =
    ratingsJson.map((e) => RatingModel.fromJson(e)).toList();

    return {
      "summary": summary,
      "ratings": ratings,
    };
  }
}

class RatingsScreen extends StatefulWidget {
  const RatingsScreen({super.key});

  @override
  State<RatingsScreen> createState() => _RatingsScreenState();
}

class _RatingsScreenState extends State<RatingsScreen> {

  late Future<Map<String, dynamic>> ratingsFuture;

  @override
  void initState() {
    super.initState();
    ratingsFuture = RatingApi.getRatings();
  }

  @override
  Widget build(BuildContext context) {

    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: CommonAppBar(title: loc.reviewRatings),
      backgroundColor: Colors.white,

      body: FutureBuilder<Map<String, dynamic>>(
        future: ratingsFuture,
        builder: (context, snapshot) {

          /// SHIMMER LOADING
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmer();
          }

          /// NO DATA
          if (!snapshot.hasData) {
            return Center(
              child: Text(loc.noRatingsFound),
            );
          }

          final summary = snapshot.data!["summary"] as RatingSummary;
          final List<RatingModel> ratings = snapshot.data!["ratings"];

          return Column(
            children: [

              /// ⭐ SUMMARY CARD
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          summary.averageRating.toString(),
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        Row(
                          children: List.generate(
                            5,
                                (index) => Icon(
                              index < summary.averageRating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.orange,
                              size: 20,
                            ),
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          "${summary.totalRatings} ${loc.ratingsCount(summary.totalRatings)}",
                          style: const TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    const Icon(
                      Icons.star_rate_rounded,
                      color: Colors.orange,
                      size: 60,
                    )
                  ],
                ),
              ),

              /// ⭐ REVIEWS LIST
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: ratings.length,
                  itemBuilder: (context, index) {

                    final rating = ratings[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
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

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Row(
                            children: [

                              const CircleAvatar(
                                child: Icon(Icons.person),
                              ),

                              const SizedBox(width: 10),

                              Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [

                                  Text(
                                    rating.customerName.isEmpty
                                        ? "User"
                                        : rating.customerName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),

                                  Row(
                                    children: List.generate(
                                      rating.rating,
                                          (index) => const Icon(
                                        Icons.star,
                                        color: Colors.orange,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),

                          const SizedBox(height: 8),

                          Text(
                            rating.description,
                            style: const TextStyle(
                              color: Colors.black87,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            rating.createdAt.substring(0, 10),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
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
    );
  }

  /// ⭐ SHIMMER UI
  Widget _buildShimmer() {
    return ListView.builder(
      itemCount: 5,
      padding: const EdgeInsets.all(16),
      itemBuilder: (_, __) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }
}