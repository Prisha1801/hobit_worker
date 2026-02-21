import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:hobit_worker/colors/appcolors.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBack;

  const CommonAppBar({
    Key? key,
    required this.title,
    this.showBackButton = true,
    this.onBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              /// 🔙 Back Button
              if (showBackButton)
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: onBack ??
                          () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                ),

              /// 🏷️ Title
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),

              if (showBackButton)
                const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(100);
}
