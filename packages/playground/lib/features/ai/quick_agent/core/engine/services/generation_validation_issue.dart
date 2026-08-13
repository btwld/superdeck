/// Stable identifiers for generation validation and repair behavior.
enum GenerationValidationCode {
  invalidResponse,
  invalidSchema,
  slideCount,
  slideIdentity,
  planStructure,
  themeResolution,
  typography,
  paletteContrast,
  elementGrounding,
  visibleSourceGrounding,
  numericGrounding,
  numericMeaning,
  metricIntent,
  commitmentGrounding,
  treatmentIntent,
  designRhythm,
  slideStructure,
  planFulfillment,
  widgetArguments,
  markdownContract,
  handoffPurpose,
  contentDensity,
}

/// Broad validation domains used by diagnostics and quality reporting.
enum GenerationValidationCategory {
  schema,
  structure,
  grounding,
  factual,
  accessibility,
  quality,
}

/// Whether an issue blocks generation or remains a quality diagnostic.
enum GenerationValidationSeverity { blocking, diagnostic }

/// Location of an issue within the generated payload.
enum GenerationValidationLocation {
  deck,
  planSlide,
  visibleContent,
  speakerComments,
}

/// One stable validation issue with human-readable repair guidance.
final class GenerationValidationIssue {
  final GenerationValidationCode code;
  final GenerationValidationCategory category;
  final GenerationValidationSeverity severity;
  final GenerationValidationLocation location;
  final String message;
  final String? slideKey;
  final bool locallyRepairable;

  const GenerationValidationIssue({
    required this.code,
    required this.category,
    required this.severity,
    required this.location,
    required this.message,
    this.slideKey,
    this.locallyRepairable = false,
  });

  bool get isBlocking => severity == .blocking;

  Map<String, Object?> toJson() => {
    'code': code.name,
    'category': category.name,
    'severity': severity.name,
    'location': location.name,
    'slideKey': ?slideKey,
    'locallyRepairable': locallyRepairable,
    'message': message,
  };
}

/// Builds consistently classified issues without coupling behavior to text.
final class GenerationValidationCollector {
  final GenerationValidationCode _code;
  final GenerationValidationCategory _category;
  final GenerationValidationSeverity _severity;
  final GenerationValidationLocation _location;
  final String? _slideKey;
  final bool _locallyRepairable;
  final List<GenerationValidationIssue> _issues;

  GenerationValidationCollector({
    GenerationValidationCode code = .planStructure,
    GenerationValidationCategory category = .structure,
    GenerationValidationSeverity severity = .blocking,
    GenerationValidationLocation location = .deck,
    String? slideKey,
    bool locallyRepairable = false,
    List<GenerationValidationIssue>? issues,
  }) : _code = code,
       _category = category,
       _severity = severity,
       _location = location,
       _slideKey = slideKey,
       _locallyRepairable = locallyRepairable,
       _issues = issues ?? <GenerationValidationIssue>[];

  List<GenerationValidationIssue> get issues => _issues;

  void add(String message) {
    _issues.add(
      GenerationValidationIssue(
        code: _code,
        category: _category,
        severity: _severity,
        location: _location,
        message: message,
        slideKey: _slideKey,
        locallyRepairable: _locallyRepairable,
      ),
    );
  }

  void addAll(Iterable<String> messages) {
    for (final message in messages) {
      add(message);
    }
  }

  GenerationValidationCollector scoped({
    GenerationValidationCode? code,
    GenerationValidationCategory? category,
    GenerationValidationSeverity? severity,
    GenerationValidationLocation? location,
    String? slideKey,
    bool? locallyRepairable,
  }) => .new(
    code: code ?? _code,
    category: category ?? _category,
    severity: severity ?? _severity,
    location: location ?? _location,
    slideKey: slideKey ?? _slideKey,
    locallyRepairable: locallyRepairable ?? _locallyRepairable,
    issues: _issues,
  );
}

extension GenerationValidationIssueList on Iterable<GenerationValidationIssue> {
  List<String> get messages => [for (final issue in this) issue.message];

  List<GenerationValidationIssue> get blockingIssues => [
    for (final issue in this)
      if (issue.isBlocking) issue,
  ];

  List<GenerationValidationIssue> get uniqueIssues {
    final seen = <String>{};

    return [
      for (final issue in this)
        if (seen.add(
          '${issue.code.name}|${issue.location.name}|'
          '${issue.slideKey ?? ''}|'
          '${issue.message}',
        ))
          issue,
    ];
  }
}
