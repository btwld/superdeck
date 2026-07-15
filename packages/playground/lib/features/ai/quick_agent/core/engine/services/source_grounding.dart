final _domainReferencePattern = RegExp(
  r'(?:(?:https?://|www\.)[^\s<>()\[\]{}]+|'
  r'(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+'
  r'[a-z]{2,}(?:/[^\s<>()\[\]{}]*)?)',
  caseSensitive: false,
);
final _numericClaimPattern = RegExp(
  r'\b(?:Q[1-4]|\d+(?:[,.]\d+)*)(?:%|\b)',
  caseSensitive: false,
);
final _projectionQualifierPattern = RegExp(
  r'\b(?:assum(?:e|ed|ption)|calculat(?:e|ed|ion)|derived?|estimat(?:e|ed)|'
  r'goal|illustrative|planned|project(?:ed|ion)|proposed|scenario|target)\b',
  caseSensitive: false,
);
final _nonCommitmentQualifierPattern = RegExp(
  r'\b(?:concept|direction|estimate|estimated|example|illustrative|option|'
  r'planned|potential|projected|proposal|proposed|scenario|vision|'
  r'(?:in|under) development)\b',
  caseSensitive: false,
);
final _structuralCountPattern = RegExp(
  r'\b(?:act|canvas|capability|category|channel|column|comparison|component|deck|'
  r'decision|dimension|group|home|horizon|hub|inbox|input|layer|level|lever|option|package|'
  r'part|path|phase|pillar|pilot|place|plan|point|principle|section|segment|silo|slide|'
  r'source|stage|step|stream|surface|system|theme|thread|tier|track|variable|'
  r'view|way|workspace)s?\b',
  caseSensitive: false,
);
final _noChangePattern = RegExp(
  r'\b(?:no|zero)\s+(?:change|disruption|impact|migration)\b',
  caseSensitive: false,
);
final _qualitativeZeroPattern = RegExp(
  r'\bzero[-\s]+friction\b',
  caseSensitive: false,
);
final _nonNumericOnePattern = RegExp(
  r'\bone[-\s]+(?:off|time)\b',
  caseSensitive: false,
);
final _unsourcedTemporalClaimPattern = RegExp(
  r'\b(?:(?:in|within|over|after|before|from)\s+(?:a\s+|an\s+|few\s+)?'
  r'(?:minutes?|hours?|days?|weeks?|months?|years?)'
  r'(?:\s+to\s+(?:minutes?|hours?|days?|weeks?|months?|years?))?'
  r'|(?:minutes?|hours?|days?|weeks?|months?|years?)\s+later'
  r'|(?:lose|loses|lost|need|needed|needs|reclaim|reclaimed|reclaims|'
  r'require|required|requires|save|saved|saves|spend|spends|spent|take|'
  r'takes|took)\s+(?:a\s+|an\s+|few\s+)?'
  r'(?:minutes?|hours?|days?|weeks?|months?|years?))\b',
  caseSensitive: false,
);
final _pricingTierLabelPattern = RegExp(
  r'(?:^|\|)\s*(?:[*_`]{1,3})?\s*'
  r'(free|starter|basic|team|pro|professional|business|growth|enterprise)'
  r'\s*(?:[*_`]{1,3})?\s*(?=[:|—–]|\s+-\s+)',
  caseSensitive: false,
);
final _evidenceAmplificationPattern = RegExp(
  r'\b(?:at scale|demonstrated|essential|proved|proven|real-world(?: impact)?|'
  r'significantly|validated|verified)\b',
  caseSensitive: false,
);
final _causalAttributionPattern = RegExp(
  r'\b(?:because of|by (?:automating|eliminating|reducing|removing|unifying)|caused by|'
  r'drives?|led to|resulted in)\b',
  caseSensitive: false,
);
final _metricAmplificationPattern = RegExp(
  r'\b(?:achiev(?:e|ed|es)|agility|allows?|confidence|cycle time|directly|'
  r'eliminat(?:e|ed|es|ing)|high-impact|high-value|hours?|immediate|rapid(?:ly)?|'
  r'reclaim(?:ed|s|ing)|reduc(?:e|ed|es|ing|tion)|significant|successfully)\b',
  caseSensitive: false,
);
final _implementationDetailPattern = RegExp(
  r'\b(?:automat(?:e|ed|es|ic|ically|ing|ion)|classification|correlation|'
  r'documentation|launch team|notifications?|prioriti[sz](?:e|ed|es|ation)|'
  r'self-serve|smart triage|tagging)\b',
  caseSensitive: false,
);
final _betaMethodPattern = RegExp(
  r'\b(?:feedback-driven(?: development)?|intensive (?:software )?testing|'
  r'(?:customer|partner) feedback|testing program)\b',
  caseSensitive: false,
);
final _absoluteCapabilityPattern = RegExp(
  r'\b(?:any(?:\s+[a-z-]+){0,2}\s+(?:source|stack)|built to grow|'
  r'designed (?:for|to)|diverse industries|'
  r'every(?:\s+[a-z-]+){0,2}\s+signal|fast onboarding|high-velocity|immutable|'
  r'maps? back to|never lost|no(?:\s+[a-z-]+){0,2}\s+(?:disruption|migration)|'
  r'operates alongside|overlay analytics|permanent|predictable scaling|pure overlay|'
  r'rapid(?:\s+[a-z-]+){0,2}\s+(?:adoption|deployment|setup)|'
  r'shareable summaries|source data pristine|team sizes|time-to-value|'
  r'traceable links|universal capture|'
  r'without(?:\s+[a-z-]+){0,3}\s+(?:disruption|friction|migration))\b',
  caseSensitive: false,
);

