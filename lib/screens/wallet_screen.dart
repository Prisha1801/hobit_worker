import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/bottom_nav_bar.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: GestureDetector(
        onTap: () {
          ref.read(bottomNavIndexProvider.notifier).state = 1;
        },
        child: const Text(
          'Go to Bookings',
          style: TextStyle(color: Colors.blue),
        ),
      ),
    );
  }
}
