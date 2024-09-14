# LLM-CodeSlim
Optimize your codebase for large language models by removing unnecessary files, comments, and whitespace.

## Description:
  
LLM-CodeSlim is a bash and power shell script designed to streamline your codebase by eliminating comments, excessive whitespace, and irrelevant files. Tailored for preparing code snippets for large language models, it ensures your projects fit within LLM context window limits, enhancing efficiency and performance during analysis or processing.

## Key Features:

- Selective File Filtering: Choose specific file types and filenames to include in the optimization process.
- Directory Ignoring: Exclude unwanted directories to focus only on essential parts of your project.
- Comment and Whitespace Removal: Clean your code by stripping out comments and unnecessary spaces.
- Stop Words Handling: Automatically ignore lines after specified stop words to further refine the output.

## Usage
- Simply run the script in your project directory to generate a minimized out.txt containing the optimized code ready for use with large language models.
- Before running the script, edit the following arrays to suit your project's needs: *folders_to_ignore, extensions_to_search, filenames_to_search, comment_chars, and stop_words*.  
