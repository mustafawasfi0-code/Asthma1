import 'package:asthma_care/models/monitoring.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PeakFlowAssessment', () {
    test('requires exactly three readings and keeps the highest', () {
      final result = PeakFlowAssessment.calculate([450, 700, 620], 800);
      expect(result.readings, [450, 700, 620]);
      expect(result.highest, 700);
      expect(result.percentage, 87.5);
      expect(result.zone, PeakFlowZone.green);
    });

    test('zone boundaries are correct', () {
      expect(
        PeakFlowAssessment.calculate([800, 700, 600], 1000).zone,
        PeakFlowZone.green,
      );
      expect(
        PeakFlowAssessment.calculate([790, 700, 600], 1000).zone,
        PeakFlowZone.yellow,
      );
      expect(
        PeakFlowAssessment.calculate([500, 400, 300], 1000).zone,
        PeakFlowZone.yellow,
      );
      expect(
        PeakFlowAssessment.calculate([499, 400, 300], 1000).zone,
        PeakFlowZone.red,
      );
    });

    test('missing personal best returns unavailable zone', () {
      final result = PeakFlowAssessment.calculate([300, 400, 350], null);
      expect(result.highest, 400);
      expect(result.percentage, isNull);
      expect(result.zone, PeakFlowZone.unavailable);
    });

    test('implausible personal best never produces a false red alert', () {
      final result = PeakFlowAssessment.calculate([900, 600, 800], 13234);
      expect(result.highest, 900);
      expect(result.percentage, isNull);
      expect(result.zone, PeakFlowZone.unavailable);
    });

    test('rejects fewer, extra, or invalid readings', () {
      expect(
        () => PeakFlowAssessment.calculate([100, 200], 500),
        throwsFormatException,
      );
      expect(
        () => PeakFlowAssessment.calculate([100, 200, 300, 400], 500),
        throwsFormatException,
      );
      expect(
        () => PeakFlowAssessment.calculate([0, 200, 300], 500),
        throwsFormatException,
      );
    });
  });
}
