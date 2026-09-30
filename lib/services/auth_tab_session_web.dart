// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:math' as math;

const _tabIdKey = '2fit_auth_tab_id';
const _activeTabsKey = '2fit_auth_active_tabs';

/// Returns true when this page appears to be a duplicated browser tab.
/// A duplicated tab can carry sessionStorage, including Firebase Auth's
/// session token. We assign a new tab id and clear only this tab's token.
Future<bool> prepareAuthTabSession() async {
  try {
    final storage = html.window.sessionStorage;
    final local = html.window.localStorage;
    var tabId = storage[_tabIdKey];
    var duplicated = false;

    if (tabId == null || tabId.isEmpty) {
      tabId = _newTabId();
    } else {
      final active = local[_activeTabsKey] ?? '';
      final ids = active.split(',').where((value) => value.isNotEmpty).toSet();
      duplicated = ids.contains(tabId);
    }

    if (duplicated) {
      tabId = _newTabId();
      final keys = storage.keys
          .where((key) => key.startsWith('firebase:authUser:'))
          .toList();
      for (final key in keys) {
        storage.remove(key);
      }
    }

    storage[_tabIdKey] = tabId;
    final active = local[_activeTabsKey] ?? '';
    final ids = active.split(',').where((value) => value.isNotEmpty).toSet();
    ids.add(tabId);
    local[_activeTabsKey] = ids.join(',');
    return duplicated;
  } catch (_) {
    return false;
  }
}

String _newTabId() {
  final random = math.Random();
  return '${DateTime.now().microsecondsSinceEpoch}_${random.nextInt(1 << 32)}';
}
