import random

from sudoku import Sudoku
from dokusan import solvers
from dokusan.boards import BoxSize
from dokusan.boards import Sudoku as dokusanSudoku

BOX_WIDTH = 3   # columns per box
BOX_HEIGHT = 2  # rows per box
SIZE = 6

BASE_SEED = 2026

rng = random.Random(BASE_SEED)
seed = rng.randrange(2**32)

puzzle = Sudoku(BOX_WIDTH, BOX_HEIGHT, seed=seed).difficulty(0.4)
pysudoku_puzzle = puzzle.board

dokusan_puzzle = dokusanSudoku.from_list(puzzle=pysudoku_puzzle,box_size=BoxSize(BOX_WIDTH, BOX_HEIGHT))

for step in solvers.steps(dokusan_puzzle):
	print(step)

