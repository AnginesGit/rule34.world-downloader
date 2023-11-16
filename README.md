# rule34.world-downloader
rule34.world downloader.

![image](/img/example.png) 
  
  ---
## Usage
```
    -p  <URL-ID>    direct playlist download
    -b  <USERNAME>  direct user bookmarks download
    -d  <PATH>      specify directory to save playlist carpet.
    -i              only images (and thumbnails of videos).
    -v              only videos.

    -h              show help
```
if direct parameters misses the script show you a menu to choose.
### examples:
Download playlist in the same directory. 
```
$ ./r34world
2) Playlist
paste playlist id or url: https://rule34.world/playlists/view/<ID>
...

```

Only User Bookmarks Images on your home.

```
$ ./r34world -id ~
1) User Bookmark
username: superhot
...
```

The script work faster if you specify only images on a only images playlist.


---
## To do
- [x] Download all Playlist posts.
- [x] User Bookmarks Downloader.
- [ ] User Playlists Downloader.
