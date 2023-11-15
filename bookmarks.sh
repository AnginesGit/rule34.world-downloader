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

#parameters
while getopts ":d:ivh" opt; do
  case $opt in
    d)
        #specify directory
      directory="$OPTARG/"
      echo "directory = $directory"
      ;;
    i)
        # Only Images
      exts_list=( "pic.jpg" "picsmall.jpg" )
      ;;
    v)
        # Only videos
      exts_list=( "mp4" "mov720.mp4" "mov.mp4" )
      ;;
    h)
      echo -e $help
      exit 0
      ;;
    \?)
      echo -e "\e[31mArguments error\e[0m"
      echo -e $help
      ;;
    :)
      echo "option $OPTARG require an argument. Read help using -h"
      exit 1
      ;;
  esac
done


# Ask username
echo -ne "\e[34musername: \e[0m"
read username
user=$( echo "$username" | sed 's@ @%20@gp' )       # SOME USERNAMES HAS SPACES

id=$(curl -e "https://rule34.world" -Ls https://rule34.world/api/user/$user | grep -o '"id":[^,]*' | cut -d ':' -f 2 | sed 's@,@@')
total_bookmarks=$(curl -e "https://rule34.world" -Ls https://rule34.world/api/user/$user | grep -o '"bookmarks":[^,]*' | cut -d ':' -f 2 | sed 's@,@@')


if [ "$id" == "" ]; then
    echo -e "\e[31mThe User not exist."
    exit 1
fi
if [ $total_bookmarks -eq 0 ]; then
    echo -e "\e[31mThe User dont have bookmarks."
    exit 1
fi

echo -e "\e[34mDownloading $username Bookmarks...     \e[32m[$total_bookmarks]\e[0m"

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

rm $codes_file
# GET BOOKMARKS DATA
for (( i = 60 ; i <= $total_bookmarks + 60 ; i=$i+60 )); do
    echo "asdfsadf : $(($i - 60)) - $i"
curl -e "https://rule34.world/u/$user/bookmarks"-Ls https://rule34.world/api/post/GetUserBookmarks\?Skip\=$(($i - 60))\&Take\=$i\&DisableTotal\=true\&userId\=$id | grep -o '"id":[^,]*' | cut -d ':' -f 2 >> $codes_file
echo "$i/$total_bookmarks"
done



# CREATE BOOKMARKS FOLDER
mkdir -p "$directory$username"

# DOWNLOAD EVERY Bookmark
while IFS= read -r code; do

    rest="${code%???}"                                                  # numbers before 3 last numbers
    url_in="https://rule34storage.b-cdn.net/posts/$rest/$code/$code"    #database pattern

    # download and verify if the file extension used is correct
    for extension in "${exts_list[@]}"
    do
        if test -f "$directory$username/$code.$extension"; then
            break
        else
            curl --silent -e "https://rule34.world" -L "$url_in.$extension" -o "$directory$username/$code.$extension"
            size=$(ls -l "$directory$username/$code.$extension" | cut -d ' ' -f 5)

            # IF THE FILE IS LESS OF 900 bytes TRY NEXT EXTENSION
            if [ $((size)) -le 900 ]
            then
                rm "$directory$username/$code.$extension"
            else
                break
            fi
        fi
    done

    ((post_iteration++))
    print_progress $post_iteration $total_bookmarks


done < $codes_file

rm $codes_file
echo ""

#finished

echo ""
echo -e "\e[32m$username Bookmarks downloaded.\e[0m"


# https://rule34.world/api/post/GetUserPosts?Skip=0&Take=60&DisableTotal=false&userId=$id
# https://rule34.world/api/playlist?UserId=$id&OrderBy=0&Skip=0&Take=60&DisableTotal=false
