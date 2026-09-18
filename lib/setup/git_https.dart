/*
 * SPDX-FileCopyrightText: 2026 Shubham Sharma
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

/// Normalize a user-entered clone URL and optionally embed an HTTPS token.
String normalizeCloneUrl(String raw) {
  var url = raw.trim();
  if (url.startsWith('git@github.com/')) {
    url = url.replaceFirst('git@github.com/', 'git@github.com:');
  } else if (url.startsWith('git@gitlab.com/')) {
    url = url.replaceFirst('git@gitlab.com/', 'git@gitlab.com:');
  }
  return url;
}

/// Convert SSH GitHub/GitLab URLs to HTTPS.
String toHttpsCloneUrl(String raw) {
  var url = normalizeCloneUrl(raw);
  final gh = RegExp(r'^git@github\.com:([^/]+)/(.+?)(?:\.git)?$');
  final gl = RegExp(r'^git@gitlab\.com:([^/]+)/(.+?)(?:\.git)?$');
  var m = gh.firstMatch(url);
  if (m != null) {
    return 'https://github.com/${m.group(1)}/${m.group(2)}.git';
  }
  m = gl.firstMatch(url);
  if (m != null) {
    return 'https://gitlab.com/${m.group(1)}/${m.group(2)}.git';
  }
  return url;
}

/// Embed a personal-access / OAuth token in an HTTPS URL.
String authenticatedCloneUrl(String raw, String token) {
  var url = toHttpsCloneUrl(raw);
  token = token.trim();
  if (token.isEmpty) return normalizeCloneUrl(raw);

  final uri = Uri.tryParse(url);
  if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
    // SSH URL and we have a token → prefer HTTPS + token
    url = toHttpsCloneUrl(raw);
  }
  final parsed = Uri.tryParse(url);
  if (parsed == null || parsed.host.isEmpty) return raw;

  return parsed.replace(userInfo: 'x-access-token:$token').toString();
}

bool isHttpsCloneUrl(String raw) {
  final u = normalizeCloneUrl(raw).toLowerCase();
  return u.startsWith('https://') || u.startsWith('http://');
}

bool isSshCloneUrl(String raw) {
  final u = normalizeCloneUrl(raw);
  return u.startsWith('git@') || u.startsWith('ssh://');
}
