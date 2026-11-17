"""Generate 6x6 Mini Sudoku puzzles with py-sudoku.

Boxes are 3 cells wide and 2 cells tall, laid out 2 boxes across and 3 down.
Keeps only valid puzzles with a unique solution and writes them to
puzzles.json as one list, each puzzle tagged with its difficulty.

Usage:
    pip install py-sudoku
    python generate_puzzles.py
"""

import json
import random
import sqlite3
from datetime import date
from contextlib import closing

from sudoku import Sudoku
from data.db import DB_PATH

LEVELS = {"easy": 0.4, "medium": 0.5, "hard": 0.6}  # fraction of cells blanked
BASE_SEED = 2026  # change this to get a different set of puzzles

BOX_WIDTH = 3   # columns per box
BOX_HEIGHT = 2  # rows per box
SIZE = 6

def units():
    """Every row, column and box as a list of string indices (0-35)."""
    rows = [[r * SIZE + c for c in range(SIZE)] for r in range(SIZE)]
    cols = [[r * SIZE + c for r in range(SIZE)] for c in range(SIZE)]
    boxes = [
        [(top + r) * SIZE + left + c for r in range(BOX_HEIGHT) for c in range(BOX_WIDTH)]
        for top in range(0, SIZE, BOX_HEIGHT)
        for left in range(0, SIZE, BOX_WIDTH)
    ]
    return rows + cols + boxes


UNITS = units()


def is_valid(grid, solution):
    """Check the solution is a correct sudoku and agrees with every clue."""
    if len(grid) != 36 or len(solution) != 36:
        return False
    if any(set(solution[i] for i in unit) != set("123456") for unit in UNITS):
        return False
    return all(g == "0" or g == s for g, s in zip(grid, solution))


def to_string(board):
    """Flatten a 6x6 board into a 36-character string, with 0 for empty cells."""
    return "".join(str(cell or 0) for row in board for cell in row)


def make_puzzle(difficulty, seed):
    """Return (grid, solution) strings, or None if the puzzle isn't unique."""
    puzzle = Sudoku(BOX_WIDTH, BOX_HEIGHT, seed=seed).difficulty(difficulty)
    if puzzle.get_difficulty() == -3:  # py-sudoku's flag for multiple solutions
        return None
    grid = to_string(puzzle.board)
    solution = to_string(puzzle.solve().board)
    if not is_valid(grid, solution):
        raise ValueError(f"Invalid puzzle from seed {seed}: {grid} / {solution}")
    return grid, solution


def get_difficulty(day: date) -> float:
    bag = ["medium", "medium", "medium", "hard", "hard"]
    iso = date.isocalendar(day)
    if iso.weekday < 3:
        return LEVELS["easy"]
    else:
        difficulty_seed = f"{iso.year}-W{iso.week}"
        difficulty_rng = random.Random(difficulty_seed)
        difficulty_rng.shuffle(bag)
        return LEVELS[bag[iso.weekday - 3]]

def get_seed(rng: random.Random) -> int:
    seed = rng.randrange(2**32)
    # check that seed not in table
    with closing(sqlite3.connect(DB_PATH)) as conn:
        with conn:
            puzzle_seeds = [row[0] for row in conn.execute("SELECT seed FROM Puzzles;")]
            while seed in puzzle_seeds:
                seed = rng.randrange(2**32)
    return seed

def generate_daily_puzzle(rng: random.Random, day: date) -> tuple[str, str]:
    # One seeded RNG hands out a fresh seed for every attempt. py-sudoku's
    # default seed is fixed at import time, so passing our own is required.
    datestr = date.isoformat(day)
    difficulty = get_difficulty(day)
    difficulty_str = next((k for k, v in LEVELS.items() if v == difficulty), None)
    insert_query = '''
    INSERT INTO Puzzles (date, seed, difficulty, grid)
    VALUES (?, ?, ?, ?);
    '''
    with closing(sqlite3.connect(DB_PATH)) as conn:
        # Keep trying seeds until we get a unique-solution puzzle whose
        # board hasn't been served before.
        while True:
            seed = get_seed(rng)
            result = make_puzzle(difficulty=difficulty, seed=seed)
            if result is None:
                continue
            seen = conn.execute("SELECT 1 FROM Puzzles WHERE grid = ?;", (result[0],)).fetchone()
            if seen is None:
                break

        with conn:
            conn.execute(insert_query, (datestr, seed, difficulty_str, result[0]))
    return result

def generate_unlimited_puzzle() -> tuple[str, str]:
    rng = random.Random()
    difficulty = rng.choice(list(LEVELS.values())) 
    result = None
    while result is None:
        result = make_puzzle(difficulty=difficulty, seed=rng.randrange(2**32))
    return result


def main() -> None:
    rng = random.Random(BASE_SEED)
    today = date.today()

if __name__ == "__main__":
    main()