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

from sudoku import Sudoku

PUZZLES_PER_LEVEL = 30
LEVELS = {"Easy": 0.4, "Medium": 0.5, "Hard": 0.6}  # fraction of cells blanked
BASE_SEED = 2026  # change this to get a different set of puzzles
OUTPUT_FILE = "puzzles.json"

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


def main():
    # One seeded RNG hands out a fresh seed for every attempt. py-sudoku's
    # default seed is fixed at import time, so passing our own is required.
    rng = random.Random(BASE_SEED)
    puzzles = []
    seen = set()

    for level, difficulty in LEVELS.items():
        found = attempts = 0
        while found < PUZZLES_PER_LEVEL:
            attempts += 1
            result = make_puzzle(difficulty, rng.randrange(2**32))
            if result is None or result[0] in seen:
                continue
            grid, solution = result
            seen.add(grid)
            puzzles.append({
                "id": len(puzzles) + 1,
                "difficulty": level,
                "grid": grid,
                "solution": solution,
            })
            found += 1
        print(f"{level}: kept {found} of {attempts} attempts")

    with open(OUTPUT_FILE, "w") as f:
        json.dump(puzzles, f, indent=2)
    print(f"Wrote {len(puzzles)} puzzles to {OUTPUT_FILE}")


if __name__ == "__main__":
    main()