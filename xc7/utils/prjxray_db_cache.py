"""
This is a database cache. Its a kind of proxy object for Python sqlite3 connection
which operates on a memory copy of the database.

Upon object creation the database is "backed up" to memory. All subsequent
operations are then pefromed on this copy which yields in performance increase.
"""
import sqlite3
from progressbar.bar import ProgressBar

# =============================================================================

class DatabaseCache(object):

    def __init__(self, file_name):

        self.file_name         = file_name
        self.memory_connection = sqlite3.connect(":memory:")
        self.file_connection   = sqlite3.connect(file_name)
        self.bar = None

        print("Loading database from '{}'".format(self.file_name))
        self.file_connection.backup(self.memory_connection, pages=100, progress=self._progress)

        self.bar.finish()
        self.bar = None

    def __del__(self):

        print("Dumping database to '{}'".format(self.file_name))
        self.memory_connection.backup(self.file_connection, pages=100, progress=self._progress)

        self.bar.finish()
        self.bar = None

        self.memory_connection.close()
        self.file_connection.close()

    def _progress(self, status, remaining, total):
        """
        Prints database copy progress.
        """
        if self.bar is None:
            self.bar = ProgressBar(max_value = total)
        else:
            self.bar.update(total - remaining)

    def get_connection(self):
        """
        Returns connection to the database copy in memory
        """
        return self.memory_connection