// These are concrete product, security, availability, evidence, or commercial
// claims that a category-only brief does not establish. The validator allows
// them when the user supplied the exact phrase or when the individual claim is
// visibly marked as planned, proposed, illustrative, or otherwise hypothetical.
const _highRiskCommitmentPhrases = {
  'access controls',
  'additive layer',
  'advanced workflows',
  'audit logs',
  'audit logging',
  'audit-ready',
  'automated consolidation',
  'automated deduplication',
  'automated ingestion',
  'automated prioritization',
  'automated reporting',
  'automated tagging',
  'automated workflows',
  'automated workspace provisioning',
  'available to everyone',
  'award-winning',
  'certification',
  'certified',
  'capture every signal',
  'chronological trail',
  'community support',
  'compliant',
  'compliant with',
  'compliance',
  'costly rollbacks',
  'cross-platform tagging',
  'cross-product views',
  'custom event ingestion',
  'custom sdk',
  'data residency',
  'data warehouse',
  'data synchronization',
  'dedicated onboarding',
  'dedicated support',
  'developer documentation',
  'developer sdk',
  'design partners today',
  'drag-and-drop',
  'early access',
  'enterprise-grade',
  'enterprise ready',
  'every release',
  'every signal source',
  'free trial',
  'full api',
  'full governance',
  'gdpr',
  'global scale',
  'granular permissions',
  'granular permission',
  'guided connection',
  'guided evidence mapping',
  'guaranteed',
  'hipaa',
  'industry leaders',
  'industry-leading',
  'integration-layer access',
  'instant connection',
  'is open',
  'launch in minutes',
  'leading product teams',
  'localized control',
  'market-leading',
  'mobile experience',
  'mobile view',
  'money-back',
  'most requested',
  'native connectors',
  'native integrations',
  'no credit card',
  'now live',
  'oauth',
  'one-click',
  'opening access',
  'open-source adapters',
  'organizational memory',
  'partner marketplace',
  'permanent logs',
  'permanent links',
  'permanent record',
  'patented',
  'pre-built connectors',
  'pressure-tested',
  'priority support',
  'production environments',
  'production-scale',
  'proven at scale',
  'proven in beta',
  'proven in production',
  'purely additive',
  'rbac',
  'read-only',
  'ready to scale',
  'real-time',
  'real-world workflow',
  'real-world workloads',
  'robust api',
  'scalable tiers',
  'searchable',
  'seat-based pricing',
  'security validated',
  'sign up',
  'soc 2',
  'soc2',
  'sso',
  'stable performance',
  'standard connectors',
  'standard protocols',
  'stakeholder alignment',
  'stakeholder consensus',
  'status meetings',
  'team-based training',
  'tested against',
  'time-to-insight',
  'total visibility',
  'unlimited data sources',
  'validated by',
  'validated in the real world',
  'activate the shared',
  'advanced api',
  'already proven',
  'automated synthesis',
  'automating the synthesis',
  'better visibility',
  'centralize every signal',
  'cluster qualitative',
  'compatible with',
  'connect your initial',
  'custom governance',
  'data migrations',
  'diverse cross-functional',
  'etl pipelines',
  'evidence taxonomy',
  'faster than their peers',
  'feedback from',
  'findings from',
  'fully extensible',
  'grow with your usage',
  'growth tier',
  'immediate context',
  'increased confidence',
  'is here',
  'kills experiment momentum',
  'most expensive',
  'multi-dimensional view',
  'multiple industries',
  'permanent archive',
  'permanent history',
  'proven performance',
  'reduced friction',
  'rigorous results',
  'scalable adoption',
  'seamless context',
  'signals flow directly',
  'speak with our technical team',
  'standard tier',
  'support options',
  'tag customer feedback',
  'unifying your signals today',
  'validated during',
  'validated in',
  'visit the signal canvas booth',
  'wasted development cycles',
  'waitlist',
  'webhook triggers',
  'works alongside',
  'without changing your infrastructure',
  'zero-friction',
  "world's first",
  'api-first',
  'auto collect',
  'auto collects',
  'auto-collect',
  'auto-collects',
  'automating manual',
  'direct authentication',
  'exclusive launch event access',
  'immediate impact',
  'live updating',
  'live-updating',
  'programmatic access',
  'real-world environments',
  'rest api',
  'seamless integration',
  'tested in complex',
  'trigger downstream',
  'validated across',
  'without requiring data migration',
  'without requiring migration',
};

