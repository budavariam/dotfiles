local wezterm = require 'wezterm'
local config = wezterm.config_builder()

local PROJECT = {
  root = '~/project/hackathon-robotics',
  components = {
    base = '~/project/hackathon-robotics/components',
    simulator = '~/project/hackathon-robotics/components/simulator',
    rosbag = '~/project/hackathon-robotics/components/ros-playback/'
  },
  web = {
    port = '5173',
    path = ''
  }
}

local function create_robot_layout(window, pane)
  local status, err = pcall(function()
    local pane0 = pane:split({
      direction = 'Right',
      size = 0.5,
    })
    local pane1 = pane:split({
      direction = 'Right',
      size = 0.5,
    })
    local pane2 = pane:split({
      direction = 'Bottom',
      size = 0.5,
    })
    local pane3 = pane1:split({
      direction = 'Bottom',
      size = 0.5,
    })
    -- Wait a bit for the shells to be ready
    wezterm.sleep_ms(500)
    
    pane0:send_text(string.format('cd %s && npm run dev\n', PROJECT.components.simulator))    
    pane1:send_text(string.format('cd %s && ros2 bag play --loop ./rosbag2_1.mcap\n', PROJECT.components.rosbag))
    pane2:send_text('pyenv shell system && ros2 launch foxglove_bridge foxglove_bridge_launch.xml send_buffer_limit:=100000000\n')
    pane3:send_text('foxglove-studio "foxglove://open?ds=foxglove-websocket&ds.url=ws://localhost:8765/"\n')
    wezterm.sleep_ms(6000)
    os.execute(string.format('firefox http://localhost:%s/%s &', PROJECT.web.port, PROJECT.web.path))
  end)
  
  if not status then
    wezterm.log_error("Error in create_robot_layout:", err)
  end
end

-- Handle CLI arguments with improved error handling
wezterm.on('gui-startup', function(cmd)
  local status, err = pcall(function()
    if cmd and cmd.args and cmd.args[1] == "--robot-layout" then
      local workspace = wezterm.mux.get_active_workspace()
      local window, pane
      status, window, pane = pcall(function()
        return wezterm.mux.spawn_window({
          workspace = workspace,
        })
      end)
      
      if status and window and pane then
        create_robot_layout(window, pane)
      else
        wezterm.log_error("Failed to spawn window:", err)
      end
    end
  end)
  
  if not status then
    wezterm.log_error("Error in gui-startup:", err)
  end
end)

config.default_prog = { '/bin/zsh' }
config.initial_rows = 40
config.initial_cols = 120

config.use_fancy_tab_bar = true
config.tab_bar_at_bottom = false
config.tab_max_width = 25
config.enable_tab_bar = true
-- I hope there will be an option soon to put it on the left

config.exit_behavior = "Hold"
return config