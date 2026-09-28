// Pure decision logic ported from `together_asthma_better_logic_diagrams.md`.
//
// Every function here is a plain, stateless calculation: given some inputs,
// it returns an answer. Nothing here touches widgets, BuildContext, colors,
// or navigation — screens call into this file and decide how to *display*
// the result using the app's existing UI. That split is intentional: it's
// what lets the client's backend logic slot in without changing how
// anything looks.
//
// Doc comments name the source function from the markdown (e.g.
// `computeZone()`) so this file can be diffed against the client's
// prototype later.
//
// Implemented in this pass: diagrams 1, 3, 4, 5, 7.
// Diagrams 2, 6, 8 are flow/repository work and land in later files
// (monitoring_screen.dart, main_screens.dart, health_repository.dart).

import '../models/monitoring.dart' show PeakFlowZone;
import '../models/profile.dart' show Profile;

// =============================================================================
// Diagram 1 — GINA Zone Calculation (`computeZone()`)
// =============================================================================

/// Symptoms that force a Red zone on their own, regardless of PEF%.
///
/// Approved defaults: everything else in the app's symptom list
/// (Cough, Wheezing, Night waking, Fatigue, Other) is "general".
const Set<String> dangerTierSymptoms = {
  'Shortness of breath',
  'Chest pain',
};

bool isDangerSymptom(String symptom) => dangerTierSymptoms.contains(symptom);

bool isGeneralSymptom(String symptom) => !isDangerSymptom(symptom);

/// Diagram 1: a single danger-tier symptom forces Red even if the PEF%
/// looks fine. This overriding behavior is intentional (matches GINA) —
/// it's the first thing to check if a zone result ever looks wrong.
///
/// [pefPercent] must already be resolved against [effectivePersonalBest] —
/// this function never falls back to a predicted value itself.
PeakFlowZone computeZone({
  required Iterable<String> symptoms,
  required double pefPercent,
}) {
  final hasDanger = symptoms.any(isDangerSymptom);
  if (hasDanger || pefPercent < 50) return PeakFlowZone.red;

  final hasGeneral = symptoms.any(isGeneralSymptom);
  if (hasGeneral || pefPercent < 80) return PeakFlowZone.yellow;

  return PeakFlowZone.green;
}

// =============================================================================
// Shared type — Adherence (feeds diagrams 2 and 5)
// =============================================================================

enum AdherenceLevel { good, fair, poor, none }

bool isGoodAdherence(AdherenceLevel level) => level == AdherenceLevel.good;

bool isPoorOrNoAdherence(AdherenceLevel level) =>
    level == AdherenceLevel.poor || level == AdherenceLevel.none;

// =============================================================================
// Diagram 3 — Weighted Critical-Step Scoring
// (`deviceWeightedPct()`, `deviceMissedByPriority()`)
// =============================================================================

/// One inhaler-technique checklist step, as answered by the patient.
///
/// [index] is the step's position in the device's step list (used to report
/// which steps were missed). [critical] marks priming, lip seal, inhale
/// coordination, or breath-hold steps — tagged per device in
/// `inhaler_devices.dart` (next chunk).
class TechniqueStepResult {
  const TechniqueStepResult({
    required this.index,
    required this.critical,
    required this.checked,
  });

  final int index;
  final bool critical;
  final bool checked;

  int get weight => critical ? 2 : 1;
}

/// Diagram 3: percentage is weighted, not a flat step count — missing one
/// critical step costs more than missing one minor step, even though both
/// are "1 step out of N."
///
/// Returns 0 for an empty step list.
double deviceWeightedPct(List<TechniqueStepResult> steps) {
  if (steps.isEmpty) return 0;
  final totalWeight = steps.fold<int>(0, (sum, s) => sum + s.weight);
  if (totalWeight == 0) return 0;
  final checkedWeight = steps
      .where((s) => s.checked)
      .fold<int>(0, (sum, s) => sum + s.weight);
  return checkedWeight / totalWeight * 100;
}

/// Diagram 3: splits missed steps by priority so critical ones can be
/// listed first with distinct styling, ahead of minor ones.
({List<int> critical, List<int> minor}) deviceMissedByPriority(
  List<TechniqueStepResult> steps,
) => (
  critical: steps
      .where((s) => s.critical && !s.checked)
      .map((s) => s.index)
      .toList(),
  minor: steps
      .where((s) => !s.critical && !s.checked)
      .map((s) => s.index)
      .toList(),
);

// =============================================================================
// Diagram 4 — "Possible Causes" card (`possibleCausesCard()`)
// =============================================================================

/// Diagram 4: the *discordant* case — symptoms despite a PEF reading that
/// looks fine. Fires for either zone (Green or Yellow), since a general
/// symptom alone doesn't push PEF% below 80 the way a danger symptom does.
///
/// [pefPercent] must already be resolved against [effectivePersonalBest].
bool showPossibleCausesCard({
  required Iterable<String> symptoms,
  required double pefPercent,
}) {
  if (symptoms.isEmpty) return false;
  return pefPercent >= 80;
}

// =============================================================================
// Diagram 5 — "Combo Guidance" card (`comboGuidanceCard()`)
// =============================================================================

/// Diagram 5: all three conditions are required simultaneously (AND, not
/// OR) — deliberately a stricter, more specific trigger than
/// [showPossibleCausesCard]. Both can be shown at once; they aren't
/// mutually exclusive.
///
/// [triggerExposureConfirmed] must be a confirmed "yes", not an "unknown" —
/// the caller is responsible for that distinction when it wires up the
/// Triggers question (diagram 2).
bool showComboGuidanceCard({
  required Iterable<String> symptoms,
  required AdherenceLevel adherence,
  required bool triggerExposureConfirmed,
}) {
  if (symptoms.isEmpty) return false;
  if (!isPoorOrNoAdherence(adherence)) return false;
  return triggerExposureConfirmed;
}

// =============================================================================
// Diagram 7 — Effective Personal Best (`effectivePersonalBest()`)
// =============================================================================

/// Same predicted-PEF formula already used at onboarding and in Profile —
/// centralized here so [effectivePersonalBest] is self-contained.
int predictedPef({
  required double heightCm,
  required int age,
  required String sex,
}) {
  final value = sex == 'Female'
      ? heightCm * 3.72 + age * 2.24 - 232
      : heightCm * 5.48 - age * 1.93 - 367;
  return value.clamp(1, 1000).round();
}

/// Diagram 7: THE only place any calculation should read the PEF baseline
/// from. Never read `profile.personalBest` or a hand-computed predicted PEF
/// directly anywhere else — that bypasses this fallback and diagrams 1, 3,
/// and 4 will disagree with each other.
int effectivePersonalBest(Profile profile) {
  final set = profile.personalBest;
  if (set != null) return set;
  return predictedPef(
    heightCm: profile.heightCm,
    age: profile.age,
    sex: profile.sex,
  );
}