// Only concrete claims with meaningful legal, commercial, security,
// availability, or credential risk should force another model request. Broader
// editorial and evidence-strength language remains useful diagnostic evidence,
// but regex matches such as "prioritizes" or "designed to" are not reliable
// enough to block a generated deck.
const _blockingCommitmentPhrases = {
  'access controls',
  'audit logs',
  'audit logging',
  'audit-ready',
  'available to everyone',
  'award-winning',
  'certification',
  'certified',
  'compliant',
  'compliant with',
  'data residency',
  'early access',
  'enterprise-grade',
  'enterprise ready',
  'free trial',
  'gdpr',
  'granular permission',
  'granular permissions',
  'guaranteed',
  'hipaa',
  'is open',
  'money-back',
  'no credit card',
  'now live',
  'oauth',
  'opening access',
  'patented',
  'production environments',
  'production-scale',
  'proven in production',
  'rbac',
  'read-only',
  'security validated',
  'seat-based pricing',
  'sign up',
  'soc 2',
  'soc2',
  'sso',
  'waitlist',
};
const _numberWords = {
  'zero': '0',
  'one': '1',
  'two': '2',
  'three': '3',
  'four': '4',
  'five': '5',
  'six': '6',
  'seven': '7',
  'eight': '8',
  'nine': '9',
  'ten': '10',
  'eleven': '11',
  'twelve': '12',
  'dozen': '12',
  'thirteen': '13',
  'fourteen': '14',
  'fifteen': '15',
  'sixteen': '16',
  'seventeen': '17',
  'eighteen': '18',
  'nineteen': '19',
  'twenty': '20',
};
const _fractionWords = {'half': '50%', 'quarter': '25%', 'third': '33%'};
const _factAnchorStopWords = {
  'a',
  'an',
  'and',
  'are',
  'as',
  'at',
  'be',
  'by',
  'change',
  'changed',
  'changes',
  'decision',
  'efficiency',
  'for',
  'faster',
  'from',
  'gain',
  'in',
  'impact',
  'increase',
  'into',
  'is',
  'it',
  'less',
  'more',
  'of',
  'on',
  'or',
  'our',
  'percent',
  'percentage',
  'productivity',
  'reclaimed',
  'recovered',
  'reduction',
  'slower',
  'spend',
  'spends',
  'spent',
  'that',
  'target',
  'the',
  'their',
  'these',
  'this',
  'team',
  'time',
  'to',
  'use',
  'velocity',
  'was',
  'were',
  'with',
};
const _groundedPurposeStopWords = {
  'a',
  'an',
  'and',
  'audience',
  'display',
  'experience',
  'for',
  'in',
  'let',
  'live',
  'open',
  'page',
  'provided',
  'show',
  'supplied',
  'the',
  'this',
  'to',
  'use',
  'using',
  'where',
  'with',
};

