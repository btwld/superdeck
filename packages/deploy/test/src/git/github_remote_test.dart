import 'package:superdeck_deploy/src/git/github_remote.dart';
import 'package:test/test.dart';

void main() {
  group('GitHubRemote.parse', () {
    test('parses HTTPS urls with and without .git', () {
      final a = GitHubRemote.parse('https://github.com/btwld/superdeck.git')!;
      expect(a.owner, 'btwld');
      expect(a.repo, 'superdeck');

      final b = GitHubRemote.parse('https://github.com/btwld/superdeck')!;
      expect(b.owner, 'btwld');
      expect(b.repo, 'superdeck');
    });

    test('preserves dots in the repo name (user/org Pages sites)', () {
      final a = GitHubRemote.parse(
        'https://github.com/btwld/btwld.github.io.git',
      )!;
      expect(a.owner, 'btwld');
      expect(a.repo, 'btwld.github.io');

      final b = GitHubRemote.parse('git@github.com:btwld/btwld.github.io')!;
      expect(b.repo, 'btwld.github.io');
    });

    test('parses SSH urls', () {
      final remote = GitHubRemote.parse('git@github.com:btwld/superdeck.git')!;
      expect(remote.owner, 'btwld');
      expect(remote.repo, 'superdeck');
    });

    test('returns null for non-GitHub urls', () {
      expect(GitHubRemote.parse('https://gitlab.com/a/b.git'), isNull);
      expect(GitHubRemote.parse('not a url'), isNull);
    });
  });

  group('baseHref', () {
    test('is the repo subpath for a project site', () {
      expect(const GitHubRemote('btwld', 'superdeck').baseHref, '/superdeck/');
    });

    test('is the domain root for a user/org site', () {
      expect(const GitHubRemote('btwld', 'btwld.github.io').baseHref, '/');
    });
  });

  group('pagesUrl', () {
    test('uses the project subpath for a project site', () {
      expect(
        const GitHubRemote('btwld', 'superdeck').pagesUrl,
        'https://btwld.github.io/superdeck/',
      );
    });

    test('uses the root for a user/org site', () {
      expect(
        const GitHubRemote('btwld', 'btwld.github.io').pagesUrl,
        'https://btwld.github.io/',
      );
    });
  });
}
