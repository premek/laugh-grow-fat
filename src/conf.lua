local conf = {}

function love.conf(t)
  t.version = "11.1"                -- The LÖVE version this game was made for (string)
  t.window.title = "Laugh & Grow Fat"        -- The window title (string)
  t.window.fullscreen = false        -- Enable fullscreen (boolean)
  --  t.window.fullscreentype = "normal" -- Standard fullscreen or desktop fullscreen mode (string)
  t.window.width = 506
  t.window.height = 479

  conf.t = t
end
return conf
