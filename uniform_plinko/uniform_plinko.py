import numpy as np
from scipy.optimize import minimize
import svgwrite as svg


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
        :param target_probabilities: a dict from bucket index to target probability
        :return: a tuple of evaluated bucket probabilities
        """
        evaluations = self.evaluate(probabilities)
        bucket_outcomes = []
        for bucket_index in sorted(evaluations.keys()):
            bucket_outcomes.append(evaluations[bucket_index] - target_probabilities[bucket_index])

        return bucket_outcomes

    def solve(self, target_probabilities):
        starting_guesses = [.5 for _ in range(self._number_of_pegs)]
        bounds = [(0, 1) for _ in range(self._number_of_pegs)]
        left_peg_probability_solutions = minimize(lambda x:
                                                  sum(x**2 for x in self._evaluate_for_roots(x, target_probabilities)),
                                                  starting_guesses,
                                                  bounds=bounds)
        return list(left_peg_probability_solutions.x)


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
        self._depth = depth
        self._number_of_pegs = int(depth * (depth + 1) / 2)
        self._adjacency = _generate_plinko_adjacency(depth)
        self._left_probabilities = None
        self._bucket_probabilities = None

    def resolve_to_system(self):
        all_paths = _traverse(self._adjacency, Path((0,)))
        return PlinkoSystem(all_paths, self._number_of_pegs)

    def get_number_of_pegs(self):
        return self._number_of_pegs

    def set_probabilities(self, peg_left_probabilities, bucket_probabilities):
        self._left_probabilities = peg_left_probabilities
        self._bucket_probabilities = bucket_probabilities

    def get_bucket_indices(self):
        return list(range(self._number_of_pegs, self._number_of_pegs + self._depth + 1))

    def render(self, file_path = '/Users/kholub/plinko.svg'):
        def _pf(x):
            return "%f%%" % (x,)

        doc = svg.Drawing(filename=file_path, size=("100%", "100%"))

        bucket_indices = self.get_bucket_indices()
        number_of_buckets = len(bucket_indices)
        bucket_width = 100 / number_of_buckets

        peg_horizontal_spacing = 100 / number_of_buckets
        peg_vertical_spacing = 90 / self._depth
        peg_radius = peg_vertical_spacing / 16

        # render pegs
        peg_index_to_center = {}
        for level in range(self._depth):
            vertical_offset = level * peg_vertical_spacing + .5 * peg_vertical_spacing
            horizontal_offset_to_first = peg_horizontal_spacing * (number_of_buckets - level) / 2

            for peg_count in range(level + 1):
                horizontal_offset = horizontal_offset_to_first + peg_count * peg_horizontal_spacing
                peg_ix = int(level * (level + 1) / 2) + peg_count
                peg_index_to_center[peg_ix] = (horizontal_offset, vertical_offset)
                doc.add(doc.circle(center=(_pf(horizontal_offset), _pf(vertical_offset)),
                                                   r=_pf(peg_radius),
                                                   stroke_width="1",
                                                   stroke="black",
                                                   fill="rgb(66, 206, 183)"))

        # render buckets, including bucket probabilities
        bucket_top = 90 + peg_radius - .25 * peg_vertical_spacing
        for bucket_count, bucket_index in enumerate(bucket_indices):
            bucket_left_position = max((1, bucket_count * bucket_width))
            bucket_right_position = min((99, (bucket_count + 1) * bucket_width))
            # left line
            doc.add(doc.line(start=(_pf(bucket_left_position), _pf(bucket_top)),
                             end=(_pf(bucket_left_position), _pf(100)),
                             stroke="black",
                             stroke_width="1"))
            # right line
            doc.add(doc.line(start=(_pf(bucket_right_position), _pf(bucket_top)),
                             end=(_pf(bucket_right_position), _pf(100)),
                             stroke="black",
                             stroke_width="1"))

            vertical_position = 95
            peg_index_to_center[bucket_index] = ((bucket_right_position + bucket_left_position) / 2, 90)
            # evaluated probability
            if self._bucket_probabilities:
                horizontal_position = (bucket_right_position + bucket_left_position) / 2 - bucket_width / 4
                probability = self._bucket_probabilities[bucket_index]
                doc.add(doc.text("%.1f%%" % (probability * 100),
                                 insert=(_pf(horizontal_position), _pf(vertical_position)),
                                 style="font-size:200%" if self._depth < 8 else "font-size:100%"))

        # render edges between pegs, including transition probabilities
        for from_peg_ix in range(self._number_of_pegs):
            from_peg_center = peg_index_to_center[from_peg_ix]
            traversable_peg_indices = np.nonzero(self._adjacency[from_peg_ix,])[0]

            left_peg_ix = traversable_peg_indices[0]
            left_peg_center = peg_index_to_center[left_peg_ix]

            right_peg_ix = traversable_peg_indices[1]
            right_peg_center = peg_index_to_center[right_peg_ix]

            doc.add(doc.line(start=(_pf(from_peg_center[0] - peg_radius), _pf(from_peg_center[1] + peg_radius)),
                             end=(_pf(left_peg_center[0] + peg_radius), _pf(left_peg_center[1] - peg_radius)),
                             stroke="black",
                             stroke_width="1"))

            doc.add(doc.line(start=(_pf(from_peg_center[0] + peg_radius), _pf(from_peg_center[1] + peg_radius)),
                             end=(_pf(right_peg_center[0] - peg_radius), _pf(right_peg_center[1] - peg_radius)),
                             stroke="black",
                             stroke_width="1"))

            if self._left_probabilities:
                left_peg_probability = self._left_probabilities[from_peg_ix]
                right_peg_probability = 1 - left_peg_probability

                """
                left_p_center = (_pf((left_peg_center[0] + from_peg_center[0]) / 2),
                                 _pf((left_peg_center[1] + from_peg_center[1]) / 2))
                doc.add(doc.text("%.2f" % left_peg_probability,
                                 insert=left_p_center))
                """

                right_p_center = (_pf((right_peg_center[0] + from_peg_center[0]) / 2),
                                 _pf((right_peg_center[1] + from_peg_center[1]) / 2))
                doc.add(doc.text("%.2f" % right_peg_probability,
                                 insert=right_p_center))

        doc.save()

if __name__ == '__main__':
    board = Board(6)
    system = board.resolve_to_system()
    bucket_indices = board.get_bucket_indices()
    peg_left_probabilities = system.solve({ix: 1/len(bucket_indices) for ix in bucket_indices})
    bucket_probabilities = system.evaluate(peg_left_probabilities)

    board.set_probabilities(peg_left_probabilities, bucket_probabilities)
    board.render()

    normal_board = Board(10)
    normal_system = normal_board.resolve_to_system()
    iid_split_probs = [.5 for _ in range(normal_board.get_number_of_pegs())]
    normal_bucket_probs = normal_system.evaluate(iid_split_probs)
    normal_board.set_probabilities(None, normal_bucket_probs)
    normal_board.render()