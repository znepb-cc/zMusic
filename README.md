# zMusic
An open-source music playing software for ComputerCraft, and Computronics' tape drives.
**Notice:** This currently only works on [SwitchCraft](https://switchcraft.pw).

## How to Install
### Setting up the server
**Tested on:**
Debian 10.2  
PHP 7.0  
nginx 1.14.2  
ffmpeg 4.1.4  
youtube-dl 2020.01.01  
Lionray commit 725032428bfcbd503e53c5cafdd68f14810d0e9a  
  
 1. Install a server that supports PHP. This could be Apache,
nginx, or any other server that supports PHP.   
 2. Install JRE 8 to your server, and ffmpeg. Then, go to /var/www/html or where your server's files are located. 
 3. Download the latest version of youtube-dl, and download the latest version of [LionRay] (https://github.com/gamax92/LionRay).
 4. Download [https://raw.githubusercontent.com/znepb/zMusic/master/index.php](https://raw.githubusercontent.com/znepb/zMusic/master/index.php) to your server. (It does not have to be /index.php on the server, but it is recommended.
 5. If needed, change `$file`, `$webm`, and `$out` in your PHP file.
 6. Move youtube-dl to the folder where your php file is located, and same with LionRay. Rename LionRay to `lionray.jar`.
 7. Create a directory named `files`
 8. Change permissions to allow your PHP file, lionray, ffmpeg, and youtube-dl to write to the files directory.

### Setting up the client
All you need is a tape drive, a tape (32 mins recommended), and a computer.

 1. Run `wget https://raw.githubusercontent.com/znepb/zMusic/master/zMusic.lua zmusic.lua` to download zMusic.
 2. Run `wget https://github.com/znepb/zMusic/raw/master/config.lua config.lua` to download the config.
 3. Run `edit config.lua` to edit the config.
 4. In the config, there are several values you must change. 
 5. Change `ip` to the IP of your server, or it's domain.
 6. Change `api-key` to your YouTube Data API v3 key. You can get one [here](https://console.developers.google.com/)
 7. Change `primary-user` to yourself (you will recieve notifications if an eror occurs)
 8. Change the first value in `trustedUsers` to your username. This table is a list of users that can run zmusic commands.

### Playing music
Now that you're done, try playing some music. Run `zmusic.lua` to get the party started!
#### Commands

 - `\zmusic play [song]` - Searches YouTube for the song, and adds it to the queue. If the queue is empty, the song will play. Passing no arguments will play the music if the queue is not empty and the music is stopped.
 - `\zmusic stop` - Stops the current song playing. You can restart the music by running `\zmusic play`
 - `\zmusic skip` - Skips the current song, if there is another song in the queue.
 - `\zmusic queue` - Tells the user what songs are in the queue.
 - `\zmusic clear` - Clears the queue.
 - `\zmusic volume <volume, 1-10>` - Sets the volume of the music, where 1 is the lowest and 10 is the highest.

#### Allowing other players to play music

If you want your friends to be able to add their own songs to the queue, do the following:

 1. Run `edit config.lua` to the the config.
 2. Add a comma to the quote after your name, and then add type `"your friend's name",` below that line.
 3. Restart zMusic

 