/// Extracts normalized hosts from URLs and visible domain-like references.
Set<String> extractReferencedDomains(Iterable<String> values) {
  final domains = <String>{};
  for (final value in values) {
    for (final match in _domainReferencePattern.allMatches(value)) {
      final token = match.group(0)!;
      final uri = Uri.tryParse(
        token.startsWith(RegExp(r'https?://', caseSensitive: false))
            ? token
            : 'https://$token',
      );
      final host = uri?.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
      if (host != null && host.isNotEmpty) domains.add(host);
    }
  }
  return domains;
}

/// Finds distinctive destination or experience terms omitted from a handoff.
///
/// Generic instruction words such as "open", "live", and "experience" are
/// intentionally ignored so a supplied identity such as "SuperDeck" cannot be
/// silently replaced with the fictional product described by the deck.
Set<String> findMissingGroundedPurposeTerms({
  required String purpose,
  required Iterable<String> values,
}) {
  final requiredTerms = _groundedPurposeTerms(purpose);
  if (requiredTerms.isEmpty) return const {};
  final actualTerms = _groundedPurposeTerms(values.join('\n'));
  return requiredTerms.difference(actualTerms);
}

Set<String> _groundedPurposeTerms(String value) =>
    RegExp(r'[\p{L}\p{N}]+', unicode: true)
        .allMatches(value)
        .map((match) => match.group(0)!.toLowerCase())
        .where((word) {
          return word.length > 2 && !_groundedPurposeStopWords.contains(word);
        })
        .toSet();

/// Extracts normalized numeric tokens that can represent audience-facing facts.
Set<String> extractNumericClaims(Iterable<String> values) {
  final claims = <String>{};
  for (final value in values) {
    final numericWordSource = value
        .replaceAll(_qualitativeZeroPattern, '')
        .replaceAll(_nonNumericOnePattern, '');
    for (final match in _numericClaimPattern.allMatches(value)) {
      claims.add(match.group(0)!.toUpperCase().replaceAll(',', ''));
    }
    for (final entry in _numberWords.entries) {
      if (RegExp(
        '\\b${RegExp.escape(entry.key)}\\b',
        caseSensitive: false,
      ).hasMatch(numericWordSource)) {
        claims.add(entry.value);
      }
    }
    for (final entry in _fractionWords.entries) {
      if (_containsFractionClaim(value, entry.key)) {
        claims.add(entry.value);
      }
    }
  }
  return claims;
}

bool _containsFractionClaim(String value, String word) => switch (word) {
  'quarter' => RegExp(
    r'\b(?:(?:a|one|about|almost|nearly|roughly)\s+quarter|quarter\s+of)\b',
    caseSensitive: false,
  ).hasMatch(value),
  'third' => RegExp(
    r'\b(?:(?:a|one|about|almost|nearly|roughly)\s+third|third\s+of|one-third)\b',
    caseSensitive: false,
  ).hasMatch(value),
  _ => RegExp(
    '\\b${RegExp.escape(word)}\\b',
    caseSensitive: false,
  ).hasMatch(value),
};

