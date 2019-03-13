"""
This is a database cache. Its a kind of proxy object for Python sqlite3 connection
which operates on a memory copy of the database.

Upon object creation the database is "backed up" to memory. All subsequent
operations are then pefromed on this copy which yields in performance increase.

It is important to explicitly call the close() method once database connection
is no longer needed. The method "backs up" the database back to disk.
"""
import sqlite3

# =============================================================================

class DatabaseCache(object):

    def __init__(self, file_name):

        self.file_name         = file_name
        self.memory_connection = sqlite3.connect(":memory:")
        self.file_connection   = sqlite3.connect(file_name)

        print("Loading database from '{}'".format(self.file_name))
        self.file_connection.backup(self.memory_connection, pages=1, progress=self._progress)
        print("")

    def close(self):

        print("Dumping database to '{}'".format(self.file_name))
        self.memory_connection.backup(self.file_connection, pages=1, progress=self._progress)
        print("")

        self.memory_connection.close()
        self.file_connection.close()

    def _progress(self, status, remaining, total):
        """
        Prints database copy progress.
        """

        if total > 0:
            percent = 100.0 * (total-remaining) / total
        else:
            percent = 100.0

        print("\r%.2f%%" % percent, end="")

    def get_connection(self):
        """
        Returns connection to the database copy in memory
        """
        return self.memory_connection

