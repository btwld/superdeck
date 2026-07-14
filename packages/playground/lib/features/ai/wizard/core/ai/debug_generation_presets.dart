import 'wizard_context.dart';

/// A realistic Wizard payload used to exercise deck generation without running
/// the conversational interview first.
class DebugGenerationPreset {
  const DebugGenerationPreset({
    required this.label,
    required this.description,
    required this.context,
  });

  final String label;
  final String description;
  final WizardContext context;
}

/// Debug-only generation scenarios exposed by the standalone Wizard page.
const debugGenerationPresets = <DebugGenerationPreset>[
  DebugGenerationPreset(
    label: 'Investor pitch (6 slides)',
    description: 'Concise, data-driven product pitch',
    context: WizardContext(
      topic: 'SuperDeck developer presentation platform investor pitch',
      audience: 'Seed-stage technology investors',
      approach: 'Data-driven and persuasive',
      emphasis: [
        'Developer productivity',
        'Market opportunity',
        'Product differentiation',
      ],
      slideCount: 6,
      style: 'Clean and technical',
      colors: ['#F8FAFC', '#0F766E', '#334155'],
      headlineFont: 'poppins',
      bodyFont: 'lato',
    ),
  ),
  DebugGenerationPreset(
    label: 'Quarterly review (8 slides)',
    description: 'Executive product and growth review',
    context: WizardContext(
      topic: 'SuperDeck quarterly product and growth review',
      audience: 'Executive leadership team',
      approach: 'Analytical and decision-oriented',
      emphasis: [
        'Product milestones',
        'Adoption metrics',
        'Next-quarter priorities',
      ],
      slideCount: 8,
      style: 'Editorial and professional',
      colors: ['#FFFBEB', '#92400E', '#57534E'],
      headlineFont: 'playfairDisplay',
      bodyFont: 'openSans',
    ),
  ),
  DebugGenerationPreset(
    label: 'Team onboarding (7 slides)',
    description: 'Practical onboarding for new engineers',
    context: WizardContext(
      topic: 'SuperDeck engineering team onboarding',
      audience: 'New product engineers',
      approach: 'Practical and welcoming',
      emphasis: [
        'Repository architecture',
        'Markdown authoring workflow',
        'Testing and contribution process',
      ],
      slideCount: 7,
      style: 'Friendly and modern',
      colors: ['#F5F3FF', '#5B21B6', '#4B5563'],
      headlineFont: 'montserrat',
      bodyFont: 'inter',
    ),
  ),
];