/// Extracts numeric tokens supplied by the user; context validation prevents
/// structural counts from being reused as unrelated evidence.
Set<String> extractGroundedNumericClaims(Iterable<String> values) => {
  for (final value in values)
    for (final context in _numericFactContexts(value))
      ..._nonStructuralNumericClaims(context),
};

/// Gives the repair model an exact correction for unsupported numeric claims.
String unsupportedNumericClaimRepairGuidance(Set<String> claims) {
  final qualitativeZeroGuidance = claims.contains('0') || claims.contains('0%')
      ? ' Delete every occurrence of the word zero, 0, and 0% from the '
            'affected slide fields, including titles and idioms such as '
            '"zero to insight" or "zero disruptive impact". When the source '
            'says "no change", preserve those exact qualitative words; '
            'otherwise remove the claim.'
      : '';
  return 'Remove them or label the containing copy as a projection, estimate, '
      'assumption, calculation, scenario, or planned target.'
      '$qualitativeZeroGuidance';
}

/// Extracts audience-facing metrics while omitting small structural counts.
Set<String> extractAudienceNumericClaims(Iterable<String> values) => {
  for (final value in values)
    for (final context in _numericFactContexts(value))
      ..._nonStructuralNumericClaims(context),
};

/// Extracts source sentences containing supplied numeric or no-change facts.
List<String> extractGroundedNumericFactSnippets(String value) {
  final snippets = <String>[];
  final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  for (final candidate in _sentenceLikeSnippets(normalized)) {
    final snippet = candidate.trim();
    if (snippet.isEmpty ||
        !_numericFactContexts(snippet).any(_hasGroundedFactContext)) {
      continue;
    }
    snippets.add(snippet);
  }
  return snippets;
}

Iterable<String> _sentenceLikeSnippets(String value) sync* {
  var start = 0;
  for (var index = 0; index < value.length; index++) {
    final character = value.codeUnitAt(index);
    final isQuestionOrExclamation = character == 0x3F || character == 0x21;
    final isPeriod = character == 0x2E;
    if (!isQuestionOrExclamation && !isPeriod) continue;
    if (isPeriod &&
        index > 0 &&
        index + 1 < value.length &&
        _isAsciiDigit(value.codeUnitAt(index - 1)) &&
        _isAsciiDigit(value.codeUnitAt(index + 1))) {
      continue;
    }
    yield value.substring(start, index + 1);
    start = index + 1;
  }
  if (start < value.length) yield value.substring(start);
}

bool _isAsciiDigit(int codeUnit) => codeUnit >= 0x30 && codeUnit <= 0x39;

/// Maps each supplied numeric token to nearby words that preserve its meaning.
Map<String, Set<String>> extractNumericFactAnchors(String value) {
  final anchors = <String, Set<String>>{};
  for (final entry in _extractNumericFactAnchorGroups(value).entries) {
    anchors[entry.key] = {for (final group in entry.value) ...group};
  }
  return anchors;
}

Map<String, List<Set<String>>> _extractNumericFactAnchorGroups(String value) {
  final anchors = <String, List<Set<String>>>{};
  for (final context in _numericFactContexts(value)) {
    for (final claim in _nonStructuralNumericClaims(context)) {
      final words = _numericFactAnchorWords(context, claim);
      if (words.isEmpty) continue;
      anchors.putIfAbsent(claim, () => []).add(words);
    }
  }
  return anchors;
}

Set<String> _numericFactAnchorWords(String context, String claim) {
  final span = _numericClaimSpan(context, claim);
  if (span == null) return _significantWords(context);
  var beforeStart = 0;
  var afterEnd = context.length;
  for (final match in _numericClaimPattern.allMatches(context)) {
    if (match.end <= span.start) beforeStart = match.end;
    if (match.start >= span.end) {
      afterEnd = match.start;
      break;
    }
  }
  final after = _nearbyWordTokens(
    context.substring(span.end, afterEnd),
    takeLast: false,
  );
  final afterWords = _significantWords(after.join(' '));
  if (afterWords.isNotEmpty) return afterWords;
  final before = _nearbyWordTokens(
    context.substring(beforeStart, span.start),
    takeLast: true,
  );
  return _significantWords(before.join(' '));
}

