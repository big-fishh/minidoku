import sqlite3
from pathlib import Path
from contextlib import closing
from data.db import DB_PATH

CREATE_PUZZLES_TABLE = '''
			CREATE TABLE IF NOT EXISTS Puzzles (
				id INTEGER PRIMARY KEY,
				date TEXT UNIQUE,
				seed INTEGER,
				grid TEXT NOT NULL UNIQUE,
				difficulty TEXT NOT NULL CHECK (difficulty in ('easy', 'medium', 'hard'))
			);
			'''

def main():
	with closing(sqlite3.connect(DB_PATH)) as conn:
		with conn:
			# log database ready message
			conn.execute(CREATE_PUZZLES_TABLE)
			conn.commit()

if __name__ == "__main__":
	main()