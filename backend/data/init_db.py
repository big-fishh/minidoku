import sqlite3
from pathlib import Path
from contextlib import closing

DB_PATH = Path(__file__).resolve().parent / "minidoku.db"
CREATE_PUZZLES_TABLE = '''
			CREATE TABLE IF NOT EXISTS Puzzles (
				id INTEGER PRIMARY KEY,
				date TEXT UNIQUE,
				difficulty TEXT NOT NULL CHECK (difficulty in ('easy', 'medium', 'hard')),
				grid TEXT NOT NULL,
				solution TEXT NOT NULL
			);
			'''

def main():
	with closing(sqlite3.connect(DB_PATH)) as conn:
		with conn:
			# log database ready message
			conn.execute(CREATE_PUZZLES_TABLE)

if __name__ == "__main__":
	main()