({int start, int end})? _numericClaimSpan(String context, String claim) {
  final spans = <({int start, int end})>[];
  for (final match in _numericClaimPattern.allMatches(context)) {
    if (match.group(0)!.toUpperCase().replaceAll(',', '') == claim) {
      spans.add((start: match.start, end: match.end));
    }
  }
  for (final entry in _numberWords.entries) {
    if (entry.value != claim) continue;
    for (final match in RegExp(
      '\\b${RegExp.escape(entry.key)}\\b',
      caseSensitive: false,
    ).allMatches(context)) {
      spans.add((start: match.start, end: match.end));
    }
  }
  for (final entry in _fractionWords.entries) {
    if (entry.value != claim) continue;
    for (final match in RegExp(
      '\\b${RegExp.escape(entry.key)}\\b',
      caseSensitive: false,
    ).allMatches(context)) {
      spans.add((start: match.start, end: match.end));
    }
  }
  if (spans.isEmpty) return null;
  spans.sort((first, second) => first.start.compareTo(second.start));
  return spans.first;
}

List<String> _nearbyWordTokens(String value, {required bool takeLast}) {
  final tokens = RegExp(
    r'[\p{L}]+',
    unicode: true,
  ).allMatches(value).map((match) => match.group(0)!).toList();
  const window = 5;
  if (tokens.length <= window) return tokens;
  return takeLast
      ? tokens.sublist(tokens.length - window)
      : tokens.sublist(0, window);
}

/// Whether copy visibly marks unsupported arithmetic as non-observed evidence.
bool hasProjectionQualifier(String value) =>
    _projectionQualifierPattern.hasMatch(value);

/// Finds numbers that are neither supplied facts nor clearly structural copy.
Set<String> findUnsupportedNumericClaims({
  required Iterable<String> values,
  required Set<String> groundedClaims,
}) {
  final unsupported = <String>{};
  for (final value in values) {
    if (hasProjectionQualifier(value)) continue;
    for (final context in _numericFactContexts(value)) {
      final candidates = extractNumericClaims([
        context,
      ]).difference(groundedClaims);
      if (_structuralCountPattern.hasMatch(context)) {
        candidates.removeWhere(_isSmallStructuralCount);
      }
      candidates.removeWhere(
        (claim) => _isStructuralEnumeration(context, claim),
      );
      unsupported.addAll(candidates);
    }
  }
  return unsupported;
}

/// Finds supplied numbers used without any of their nearby source-fact words.
Set<String> findNumericContextMismatches({
  required Iterable<String> values,
  required String userIntent,
  bool allowSlideContextFallback = false,
}) {
  final anchorGroups = _extractNumericFactAnchorGroups(userIntent);
  final copyValues = values.toList(growable: false);
  final slideWords = _significantWords(copyValues.join('\n'));
  final mismatches = <String>{};
  for (final value in copyValues) {
    if (hasProjectionQualifier(value)) continue;
    for (final context in _numericFactContexts(value)) {
      final copyWords = _significantWords(context);
      for (final claim in _nonStructuralNumericClaims(context)) {
        if (_isStructuralEnumeration(context, claim)) continue;
        final claimAnchorGroups = anchorGroups[claim];
        if (claimAnchorGroups == null || claimAnchorGroups.isEmpty) continue;
        if (_addsOpenEndedQualifier(
          context: context,
          claim: claim,
          userIntent: userIntent,
        )) {
          mismatches.add(claim);
          continue;
        }
        if (_changesNumericClaimOwnership(
          context: context,
          claim: claim,
          userIntent: userIntent,
        )) {
          mismatches.add(claim);
          continue;
        }
        if (_matchesAnyAnchorGroup(copyWords, claimAnchorGroups)) continue;
        if ((copyWords.isEmpty || allowSlideContextFallback) &&
            _matchesAnyAnchorGroup(slideWords, claimAnchorGroups)) {
          continue;
        }
        mismatches.add(claim);
      }
    }
  }
  return mismatches;
}

