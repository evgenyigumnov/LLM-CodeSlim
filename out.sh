#!/bin/bash

# Удаляем существующий out.txt, если он есть
rm -f out.txt

# Массивы
folders_to_ignore=("target" ".git" ".github" ".gitignore" ".idea" )   # Папки, которые нужно игнорировать
extensions_to_search=( "rs" )                              # Расширения файлов, которые нужно искать
filenames_to_search=("Cargo.toml" "core.rs" "text.rs" "json.rs")                       # Имена файлов, которые нужно искать
comment_chars=("#" "//" "/*")                            # Символы, обозначающие комментарии
stop_words=("#[cfg(test)]")                              # Стоп-слова, после которых игнорировать оставшиеся строки в файле

# Строим команду 'find'

# Начинаем с базовой команды 'find'
find_cmd="find ."

# Добавляем папки для игнорирования
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

# Добавляем условия для поиска файлов
find_cmd+=" \\( "

name_patterns=()

# Добавляем расширения файлов
for ext in "${extensions_to_search[@]}"; do
    name_patterns+=("-name '*.$ext'")
done

# Добавляем имена файлов
for fname in "${filenames_to_search[@]}"; do
    name_patterns+=("-name '$fname'")
done

# Объединяем все паттерны с помощью -o
for ((i=0; i<${#name_patterns[@]}; i++)); do
    find_cmd+=" ${name_patterns[$i]}"
    if [ $i -lt $((${#name_patterns[@]} - 1)) ]; then
        find_cmd+=" -o"
    fi
done

find_cmd+=" \\) -type f -print"

# Выводим финальную команду для отладки (можно закомментировать эту строку)
# echo "Running command: $find_cmd"

# Построение регулярного выражения для комментариев
comment_pattern=""
for ((i=0; i<${#comment_chars[@]}; i++)); do
    # Экранируем специальные символы в символах комментариев
    escaped_char=$(printf '%s\n' "${comment_chars[$i]}" | sed 's/[][(){}.*+?^$\\|/]/\\&/g')
    if [ $i -eq 0 ]; then
        comment_pattern="$escaped_char"
    else
        comment_pattern="$comment_pattern|$escaped_char"
    fi
done

# Выполняем команду 'find' и обрабатываем результаты
while read filepath; do
    echo -e "\n#### $filepath ####" >> out.txt
    stop=false
    # Обрабатываем файл построчно
    while IFS= read -r line; do
        if [ "$stop" = true ]; then
            break
        fi
        # Удаляем табуляции
        line="${line//$'\t'/}"
        # Удаляем ведущие пробелы
        line="${line#"${line%%[![:space:]]*}"}"
        # Удаляем конечные пробелы
        line="${line%"${line##*[![:space:]]}"}"
        # Пропускаем строки, которые пустые или содержат только пробелы
        if [[ -z "$line" ]]; then
            continue
        fi
        # Проверяем на стоп-слова
        for stop_word in "${stop_words[@]}"; do
            if [[ "$line" == "$stop_word" ]]; then
                stop=true
                break
            fi
        done
        if [ "$stop" = true ]; then
            break
        fi
        # Пропускаем строки, которые являются комментариями
        if [[ "$line" =~ ^($comment_pattern) ]]; then
            continue
        fi
        # Записываем обработанную строку в out.txt
        echo "$line" >> out.txt
    done < "$filepath"
done < <(eval $find_cmd)
