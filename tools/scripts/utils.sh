#!/usr/bin/bash

# For edge oriented commands, values: /dev/stdout, /dev/null
OUTPUT=/dev/null

# Function to print variable title
function print_title() {
    local title="$1"
    local line="--------------------------------------------------"
    local padding=$(( ( ${#line} - ${#title} ) / 2 ))
    local padded_title
    padded_title=$(printf "%${padding}s%s%${padding}s" "" "${title^^}" "")
    
    echo "$line"
    echo "$padded_title"
    echo "$line"
}