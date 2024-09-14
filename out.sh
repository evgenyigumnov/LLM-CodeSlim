#!/bin/bash

# Remove existing out.txt if it exists
rm -f out.txt

# Arrays
folders_to_ignore=("target" ".git" ".github" ".gitignore" ".idea" )   # Folders to ignore
extensions_to_search=( "rs" )                              # File extensions to search for
filenames_to_search=("Cargo.toml" "core.rs" "text.rs" "json.rs")                       # Filenames to search for
comment_chars=("#" "//" "/*")                            # Characters that denote comments
stop_words=("#[cfg(test)]")                              # Stop words after which to ignore the remaining lines in the file

# Build the 'find' command

# Start with the basic 'find' command
find_cmd="find ."

# Add folders to ignore
if [ ${#folders_to_ignore[@]} -gt 0 ]; then
    ignore_dir_expr=""
    for dir in "${folders_to_ignore[@]}"; do
        if [ -n "$ignore_dir_expr" ]; then
            ignore_dir_expr+=" -o "
        fi
        ignore_dir_expr+="-path './$dir' -prune"
    done
    find_cmd+=" \\( $ignore_dir_expr \\) -o"
fi

# Add conditions to search for files
find_cmd+=" \\( "

name_patterns=()

# Add file extensions
for ext in "${extensions_to_search[@]}"; do
    name_patterns+=("-name '*.$ext'")
done

# Add filenames
for fname in "${filenames_to_search[@]}"; do
    name_patterns+=("-name '$fname'")
done

# Combine all patterns using -o
for ((i=0; i<${#name_patterns[@]}; i++)); do
    find_cmd+=" ${name_patterns[$i]}"
    if [ $i -lt $((${#name_patterns[@]} - 1)) ]; then
        find_cmd+=" -o"
    fi
done

find_cmd+=" \\) -type f -print"

# Print the final command for debugging (you can comment out this line)
# echo "Running command: $find_cmd"

# Build the regular expression for comments
comment_pattern=""
for ((i=0; i<${#comment_chars[@]}; i++)); do
    # Escape special characters in comment characters
    escaped_char=$(printf '%s\n' "${comment_chars[$i]}" | sed 's/[][(){}.*+?^$\\|/]/\\&/g')
    if [ $i -eq 0 ]; then
        comment_pattern="$escaped_char"
    else
        comment_pattern="$comment_pattern|$escaped_char"
    fi
done

# Execute the 'find' command and process the results
while read filepath; do
    echo -e "\n#### $filepath ####" >> out.txt
    stop=false
    # Process the file line by line
    while IFS= read -r line; do
        if [ "$stop" = true ]; then
            break
        fi
        # Remove tabs
        line="${line//$'\t'/}"
        # Remove leading spaces
        line="${line#"${line%%[![:space:]]*}"}"
        # Remove trailing spaces
        line="${line%"${line##*[![:space:]]}"}"
        # Skip lines that are empty or contain only spaces
        if [[ -z "$line" ]]; then
            continue
        fi
        # Check for stop words
        for stop_word in "${stop_words[@]}"; do
            if [[ "$line" == "$stop_word" ]]; then
                stop=true
                break
            fi
        done
        if [ "$stop" = true ]; then
            break
        fi
        # Skip lines that are comments
        if [[ "$line" =~ ^($comment_pattern) ]]; then
            continue
        fi
        # Write the processed line to out.txt
        echo "$line" >> out.txt
    done < "$filepath"
done < <(eval $find_cmd)
