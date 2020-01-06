return {
  ip = "", -- (required) The IP (or domain) the youtube-dl server is located. 
		   -- Do not put the https:// or http://! If you are hosting the file 
		   -- on a different file that root, put / and then the file path after
		   -- the slash.
  apiKey = "", -- (required) The YouTube API key to search songs
  primaryUser = "", -- (required) The user that will be notified of errors
  trustedUsers = { -- (at least one) Users that are trusted and can run commands 
    ""
  }, 
}
