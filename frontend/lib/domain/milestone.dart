enum MilestoneKind { clock, bolt, drop, flame }

enum ReviewStatus { draft, reviewed }

/// An educational, approximate marker on the ring. It is a visual reference
/// for elapsed time only — never evidence that a biological event happened.
class Milestone {
  const Milestone({
    required this.id,
    required this.kind,
    required this.title,
    required this.short,
    required this.offsetMinutes,
    required this.window,
    required this.body,
    this.sourceReference,
    this.reviewStatus = ReviewStatus.draft,
    this.enabled = true,
  });

  final String id;
  final MilestoneKind kind;
  final String title;
  final String short;
  final int offsetMinutes;
  final String window;
  final String body;
  final String? sourceReference;
  final ReviewStatus reviewStatus;
  final bool enabled;

  Duration get offset => Duration(minutes: offsetMinutes);
}

/// Shown on every milestone detail (FR-13).
const milestoneDisclaimer =
    'Timing varies between individuals. This timer records time only. It cannot measure ketones or tell what is happening in your body.';

/// Milestone configuration lives here as data, not inside the ring widget.
/// Draft copy from the mockup: requires qualified health review before release.
const defaultMilestones = <Milestone>[
  Milestone(
    id: 'start',
    kind: MilestoneKind.clock,
    title: 'Fast begins',
    short: 'Fast begins',
    offsetMinutes: 0,
    window: 'The moment you press Start',
    body: 'This marks when you started recording. It is a time stamp only. Nothing about your body is being measured.',
  ),
  Milestone(
    id: 'fuel',
    kind: MilestoneKind.bolt,
    title: 'Fuel use shifts',
    short: 'Fuel use shifts',
    offsetMinutes: 10 * 60,
    window: 'Roughly 8–12 hours (estimate)',
    body: 'Some hours after eating, the body may rely less on recently eaten food and more on stored energy. When this happens differs widely between people.',
  ),
  Milestone(
    id: 'ketosis',
    kind: MilestoneKind.drop,
    title: 'Ketosis may begin',
    short: 'Ketosis may begin',
    offsetMinutes: 14 * 60,
    window: 'Roughly 12–18 hours (estimate)',
    body: 'During fasting, the body may increase its use of fat-derived ketones over time. The timing varies depending on factors such as recent meals, activity, individual metabolism and other circumstances.',
  ),
  Milestone(
    id: 'later',
    kind: MilestoneKind.flame,
    title: 'Later fasting stage',
    short: 'Later stage',
    offsetMinutes: 20 * 60,
    window: 'Roughly 18–24 hours (estimate)',
    body: 'Over longer periods, the body’s fuel use may keep changing. This is an optional educational marker, not a goal, and it does not mean any specific process has happened.',
  ),
];