bool _matchesAnyAnchorGroup(
  Set<String> copyWords,
  List<Set<String>> anchorGroups,
) => anchorGroups.any((required) {
  final matched = required.intersection(copyWords).length;
  if (matched == required.length) return true;
  return required.length >= 3 && matched >= required.length - 1;
});

bool _changesNumericClaimOwnership({
  required String context,
  required String claim,
  required String userIntent,
}) {
  if (!RegExp(r'\b(?:you|your)\b', caseSensitive: false).hasMatch(context)) {
    return false;
  }
  return !_numericFactContexts(userIntent)
      .where((source) => extractNumericClaims([source]).contains(claim))
      .any(
        (source) =>
            RegExp(r'\b(?:you|your)\b', caseSensitive: false).hasMatch(source),
      );
}

/// Finds commercial, legal, or credential claims absent from the user brief.
Set<String> findUnsupportedCommitmentPhrases({
  required Iterable<String> values,
  required String userIntent,
  bool inspectMetricCausality = true,
}) {
  final copyValues = values.toList(growable: false);
  final supplied = userIntent.toLowerCase();
  final groundedNumbers = extractGroundedNumericClaims([userIntent]);
  final containsGroundedObservation =
      inspectMetricCausality &&
      extractNumericClaims(copyValues).intersection(groundedNumbers).isNotEmpty;
  final unsupported = <String>{};
  for (final value in copyValues) {
    for (final context in _commitmentContexts(value)) {
      final copy = context.toLowerCase();
      final qualified = _nonCommitmentQualifierPattern.hasMatch(copy);
      for (final phrase in _highRiskCommitmentPhrases) {
        if (copy.contains(phrase) &&
            !supplied.contains(phrase) &&
            !qualified &&
            !_isBenignCommitmentUse(copy, phrase) &&
            !_isNegatedPhrase(copy, phrase)) {
          unsupported.add(phrase);
        }
      }
      for (final pattern in [
        _evidenceAmplificationPattern,
        if (containsGroundedObservation) _causalAttributionPattern,
        if (containsGroundedObservation) _metricAmplificationPattern,
        _implementationDetailPattern,
        _betaMethodPattern,
        _absoluteCapabilityPattern,
      ]) {
        for (final match in pattern.allMatches(copy)) {
          final phrase = match.group(0)!;
          if (!supplied.contains(phrase) &&
              !qualified &&
              !_isNegatedPhrase(copy, phrase)) {
            unsupported.add(phrase);
          }
        }
      }
      for (final match in _pricingTierLabelPattern.allMatches(copy)) {
        final label = match.group(1)!.toLowerCase();
        if (!qualified && !_userSuppliesPricingTier(supplied, label)) {
          unsupported.add('pricing tier "$label"');
        }
      }
      for (final match in _unsourcedTemporalClaimPattern.allMatches(copy)) {
        final phrase = match.group(0)!;
        if (!supplied.contains(phrase) && !qualified) {
          unsupported.add(phrase);
        }
      }
    }
  }
  return unsupported;
}

/// Whether unsupported commitment findings are concrete enough to block.
bool hasBlockingCommitmentClaim(Iterable<String> phrases) => phrases.any(
  (phrase) =>
      _blockingCommitmentPhrases.contains(phrase) ||
      phrase.startsWith('pricing tier "'),
);

bool _userSuppliesPricingTier(String supplied, String label) => RegExp(
  '(?:\\b${RegExp.escape(label)}\\b.{0,24}\\btier\\b|'
  '\\btier\\b.{0,24}\\b${RegExp.escape(label)}\\b|'
  '\\b${RegExp.escape(label)}\\b\\s*[:|])',
  caseSensitive: false,
).hasMatch(supplied);

