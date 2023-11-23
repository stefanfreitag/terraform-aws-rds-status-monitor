from unittest import TestCase, mock
import unittest
import index
import os


class Test(TestCase):
    @mock.patch.dict(os.environ, {"SUPPRESS_STATES": "FAILED"})
    def test_get_valid_states_returns_all_lowercase_list(self):
        result = index.get_valid_states()
        assert result == ["available", "failed"]

    def test_get_valid_states_with_missing_os_environment_key(self):
        result = index.get_valid_states()
        assert result == ["available"]


if __name__ == "__main__":
    unittest.main()
