#!/bin/bash
#
help="
Rule34.world Downloader

-p <URL>\tdirect playlist download
-b <username>\tdirect user bookmarks download
-d <DIRECTORY>\tsave playlist in a directory

-i\t\tonly download images
-v\t\tonly download videos

-h\t\tshow this help
"

#variables
exts_list=( "mp4" "mov720.mp4" "mov.mp4" "pic.jpg" )
directory=""
asker=true

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

get_username () {

    echo -ne "\e[34musername: \e[0m"
    read username

    username_get=$username
}

get_playlist () {

    echo -en "\e[34Playlist URL or ID: \e[0m"
    read URL
    local id=$(echo "$URL" | sed "s@rule34.world@@"| grep -Eo '[0-9]*')

    playlist_id_get=$id
}

download_playlist () {

    mkdir -p ".temp"
    local codes_file="cdPlayls" # temporal file for the code posts
    rm -f ".temp/$codes_file"

    local id=$playlist_id_get
    local URL="rule34.world/playlists/view/$id"

    # get playlist information
    local pl_data=$( curl -s "https://rule34.world/api/playlist/$id" --compressed -H "Referer: https://rule34.world/playlists/view/$id" )
    local title=$( echo $pl_data | grep -oP 'title":"[^"]*' | cut -d '"' -f 3 )
    local total_posts=$( echo $pl_data | grep -oP 'items[^,]*' | cut -d ':' -f 2 )

    # check if playlist url exist
    if [ "$title" == "" ]; then
        echo -e "\e[31mThe playlist doesn't exist or invalid url."
        exit 1
    fi


    # create the playlist folder
    mkdir -p "$directory$title"

    echo -e "\e[34mDownloading Playlist: $title\e[32m    [$total_posts]\e[0m"

    #DOWNLOAD PLAYLIST
    for (( i = 60 ; i <= $total_posts + 60 ; i=$i+60 )); do
        curl -e "https://rule34.world" -Ls "https://rule34.world/api/playlist-item?PlaylistId=$id&Skip=$(($i - 60))&Take=$i&DisableTotal=false" | grep -o '"id":[^,]*' | cut -d ':' -f 2 >> ".temp/$codes_file"
        echo "$i/$total_posts"
    done

    #local total_posts=$(wc -l ".temp/$codes_file" | cut -d " " -f 1)
    local post_iteration=0


    while IFS= read -r code; do

        rest="${code%???}"                 # numbers before 3 last numbers
        url_in="https://rule34storage.b-cdn.net/posts/$rest/$code/$code"    #database pattern

        # download and verify if the file extension used is correct
        for extension in "${exts_list[@]}"
        do
            curl --silent -e "https://rule34.world" -L "$url_in.$extension" -o "$directory$title/$code.$extension"
            size=$(ls -l "$directory$title/$code.$extension" | cut -d ' ' -f 5)
            if [ $((size)) -le 900 ]
            then
                rm -f "$directory$title/$code.$extension"
            else
                break
            fi
        done

        ((post_iteration++))
        print_progress $post_iteration $total_posts


    done < ".temp/$codes_file"

    rm -f ".temp/$codes_file"

    #finished

    echo ""
    echo -e "\e[32mPlaylist $title downloaded.\e[0m"
}

download_bookmarks () {

    mkdir -p ".temp"
    local codes_file="bkmrksdt" # temporal file for the code posts

    local username=$username_get
    local user=$( echo "$username" | sed 's@ @%20@gp' )       # SOME USERNAMES HAS SPACES

    local id=$(curl -e "https://rule34.world" -Ls https://rule34.world/api/user/$user | grep -o '"id":[^,]*' | cut -d ':' -f 2 | sed 's@,@@')
    local total_bookmarks=$(curl -e "https://rule34.world" -Ls https://rule34.world/api/user/$user | grep -o '"bookmarks":[^,]*' | cut -d ':' -f 2 | sed 's@,@@')


    if [ "$id" == "" ]; then
        echo -e "\e[31mThe User not exist."
        exit 1
    fi
    if [ $total_bookmarks -eq 0 ]; then
        echo -e "\e[31mThe User dont have bookmarks."
        exit 1
    fi

    echo -e "\e[34mDownloading $username Bookmarks...     \e[32m[$total_bookmarks]\e[0m"

    rm -f ".temp/$codes_file"
    # GET BOOKMARKS DATA
    for (( i = 60 ; i <= $total_bookmarks + 60 ; i=$i+60 )); do
    curl -e "https://rule34.world/u/$user/bookmarks" -Ls https://rule34.world/api/post/GetUserBookmarks\?Skip\=$(($i - 60))\&Take\=$i\&DisableTotal\=false\&userId\=$id | grep -oP '"id":[^,]*' | cut -d ':' -f 2 >> ".temp/$codes_file"
    done
    echo ""



    # CREATE BOOKMARKS FOLDER
    mkdir -p "$directory$username"


    post_iteration=0
    echo "temino"
exit 1


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
                curl -e "https://rule34.world" -Ls "$url_in.$extension" -o "$directory$username/$code.$extension"
                size=$(ls -l "$directory$username/$code.$extension" | cut -d ' ' -f 5)

                # IF THE FILE IS LESS OF 900 bytes TRY NEXT EXTENSION
                if [ $((size)) -le 900 ]
                then
                    rm -f "$directory$username/$code.$extension"
                else
                    break
                fi
            fi
        done

        ((post_iteration++))
        print_progress $post_iteration $total_bookmarks


    done < ".temp/$codes_file"

    rm -f ".temp/$codes_file"
    echo ""

    #finished

    echo ""
    echo -e "\e[32m$username Bookmarks downloaded.\e[0m"

}


# MENU ASKER
menu() {

    echo -en "\e[35mWhat to download:\e[33m
    1) User Bookmarks
    2) Playlist

    0) Exit
    \e[31m> \e[0m"


    read answer
    answer=$((answer))


    if [ $answer -eq 1 ]; then
        get_username
        download_bookmarks
        exit 0

    elif [ $answer -eq 2 ]; then
        get_playlist
        download_playlist
        exit 0

    elif [ $answer -eq 3 ]; then
        exit 0

    else
        exit 0
    fi

}

# PARAMETERS
while getopts ":d:ivhp:b:" opt; do
  case $opt in
    d)
      directory="$OPTARG/"
      echo "directory = $directory"
      ;;
    i)
      exts_list=( "pic.jpg" )
      ;;
    v)
      exts_list=( "mp4" "mov.mp4" "mov720.mp4" )
      ;;
    h)
      echo -e "$help"
      exit 0
      ;;
    p)

      playlist_id_get=$OPTARG
      download_playlist
      exit 0
      rm -drf ".temp"

      ;;
    b)

      username_get=$OPTARG
      download_bookmarks
      exit 0
      rm -drf ".temp"

      ;;

    \?)
      echo -e "\e[31mArguments error\e[0m";echo -e "$help";;
    :)
      echo "option $OPTARG require an argument. Read help using -h";exit 1;;
  esac
done

# https://rule34.world/api/post/GetUserPosts?Skip=0&Take=60&DisableTotal=false&userId=$id
# https://rule34.world/api/playlist?UserId=$id&OrderBy=0&Skip=0&Take=60&DisableTotal=false
# https://rule34.world/api/playlist-item?PlaylistId=$id&Skip=0&Take=60&DisableTotal=false

menu
rm -drf ".temp"
exit 0
