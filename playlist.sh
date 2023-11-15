#!/bin/bash
#
#variables
help="\n
-d <directory>       save playlist in a directory\n
-i     only download images\n
-v     only download videos\n
-h     show this help\n
"

codes_file="codes" # temporal file for the code posts
exts_list=( "mp4" "mov720.mp4" "mov.mp4" "pic.jpg" "picsmall.jpg" )
directory=""
#specify directory
while getopts ":d:ivh" opt; do
  case $opt in
    d)
      directory="$OPTARG/"
      echo "directory = $directory"
      ;;
    i)
      exts_list=( "pic.jpg" "picsmall.jpg" )
      ;;
    v)
      exts_list=( "mp4" "mov720.mp4" "mov.mp4" )
      ;;
    h)
      echo -e $help
      exit 0
      ;;
    \?)
      echo -e "\e[31mArguments error\e[0m"
      echo $help
      ;;
    :)
      echo "option $OPTARG require an argument. Read help using -h"
      exit 1
      ;;
  esac
done


echo -e "\e[34mPaste id or url playlist:\e[0m"

read URL

id=$(echo "$URL" | sed "s@rule34.world@@"| grep -Eo '[0-9]*')
URL="rule34.world/playlists/view/$id"

# get title
title=$( curl -Ls $URL | grep -o 'class="text fill">[^<]*' | cut -d '>' -f 2 )

# check if playlist url exist
if [ "$title" == "" ]; then
    echo -e "\e[31mThe playlist doesn't exist or invalid url."
    exit 1
fi

# create the playlist folder
mkdir -p "$directory$title"

echo -e "\e[34mDownloading Playlist: $title\e[0m"

curl -Ls $URL | grep -oP "/post/.*?\"" | sed "s@/post/@@" | sed 's@"@@' > $codes_file

total_posts=$(wc -l $codes_file | cut -d " " -f 1)
post_iteration=0

print_progress() {
    local count=$1
    local total_count=$2
    
    percentage=$((count * 100 / total_count))
    char_length=30
    bar_length=$((count * char_length/ total_count))

    progress_bar="["
    for ((j=0; j<bar_length; j++)); do
        progress_bar+="="
    done
    for ((j=bar_length; j<char_length; j++)); do
        progress_bar+=" "
    done
    progress_bar+="]"

    echo -ne "\e[33m$progress_bar    $count/$total_count\e[0m\r"
}


while IFS= read -r code; do

    rest="${code%???}"                                                  # numbers before 3 last numbers
    url_in="https://rule34storage.b-cdn.net/posts/$rest/$code/$code"    #database pattern

    # download and verify if the file extension used is correct
    for extension in "${exts_list[@]}"
    do
        curl --silent -e "https://rule34.world" -L "$url_in.$extension" -o "$directory$title/$code.$extension"
        size=$(ls -l "$directory$title/$code.$extension" | cut -d ' ' -f 5)
        if [ $((size)) -le 900 ]
        then
            rm "$directory$title/$code.$extension"
        else
            break
        fi 
    done

    ((post_iteration++))
    print_progress $post_iteration $total_posts


done < $codes_file

rm $codes_file

#finished

echo ""
echo -e "\e[32mPlaylist $title downloaded.\e[0m"