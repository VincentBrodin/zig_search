# Maze Solver in Zig
A simple maze solver written in Zig that supports two algorithms—BFS and DFS.
The project reads a maze from an input file, solves it using the selected method,
and outputs the solution either to a file or to the console.

## Cloning the Repository
Clone the repository using Git:

```bash
git clone https://github.com/VincentBrodin/zig_search.git
cd zig_search 
```

## Building the Project
The project uses Zig’s build system. To build the executable, run:

```bash
zig build
```

## Running the Project

The executable expects command-line arguments in the following order:

.1 Method: The maze solving algorithm to use. Acceptable values are "bfs" or "dfs".
.2 Input: Path to the maze input file.
.3 Output (optional): Path to the output file. If omitted, the solution is printed to the console.

### Usage Examples
Print output to the console:
```bash
zig-out/bin/main bfs input_maze.txt
```

### Write output to a file:

```bash
zig-out/bin/main dfs input_maze.txt output_solution.txt
```

#### Note!
The maze input file should be formatted correctly (using the expected characters such as # for walls, s for start, g for goal, etc.).
