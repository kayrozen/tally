--
--        Mark423 TALLY SENSOR
--
config_file="config.lua"
-- nodemcu pins https://github.com/nodemcu/nodemcu-firmware/blob/master/docs/en/modules/gpio.md 
-- layout of the pins on the board: google lolin esp8266
-- i messed up the pin wirings, the pinmap is adjusted to map each pin to the right
-- channel
pinmap = {}
pinmap[5]=0  --d5
pinmap[6]=1  --d6
pinmap[7]=2  --d7
pinmap[1]=3  --d1

pinstate = 0
ready = false

function init()
  print("Mark423 Tally controller starting...")
  if m423_running == true then
    print("M423 is already running, aborting. Reboot the node to run updated software")
    return
  end
  m423_running = true
  read_config()
  init_inputs()
  wifi_setup()
  start_heartbeat()
end

-- We're using broadcast UDP to communicate to the LED nodes
-- The network sometimes loses these packets. The heartbeat
-- will make sure that the current state is broadcast every
-- 500ms.
function heartbeat()
  if ready then
    send_pinstate()
  end
end
  
function start_heartbeat()
  hb_timer = tmr.create()
  hb_timer:register(500, tmr.ALARM_AUTO, heartbeat)
  hb_timer:start()
end

function init_inputs()
  for p,c in pairs(pinmap) do
    print(string.format("Configuring pin %d", p))
    gpio.mode(p, gpio.INT, gpio.PULLUP)
    local cb = function(l,w) return input_trigger(p,l,w) end
    gpio.trig(p, "both", cb)
  end
end

function send_pinstate()
  message = string.char(2) .. string.char(pinstate)
  bcaddr = wifi.sta.getbroadcast()
  udpSocket:send(5004, bcaddr, message)
end

function input_trigger(pin, level, when)
  local channel = pinmap[pin]
  print(pin .. "TRIG")
  if not ready then return end
  -- following is needed for debouncing a switch
  -- don't know if it will be needed in the real app
  tmr.delay(10)
  level = gpio.read(pin)
  
  mask = bit.bit(channel)
  if level == gpio.LOW then
    print(channel .. "LO")
    pinstate = bit.bor(pinstate, mask)
  else
    print(channel .. "HI")
    pinstate = bit.band(pinstate, bit.bnot(mask))
  end
  send_pinstate()
end

function wifi_setup()
  print("Starting wifi setup")
  enduser_setup.start(
    function()
      local sta_config = wifi.sta.getconfig(true)
      sta_config.save = true
      sta_config.got_ip_cb=udp_listen
      wifi.sta.config(sta_config)
    end,
    function(err, str)
      print("enduser_setup: Err #" .. err .. ": " .. str)
    end,
    print -- Lua print function can serve as the debug callback
  );
end

function udp_listen()
  udpSocket = net.createUDPSocket()
  udpSocket:listen(5004, wifi.sta.getip())
  udpSocket:on("receive", parse_packet)
  port, ip = udpSocket:getaddr()
  print(string.format("local UDP socket address / port: %s:%d", ip, port))
  ready = true
end

function parse_packet(s, data, port, ip)
  command = string.byte(data)
  if command == 1 then
    -- channel 255 means sensor
    message = string.format(string.char(4) .. "%s,%d", node.chipid(), 255)
    s:send(port, ip, message)
  end
end

function read_config()  
  if not file.exists(config_file) then return end
  dofile(config_file)
end

function write_config()
  file.open(config_file, "w")
  --stub... no actual config.. yet
  --file.write(string.format("channel=%d", channel))
  file.close()
end
init()
