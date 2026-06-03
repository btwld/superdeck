import 'package:superdeck_deploy/src/utils/branch_validation.dart';
import 'package:test/test.dart';

void main() {
  group('isValidBranchName', () {
    test('accepts common branch names', () {
      expect(isValidBranchName('gh-pages'), isTrue);
      expect(isValidBranchName('main'), isTrue);
      expect(isValidBranchName('feature/deploy_v2'), isTrue);
      expect(isValidBranchName('release.1.0'), isTrue);
    });

    test('rejects empty names', () {
      expect(isValidBranchName(''), isFalse);
    });

    test('rejects path traversal', () {
      expect(isValidBranchName('../evil'), isFalse);
      expect(isValidBranchName('a..b'), isFalse);
    });

    test('rejects names that look like flags', () {
      expect(isValidBranchName('-rf'), isFalse);
    });

    test('rejects whitespace and control characters', () {
      expect(isValidBranchName('foo bar'), isFalse);
      expect(isValidBranchName('foo\tbar'), isFalse);
      expect(isValidBranchName('foo\nbar'), isFalse);
    });

    test('rejects shell metacharacters', () {
      expect(isValidBranchName('foo;rm'), isFalse);
      expect(isValidBranchName(r'foo$(whoami)'), isFalse);
    });
  });
}
