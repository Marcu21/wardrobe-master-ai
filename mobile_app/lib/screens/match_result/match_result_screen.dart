import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/navigation/app_routes.dart';
import 'package:mobile_app/theme/app_colors.dart';
import 'package:mobile_app/widgets/scale_button.dart';
import 'widgets/match_result_header.dart';
import 'widgets/match_score_card.dart';
import 'widgets/match_analysis_box.dart';
import 'widgets/match_outfits_list.dart';
import 'match_result_view_model.dart';

const _kBlob1 = Color(0x380EA5E9);
const _kBlob2 = Color(0x200284C7);

class MatchResultScreen extends StatelessWidget {
  final Map<String, dynamic> scannedItemData;
  final File imageFile;

  const MatchResultScreen({
    super.key,
    required this.scannedItemData,
    required this.imageFile,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MatchResultViewModel(scannedItemData: scannedItemData),
      child: _MatchResultBody(
        scannedItemData: scannedItemData,
        imageFile: imageFile,
      ),
    );
  }
}

class _MatchResultBody extends StatefulWidget {
  final Map<String, dynamic> scannedItemData;
  final File imageFile;

  const _MatchResultBody({
    required this.scannedItemData,
    required this.imageFile,
  });

  @override
  State<_MatchResultBody> createState() => _MatchResultBodyState();
}

class _MatchResultBodyState extends State<_MatchResultBody> {
  bool _errorShown = false;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MatchResultViewModel>();

    if (vm.errorMessage != null && !_errorShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_errorShown) {
          setState(() => _errorShown = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error analyzing wardrobe: ${vm.errorMessage}'),
            ),
          );
        }
      });
    }

    return Scaffold(
      backgroundColor: kBgColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Match Results',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -70,
            right: -50,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kBlob1,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: -50,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kBlob2,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MatchResultHeader(
                    scannedItemData: widget.scannedItemData,
                    imageFile: widget.imageFile,
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topCenter,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeIn,
                      switchOutCurve: Curves.easeOut,
                      layoutBuilder: (currentChild, previousChildren) {
                        return Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            ...previousChildren,
                            if (currentChild != null) currentChild,
                          ],
                        );
                      },
                      child: vm.isLoading
                          ? Padding(
                              key: const ValueKey('loading'),
                              padding: const EdgeInsets.symmetric(
                                vertical: 48.0,
                              ),
                              child: Center(
                                child: Column(
                                  children: [
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color:
                                                Colors.teal.withOpacity(0.07),
                                            border: Border.all(
                                              color: Colors.teal.withOpacity(
                                                0.15,
                                              ),
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 52,
                                          height: 52,
                                          child: CircularProgressIndicator(
                                            color: Colors.teal.withOpacity(
                                              0.25,
                                            ),
                                            strokeWidth: 1.5,
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 36,
                                          height: 36,
                                          child: CircularProgressIndicator(
                                            color: Colors.teal,
                                            strokeWidth: 2.5,
                                          ),
                                        ),
                                        const Icon(
                                          CupertinoIcons.sparkles,
                                          color: Colors.teal,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    const Text(
                                      "Analyzing match…",
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      "Scoring, styling & building your results",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.black45,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Column(
                              key: const ValueKey('content'),
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                MatchScoreCard(matchScore: vm.matchScore),
                                const SizedBox(height: 20),
                                MatchAnalysisBox(
                                  title: "Why it works",
                                  items: vm.pros,
                                  color: Colors.green[700]!,
                                  bgColor: Colors.green[50]!,
                                  icon: Icons.check_circle_outline,
                                ),
                                MatchAnalysisBox(
                                  title: "Keep in mind",
                                  items: vm.cons,
                                  color: Colors.orange[800]!,
                                  bgColor: Colors.orange[50]!,
                                  icon: Icons.warning_amber_rounded,
                                ),
                                MatchOutfitsList(
                                  generatedOutfits: vm.generatedOutfits,
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ScaleButton(
                    onTap: () {
                      Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.addClothing,
                        arguments: AddClothingArgs(
                          initialAnalysisResult: widget.scannedItemData,
                          initialImageFile: widget.imageFile,
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.teal,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.withOpacity(0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.checkmark_circle_fill,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Buy & Add to Wardrobe",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ScaleButton(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.72),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.teal.withOpacity(0.30),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.xmark,
                            color: Colors.teal,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Discard",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.teal,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
