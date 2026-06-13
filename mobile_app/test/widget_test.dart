import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/screens/add_clothing/add_clothing_screen.dart';
import 'package:mobile_app/screens/add_clothing/add_clothing_view_model.dart';
import 'package:mobile_app/screens/add_clothing/widgets/analysis_error_view.dart';
import 'package:mobile_app/screens/add_clothing/widgets/analysis_loading_view.dart';
import 'package:mobile_app/screens/add_clothing/widgets/analysis_result_view.dart';

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  group('AddClothingScreen — async state transitions', () {
    testWidgets(
      'WT-01: shows AnalysisLoadingView while isAnalyzing is true',
      (tester) async {
        final vm = AddClothingViewModel.forTest(isAnalyzing: true);
        await tester.pumpWidget(
          MaterialApp(home: AddClothingScreen(testViewModel: vm)),
        );
        await tester.pump(const Duration(milliseconds: 1300));

        expect(find.byType(AnalysisLoadingView), findsOneWidget);
        expect(find.text('Analyzing your item…'), findsOneWidget);
        expect(find.text('Analyze with AI'), findsNothing);

        vm.dispose();
      },
    );

    testWidgets(
      'WT-02: shows upload form and Analyze button in initial state',
      (tester) async {
        final vm = AddClothingViewModel.forTest();
        await tester.pumpWidget(
          MaterialApp(home: AddClothingScreen(testViewModel: vm)),
        );
        await tester.pump(const Duration(milliseconds: 1000));

        expect(find.byType(AnalysisLoadingView), findsNothing);
        expect(find.byType(AnalysisResultView), findsNothing);
        expect(find.text('Analyze with AI'), findsOneWidget);
        expect(find.text('Add New Item'), findsOneWidget);

        vm.dispose();
      },
    );

    testWidgets(
      'WT-03: shows AnalysisErrorView with error message when analysis fails',
      (tester) async {
        final vm = AddClothingViewModel.forTest(
          errorMessage: 'Connection timeout',
        );
        await tester.pumpWidget(
          MaterialApp(home: AddClothingScreen(testViewModel: vm)),
        );

        expect(find.byType(AnalysisErrorView), findsOneWidget);
        expect(find.text('Connection timeout'), findsOneWidget);
        expect(find.byType(AnalysisLoadingView), findsNothing);

        vm.dispose();
      },
    );
  });
}
