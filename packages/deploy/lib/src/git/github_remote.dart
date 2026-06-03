/// A parsed GitHub `owner/repo` pair derived from a git remote URL.
class GitHubRemote {
  /// The repository owner (user or organization).
  final String owner;

  /// The repository name (without the `.git` suffix).
  final String repo;

  const GitHubRemote(this.owner, this.repo);

  static final _httpsPattern = RegExp(
    r'https://github\.com/([^/]+)/([^/.]+)(\.git)?',
  );
  static final _sshPattern = RegExp(
    r'git@github\.com:([^/]+)/([^/.]+)(\.git)?',
  );

  /// Parses a git remote [url] in HTTPS or SSH form, or returns `null` if it is
  /// not a recognizable GitHub URL.
  static GitHubRemote? parse(String url) {
    final https = _httpsPattern.firstMatch(url);
    if (https != null) {
      return GitHubRemote(https.group(1)!, https.group(2)!);
    }

    final ssh = _sshPattern.firstMatch(url);
    if (ssh != null) {
      return GitHubRemote(ssh.group(1)!, ssh.group(2)!);
    }

    return null;
  }

  /// The `--base-href` value for serving under a Pages project subpath.
  String get baseHref => '/$repo/';

  /// The public GitHub Pages URL for the given [branch].
  String pagesUrl(String branch) {
    if (repo == '$owner.github.io' && (branch == 'main' || branch == 'master')) {
      return 'https://$owner.github.io/';
    }

    return 'https://$owner.github.io/$repo/';
  }
}
