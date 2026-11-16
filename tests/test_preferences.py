"""Guard against losing unrelated application settings during a restore."""
import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('preferences', Path(__file__).parents[1] / 'macos/preferences.py')
preferences = importlib.util.module_from_spec(spec)
spec.loader.exec_module(preferences)


class PreferenceRestoreTests(unittest.TestCase):
    def test_preserves_unmanaged_settings_and_binary_theme_data(self):
        merged, changed = preferences.merge_preferences(
            {'unmanaged': 'keep', 'font': 'old'},
            {'font': 'SF Mono', 'theme': {'data': 'aGVsbG8='}},
        )
        self.assertEqual(merged, {'unmanaged': 'keep', 'font': 'SF Mono', 'theme': b'hello'})
        self.assertEqual(changed, ['font', 'theme'])

    def test_second_restore_has_no_changes(self):
        selected = {'font': 'SF Mono', 'theme': {'data': 'aGVsbG8='}}
        current, _ = preferences.merge_preferences({'unmanaged': 1}, selected)
        merged, changed = preferences.merge_preferences(current, selected)
        self.assertEqual(merged, current)
        self.assertEqual(changed, [])
