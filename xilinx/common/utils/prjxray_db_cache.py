"""
This is a database cache. Its a kind of proxy object for Python sqlite3 connection
which operates on a memory copy of the database.

Upon object creation the database is "backed up" to memory. All subsequent
operations are then pefromed on this copy which yields in performance increase.
"""
import sqlite3
from lib.progressbar_utils import ProgressBar

# =============================================================================


class DatabaseCache(object):
    def __init__(self, file_name, read_only=False):

        self.file_name = file_name
        self.read_only = read_only
        self.bar = None

    def __enter__(self):
        """
        Opens the database file and makes its copy in memory
        """

        # File URI
        if self.read_only:
            uri = "file:%s?mode=ro" % self.file_name
        else:
            uri = "file:%s?mode=rwc" % self.file_name

        # Open connections
        self.memory_connection = sqlite3.connect(":memory:")
        self.file_connection = sqlite3.connect(uri, uri=True)

        # Load the database
        print("Loading database from '{}'".format(self.file_name))
        self.file_connection.backup(
            self.memory_connection, pages=100, progress=self._progress
        )

        self.bar.finish()
        self.bar = None

        # Return the connection
        return self.memory_connection

    def __exit__(self, exc_type, exc_value, traceback):
        """
        Writes back the database to file if the database was open as not read-only
        """

        # Write back only if not read-only
        if not self.read_only:
            if self.memory_connection.in_transaction:
                assert exc_type is not None, "Outstanding transaction, but no exception?"
                self.memory_connection.rollback()

            print("Dumping database to '{}'".format(self.file_name))
            self.memory_connection.backup(
                self.file_connection, pages=100, progress=self._progress
            )

            self.bar.finish()
            self.bar = None

        # Close connections
        self.memory_connection.close()
        self.file_connection.close()

    def _progress(self, status, remaining, total):
        """
        Prints database copy progress.
        """
        if self.bar is None:
            self.bar = ProgressBar(max_value=total)
        else:
            self.bar.update(total - remaining)
