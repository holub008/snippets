import numpy as np
from scipy.optimize import fsolve


def _generate_plinko_adjacency(depth):
    number_of_pegs = int(depth * (depth + 1) / 2)
    number_of_buckets = depth + 1
    adjacency = np.zeros([number_of_pegs + number_of_buckets, number_of_pegs + number_of_buckets])

    # note that this can be done more cleanly (by setting 1's at 2 * row_ix + 1 and 2 * row_ix + 2)
    # but I think this is conceptually clearer
    total_pegs = 0
    for level in range(1, depth + 1):
        # each level is the same length as its depth
        for parent_peg_ix in range(total_pegs, total_pegs + level):
            # the to left peg is always offset by the length of the parent row, right length of parent row + 1
            adjacency[parent_peg_ix, parent_peg_ix + level] = 1
            adjacency[parent_peg_ix, parent_peg_ix + level + 1] = 1

            total_pegs += 1

    return adjacency


class Path:
    def __init__(self, indices, left_turns=()):
        self._indices = indices
        self._left_turns = left_turns

    def append(self, from_index, is_left):
        """
        :return: a copy of this path object with the appended step
        """
        new_indices = self._indices + (from_index,)
        new_turns = self._left_turns + (is_left,)

        return Path(new_indices, new_turns)

    def get_last_from_index(self):
        return self._indices[-1]

    def evaluate(self, probabilities):
        """
        :param probabilities: a list of left turn probabilities corresponding to each peg
        :return: the product of probabilities along this path
        """
        product = 1
        for ix in range(len(self._indices) - 1):
            peg_index = self._indices[ix]
            product *= probabilities[peg_index] if self._left_turns[ix] else (1 - probabilities[peg_index])

        return product

    def __repr__(self):
        turn_strings = ['L' if x else 'R' for x in self._left_turns] + ['end']
        return "Path(%s)" % (list(zip(self._indices, turn_strings)))

    def __str__(self):
        return self.__repr__()


class PlinkoSystem:
    def __init__(self, paths, number_of_pegs):
        # this is paths grouped by the bucket they terminate in
        grouped_paths = {}
        for path in paths:
            terminating_bucket_index = path.get_last_from_index()
            bucket_paths = grouped_paths.setdefault(terminating_bucket_index, [])
            bucket_paths.append(path)

        self._bucket_index_to_paths = grouped_paths
        self._number_of_pegs = number_of_pegs

    def evaluate(self, probabilities):
        """

        :param probabilities: a list of left turn probabilities corresponding to each peg
        :return: a dict of bucket_index to
        """
        bucket_index_to_probabilities = {}
        for bucket_index in self._bucket_index_to_paths:
            paths = self._bucket_index_to_paths[bucket_index]
            summation = 0
            for path in paths:
                summation += path.evaluate(probabilities)
            bucket_index_to_probabilities[bucket_index] = summation

        return bucket_index_to_probabilities

    def _evaluate_for_roots(self, probabilities, target_probabilities):
        """
        :param probabilities: a list of left turn probabilities corresponding to each peg
        :param target_probabilties: a dict from bucket index to target probability
        :return: a tuple of evaluated bucket probabilities
        """
        evaluations = self.evaluate(probabilities)
        bucket_outcomes = []
        for bucket_index in sorted(evaluations.keys()):
            bucket_outcomes.append(evaluations[bucket_index] - target_probabilities[bucket_index])

        return bucket_outcomes

    def solve(self, target_probabilities):
        starting_guesses = [.5 for _ in range(self._number_of_pegs)]
        # fsolve requires "square" problems - so we fill in 0s. this may bork gradients
        missing_equations = [.1 for _ in range(self._number_of_pegs - len(self._bucket_index_to_paths.keys()))]
        print(missing_equations)
        left_peg_probability_solutions = fsolve(lambda x:
                                                self._evaluate_for_roots(x, target_probabilities) + missing_equations,
                                                starting_guesses)
        return left_peg_probability_solutions



def _traverse(adjacency, current_path):
    last_index = current_path.get_last_from_index()
    traversable_indices = np.nonzero(adjacency[last_index, ])[0]
    if not len(traversable_indices) == 2:
        return current_path,

    left_traversal = current_path.append(traversable_indices[0], True)
    right_traversal = current_path.append(traversable_indices[1], False)

    return _traverse(adjacency, left_traversal) + _traverse(adjacency, right_traversal)


class Board:
    def __init__(self, depth):
        self._number_of_pegs = int(depth * (depth + 1) / 2)
        self._adjacency = _generate_plinko_adjacency(depth)
        self._left_probabilities = None
        self._bucket_probabilities = None

    def resolve_to_system(self):
        all_paths = _traverse(self._adjacency, Path((0,)))
        return PlinkoSystem(all_paths, self._number_of_pegs)

    def set_probabilities(self, peg_left_probabilities, bucket_probabilities):
        self._left_probabilities = peg_left_probabilities
        self._bucket_probabilities = bucket_probabilities

    def visualize(self):
        pass

if __name__ == '__main__':
    board = Board(3)
    system = board.resolve_to_system()
    system.evaluate([.5 for _ in range(6)])
    # errors on first propagation
    system._evaluate_for_roots([.5 for _ in range(6)], {ix: .25 for ix in range(6, 10)})
    left_peg_probabilities = system.solve({ix: .2 for ix in range(6, 10)})