bool _isBenignCommitmentUse(String copy, String phrase) =>
    phrase == 'compliance' &&
    RegExp(
      r'\b(?:plan|planning|process|roadmap|schedule) compliance\b',
      caseSensitive: false,
    ).hasMatch(copy);

bool _addsOpenEndedQualifier({
  required String context,
  required String claim,
  required String userIntent,
}) {
  final pattern = RegExp('${RegExp.escape(claim)}\\s*\\+');
  return pattern.hasMatch(context) && !pattern.hasMatch(userIntent);
}

Iterable<String> _commitmentContexts(String value) sync* {
  final normalized = value.replaceAll(RegExp(r'[^\S\n]+'), ' ').trim();
  if (normalized.isEmpty) return;
  for (final sentence in _sentenceLikeSnippets(normalized)) {
    for (final context in sentence.split(RegExp(r'(?:\n+|[;]+)'))) {
      final trimmed = context.trim();
      if (trimmed.isNotEmpty) yield trimmed;
    }
  }
}

bool _isNegatedPhrase(String copy, String phrase) => RegExp(
  r'\b(?:avoid(?:ed|ing)?|no|not|omit(?:ted|ting)?|remove(?:d|ing)?|without)\b'
  r'(?:\s+[a-z-]+){0,3}\s+'
  '${RegExp.escape(phrase)}',
  caseSensitive: false,
).hasMatch(copy);

Set<String> _significantWords(String value) =>
    RegExp(r'[\p{L}]+', unicode: true)
        .allMatches(value)
        .map((match) => _normalizeFactWord(match.group(0)!))
        .where((word) {
          return word.length > 2 &&
              !_factAnchorStopWords.contains(word) &&
              !_numberWords.containsKey(word) &&
              !_fractionWords.containsKey(word);
        })
        .toSet();

String _normalizeFactWord(String value) {
  var word = value.toLowerCase();
  if (word.length > 4 && word.endsWith('s') && !word.endsWith('ss')) {
    word = word.substring(0, word.length - 1);
  }
  return switch (word) {
    'adoption' || 'migration' || 'rollout' || 'transition' => 'adoption',
    'canvas' || 'place' || 'surface' => 'workspace',
    'company' || 'customer' || 'enterprise' || 'organization' => 'partner',
    'connector' || 'integration' || 'toolchain' => 'source',
    _ => word,
  };
}

Iterable<String> _numericFactContexts(String value) sync* {
  final normalized = value.replaceAll(RegExp(r'[^\S\n]+'), ' ').trim();
  if (normalized.isEmpty) return;
  for (final sentence in _sentenceLikeSnippets(normalized)) {
    final sentenceBody = sentence.replaceFirst(RegExp(r'[.!?]+$'), '');
    for (final context in sentenceBody.split(
      RegExp(r'(?:\n+|[;:,)]+|\s+and\s+)', caseSensitive: false),
    )) {
      final trimmed = context.trim();
      if (trimmed.isNotEmpty) yield trimmed;
    }
  }
}

Set<String> _nonStructuralNumericClaims(String context) {
  final claims = extractNumericClaims([context]);
  if (!_structuralCountPattern.hasMatch(context)) return claims;
  claims.removeWhere((claim) {
    final count = int.tryParse(claim);
    return count != null && count >= 1 && count <= 4;
  });
  return claims;
}

bool _isSmallStructuralCount(String claim) {
  final count = int.tryParse(claim);
  return count != null && count >= 1 && count <= 4;
}

bool _isStructuralEnumeration(String context, String claim) {
  if (!_isSmallStructuralCount(claim)) return false;
  final marker = context.replaceAll(RegExp(r'[#*_`\[(\s]'), '').trim();
  return marker == claim;
}

bool _hasGroundedFactContext(String context) =>
    _nonStructuralNumericClaims(context).isNotEmpty ||
    _noChangePattern.hasMatch(context);
