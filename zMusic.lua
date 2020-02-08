
local config = dofile('config.lua')
local function log(msg, type)
  if type == nil then type = "default" end
  local fullMessage = "["..textutils.formatTime(os.time(), false).."] " .. msg
  if term.isColor() then
    if type == "default" then
      term.setTextColor(colors.white)
    elseif type == "warning" then
      term.setTextColor(colors.yellow)
    elseif type == "error" then
      term.setTextColor(colors.red)
    elseif type == "success" then
      term.setTextColor(colors.lime)
    end
  else
    if type == "warning" then
      fullMessage = "["..textutils.formatTime(os.time(), false).."] [WARN] " .. msg
    elseif type == "error" then
      fullMessage = "["..textutils.formatTime(os.time(), false).."] [ERROR] " .. msg
    elseif type == "success" then
      fullMessage = "["..textutils.formatTime(os.time(), false).."] [SUCCESS] " .. msg
    end
  end
  print(fullMessage)
end

local function main()
  local queue = {}
  local playing = false
  local tape = peripheral.find("tape_drive")
  local nextReady = true
  local lastUser = ""
  tape.setVolume(1)
  log("Started", "success")

  local function downloadSong(id)
    log('Wiping disk...')
    tape.stop()
    tape.seek(-tape.getSize())
    tape.write(string.char(0xAA):rep(tape.getSize()))
    tape.seek(-tape.getSize())
    log("Downloading audio...")
    local handle = http.get("http://"..config.ip.."/?v="..id, nil, true)
    local data = handle.readAll()
    handle.close()
    queue[1].size = #data
    log('Writing...')
    tape.write(data)
    tape.seek(-tape.getSize())
    log("Complete")
  end

  local function play(usr)
    log('Playing: '..queue[1].name)
    chatbox.tell(usr, "&aNow Playing: &2"..queue[1].name, "zMusic", "", "format")
    tape.play()
  end

  local function stop()

  end

  local function search(q, usr)
    chatbox.tell(usr, "Searching: &7"..q, "zMusic", "", "format")
    local formattedQuery = textutils.urlEncode(q)
    log('Searching for '..q)
    local data, error = http.get("https://www.googleapis.com/youtube/v3/search?q="..formattedQuery.."&maxResults=10&part=snippet&key="..config.apiKey)
    if error then
      chatbox.tell(usr, "&cYouTube returned an error: "..error, "zMusic", "", "format")
      log('YouTube returned an error: '..error, "error")
    else
      log("Decoding JSON...")
      local jsonData = json.decode(data.readAll())
      local function check(id)
        log("Checking: "..id)
        local item = jsonData.items[id]
        if item.id.kind == "youtube#video" then
          table.insert(queue, {
            id = item.id.videoId,
            name = item.snippet.title
          })
          log("Added to queue", "success")

          chatbox.tell(usr, "&aAdded &2"..item.snippet.title.."&r&a to the queue", "zMusic", "", "format")
          return true
        else
          log("Not OK", "warning")
          return false
        end
      end

      log("Searching for video...")
      local c = 1
      local found = false
      repeat
        found = check(c)
        c = c + 1
      until found == true
    end
  end

  local function isTrusted(user)
    for i, v in pairs(config.trustedUsers) do
      if v == user then
        return true
      end
    end
    return false
  end

  log("Now listening", "success")
  local function eventListener()
    while true do
      local e = {os.pullEvent()}
      if e[1] == "command" then
        local usr, msg, args = e[2], e[3], e[4]
        if isTrusted(usr) then
          if msg == "zmusic" then
            lastUser = usr
            log("Command received")
            if args[1] == "play" then
              log("Playing song", "success")
              if args[2] ~= nil then
                nextReady = false
                local q = ""
                for i = 2, #args do 
                  q = q..args[i]
                  if args[i+1] then
                    q = q .. " "
                  end
                end
                search(q, usr)
                nextReady = true
              
              elseif args[2] == nil then
                if #queue == 0 then
                  log("The queue is empty", "warning")
                  chatbox.tell(usr, "&cThe queue is empty", "zMusic", "", "format")
                elseif playing == false then
                  log("Unpausing music", "success")
                  playing = true
                  chatbox.tell(usr, "&aResumed music", "zMusic", "", "format")
                  tape.play()

                end
              end
            elseif args[1] == "stop" then
              log("Stopping song")
              if playing == true then
                tape.stop()
                playing = false
                log("Song stopped", "success")
                chatbox.tell(usr, "&aPasued music. Use \zmusic clear to clear the queue.", "zMusic", "", "format")
              elseif playing == false then
                log("Nothing is playing", "warning")
                chatbox.tell(usr, "&cNothing is playing", "zMusic", "", "format")
              end
            elseif args[1] == "skip" then
              if queue[2] then
                stop()
                tape.seek(queue[1].size)
                log("Skipping song", "success")
                chatbox.tell(usr, "&aSkipped song", "zMusic", "", "format")
              else
                log("Nothing left in queue", "warning")
                chatbox.tell(usr, "&cThere is nothing left in the queue", "zMusic", "", "format")
              end
            elseif args[1] == "queue" then
              if #queue > 0 then
                log("Sending queue", "success")
                for i, v in pairs(queue) do
                  chatbox.tell(usr, "Position: &l"..i.."&r Name: &l"..v.name.."&r ID: &l"..v.id, "zMusic", "", "format")
                end
              else
                log("The queue is empty", "warning")
                chatbox.tell(usr, "&cThe queue is empty", "zMusic", "", "format")
              end
            elseif args[1] == "clear" then
              queue = {}
              log("Cleared queue", "success")
              chatbox.tell(usr, "&aCleared the queue", "zMusic", "", "format")
            elseif args[1] == "volume" then
              log('Received set volume')
              if tonumber(args[2]) == nil then
                if args[2] == "reset" then
                  log("Volume reset", "success")
                  tape.setVolume(1)
                  chatbox.tell(usr, "&aSet the volume to 1", "zMusic", "", "format")
                else
                  log("Volume reset", "warning")
                  chatbox.tell(usr, "&cNot a number!", "zMusic", "", "format")
                end
              else
                local vol = tonumber(args[2])/10
                if vol > 1 then
                  log("Volume can not be more than 10", "success")
                  chatbox.tell(usr, "&cVolume cannot be more than 10", "zMusic", "", "format")
                elseif vol < 0.1 then
                  log("Volume can not be less than 1", "success")
                  chatbox.tell(usr, "&cVolume cannot be less than 1", "zMusic", "", "format")
                else
                  log("Volume set to "..vol, "success")
                  tape.setVolume(vol)
                  chatbox.tell(usr, "&aSet the volume to "..args[2], "zMusic", "", "format")
                end
              end
            end
          end
        end
      end
    end
  end

  local function queueListener()
    while true do
      log('[queue] Checking')
      if playing == false and queue[1] ~= nil and nextReady == true then
        log('[queue] Loading next song')
        downloadSong(queue[1].id)
        log('[queue] Now playing')
        play(lastUser or config.primaryUser)
        playing = true
        nextReady = false
      end
      sleep(1)
    end
  end

  local function endListener()
    while true do
      
      if queue[1] ~= nil then
        if queue[1].size ~= nil then
          log('[end] Checking: '..tostring(tape.getPosition() >= queue[1].size))
          if tape.getPosition() >= queue[1].size then
            log('[end] Tape over')
            playing = false
            table.remove(queue, 1)
            nextReady = true
          end
        end
      end
      sleep(1)
    end
  end

  parallel.waitForAll(eventListener, queueListener, endListener)
end

local ok, err = pcall(main)

if not ok then
  chatbox.tell(config.primaryUser, "&4Fatal Error: "..err, "zMusic", "", "format")
  log("Crashed! "..err, "error")
end
