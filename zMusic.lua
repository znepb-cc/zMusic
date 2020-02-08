
local config = dofile('config.lua')
os.loadAPI("json")
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

local chat = peripheral.wrap(config.chatboxSize)
chat.capture("^\\")

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
    chat.tell("Now Playing: "..queue[1].name)
    tape.play()
  end

  local function search(q, usr)
    chat.tell("Searching: "..q)
    local formattedQuery = textutils.urlEncode(q)
    log('Searching for '..q)
    local data, error = http.get("https://www.googleapis.com/youtube/v3/search?q="..formattedQuery.."&maxResults=10&part=snippet&key="..config.apiKey)
    if error then
      chat.tell("YouTube returned an error: "..error)
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

          chat.tell("Added "..item.snippet.title.." to the queue")
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

  local function getArgs(str)
    local args = {}
    local cstr = ""

    for i = 1, string.len(str) do
      if str:sub(i, i) == " " then
        table.insert(args, cstr)
        cstr = ""
      else
        cstr = cstr .. str:sub(i, i)
      end
    end

    table.insert(args, cstr)
    cstr = ""

    return args
  end

  local function eventListener()
    log("Now listening", "success")
    while true do
      local e = {os.pullEvent()}
      if e[1] == "chat_capture" then
        local msg, usr = e[2], e[4]
        local args = getArgs(msg)
        msg = args[1]
        for i, v in pairs(args) do
        end
        table.remove(args, 1)
        if true then -- I'm too lazy to go through everything and change it.
          if msg == "\\zmusic" then
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
                  chat.tell("The queue is empty")
                elseif playing == false then
                  log("Unpausing music", "success")
                  playing = true
                  chat.tell("Resumed music")
                  tape.play()

                end
              end
            elseif args[1] == "stop" then
              log("Stopping song")
              if playing == true then
                tape.stop()
                playing = false
                log("Song stopped", "success")
                chat.tell("Pasued music. Use \zmusic clear to clear the queue.")
              elseif playing == false then
                log("Nothing is playing", "warning")
                chat.tell("Nothing is playing" )
              end
            elseif args[1] == "skip" then
              if queue[2] then
                stop()
                tape.seek(queue[1].size)
                log("Skipping song", "success")
                chat.tell("Skipped song")
              else
                log("Nothing left in queue", "warning")
                chat.tell("&cThere is nothing left in the queue")
              end
            elseif args[1] == "queue" then
              if #queue > 0 then
                log("Sending queue", "success")
                for i, v in pairs(queue) do
                  chat.tell("Position: &l"..i.."&r Name: &l"..v.name.."&r ID: &l"..v.id)
                end
              else
                log("The queue is empty", "warning")
                chatbox.tell("The queue is empty")
              end
            elseif args[1] == "clear" then
              queue = {}
              log("Cleared queue", "success")
              chat.tell("Cleared the queue")
            elseif args[1] == "volume" then
              log('Received set volume')
              if tonumber(args[2]) == nil then
                if args[2] == "reset" then
                  log("Volume reset", "success")
                  tape.setVolume(1)
                  chat.tell("Set the volume to 1")
                else
                  log("Volume reset", "warning")
                  chat.tell("Not a number!")
                end
              else
                local vol = tonumber(args[2])/10
                if vol > 1 then
                  log("Volume can not be more than 10", "success")
                  chat.tell("Volume cannot be more than 10")
                elseif vol < 0.1 then
                  log("Volume can not be less than 1", "success")
                  chat.tell("Volume cannot be less than 1")
                else
                  log("Volume set to "..vol, "success")
                  tape.setVolume(vol)
                  chat.tell("Set the volume to "..args[2])
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
  chat.tell("Fatal Error: "..err)
  log("Crashed! "..err, "error")
end

