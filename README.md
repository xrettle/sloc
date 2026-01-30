# sloc (Speedy Lines of Code)

sloc is a high-performance Windows utility designed to count files, lines of code, and characters in a given directory path. While it takes inspiration from cloc, this tool is built specifically for speed on Windows systems by using native .NET libraries instead of traditional script loops.

## Project overview

S.L.O.C. (speedy lines of code), a cloc-inspired windows tool to count amount of files, lines of code, and characters in a given directory path.

Most code counters process files one by one through a command line interface, which creates significant overhead. This tool bypasses those limitations by generating a temporary PowerShell worker that calls System.IO methods directly. It is designed for developers who need to scan large repositories or local projects without waiting for standard tools to finish.

## Key features

The tool uses a two-phase scanning process to provide accurate data. First, it indexes the entire directory tree to get a total file count. This allows the progress bar to show an actual percentage rather than just an indefinite spinner. Second, it processes the files in batches. By updating the user interface only once every thousand files, the script maintains its high speed because it does not waste CPU cycles on constant screen refreshes.

It also includes safety measures for production environments. It automatically skips files larger than 100MB to prevent memory exhaustion and filters out binary files like images or executables. This ensures the final line count reflects actual source code rather than noise from compiled assets.

## Installation and usage

You do not need to install anything or set up a runtime environment.

1. Download the sloc.bat file from this repository.
2. Run the file by double-clicking it or calling it from a terminal.
3. Paste the path of the folder you want to analyze.
4. Review the results once the progress bar reaches 100 percent.

The script is a single file, which makes it easy to move between different machines or include in project folders.

## Technical details

The core logic uses a HashSet for extension lookups, which provides constant time complexity for identifying code files. For the actual counting, it uses the ReadAllText method. This is faster than reading files line by line because it pulls the data into memory in a single operation. The line count is then calculated by comparing the total string length to the length of the string after newlines are removed. This mathematical approach is significantly more efficient than iterating through every line in a text buffer.

## License and attribution

This project is released under the MIT License.

You are free to use, copy, modify, and distribute this software for any purpose. The only requirement is that you must include the original copyright notice and this permission notice in all copies or substantial portions of the software. Attribution to the original author is required as part of the license terms.
