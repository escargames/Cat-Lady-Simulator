pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--by niarkou & sam

--
-- standard pico-8 workflow
--

config = {
    menu = {tl = "menu"},
    play = {tl = "play"},
    pause = {tl = "pause"},
}

function _init()
    state = "play"
    player = {x = 64, y = 64, spd = 1}
    cats = { {x = 32, y = 20, color = 1},
             {x = 40, y = 80, color = 2} }
end

function _update()
     --if (state == "menu") then
       -- update_menu()
    if (state == "play") then
        update_play()
    --elseif (state == "pause") then
        --update_pause()
    end
end

function _draw()
    config[state].draw()
end

--
-- play state handling
--

function update_play()
    update_player()
    update_cats()
end

--
-- walls
--

function wall(x,y)
    return fget(mget(x/8,y/8), 0)
end

function wall_area(x,y,w,h)
    return
        wall(x-w,y-h) or
        wall(x+w,y-h) or
        wall(x-w,y+h) or
        wall(x+w,y+h)
end

--
-- player
--

function update_player()
    local x = player.x
    local y = player.y
    if btn(0) then
        x = player.x - player.spd
    elseif btn(1) then
        x = player.x + player.spd
    end
    
    if btn(2) then
        y = player.y - player.spd
    elseif btn(3) then
        y = player.y + player.spd
    end

    if not wall_area(x,y, 4, 4) then
        player.x = x
        player.y = y
    end
end

--
-- cats
--

function update_cats()
end

--
-- drawing
--
function draw_world()
    cls()
    map(0,0,0,0,16,16)
end

function draw_play()
    palt(11, true)
    palt(0, false)
    spr(18, player.x - 8, player.y - 12, 2, 2)
    palt()
end

function draw_cats()
    palt(7, true)
    palt(0, false)
    foreach(cats, function(cat)
        spr(16, cat.x - 8, cat.y - 12, 2, 2)
    end)
    palt()
end

config.play.draw = function ()
    camera(player.x - 64, player.y - 64)
    draw_world()
    draw_cats()
    draw_play()
    camera()
end

__gfx__
00000000444444445555555588888888000000000000000000000000000000000000000000000000000000000000000033333333333333333333333333333333
0000000044444444555555558aaaaaa8000000000000000000000000000000000000000000000000000000000000000033333333333333333333333330003333
0070070044444444555555558aaaaaa8000000000000000000000000000000000000000000000000000000000000000033333333333333333333333301503333
0007700044444444555555558aaaaaa8000000000000000000000000000000000000000000000000000000000000000033333000003333333333333011500333
0007700044444444555555558aaaaaa8000000000000000000000000000000000000000000000000000000000000000033330555503333333333300001110333
0070070044444444555555558aaaaaa8000000000000000000000000000000000000000000000000000000000000000033305555503333333330055550000333
0000000044444444555555558aaaaaa8000000000000000000000000000000000000000000000000000000000000000033005550003333333305555555550333
00000000444444445555555588888888000000000000000000000000000000000000000000000000000000000000000033055003333000003055555550055033
7777777777777777bbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000000000003055503333301111055555550e005033
7777777777777777bbbbbbb00bbbbbbb000000000000000000000000000000000000000000000000000000000000000030555033333066611550055500705033
7777777777777777bbbbb00660bbbbbb00000000000000000000000000000000000000000000000000000000000000003055503333330666550e005550055003
7777777777707707bbbb0677760bbbbb000000000000000000000000000000000000000000000000000000000000000030555033333306655500705556600033
7777777777097090bbb067777770bbbb000000000000000000000000000000000000000000000000000000000000000030555003333300555550055666666033
7777777770490490bbb060007770bbbb000000000000000000000000000000000000000000000000000000000000000033055550033333055555566600660003
7777777770919190bbb001ff0100bbbb000000000000000000000000000000000000000000000000000000000000000033005555500000005555666606660333
7777000000909090bbbb171f171bbbbb000000000000000000000000000000000000000000000000000000000000000033300555555555550506666666660333
7770444949999990bbbbf1fff1bbbbbb000000000000000000000000000000000000000000000000000000000000000033333005555555555056066666603333
7709494949999007bbbbbfffe8222bbb000000000000000000000000000000000000000000000000000000000000000033333055555555550500666666033333
7704949999990777bbbb28ee888882bb000000000000000000000000000000000000000000000000000000000000000033330055555555555505000000333333
7709099090907777bbb288888882882b000000000000000000000000000000000000000000000000000000000000000033330555555555555555555550333333
7709090090407777bbb28888888222bb000000000000000000000000000000000000000000000000000000000000000033330555555555555555555550033333
7709090090901777bbb222222222bbbb000000000000000000000000000000000000000000000000000000000000000033330555555555555505505555003333
7170707101017177bbbb1dd1b1dd1bbb000000000000000000000000000000000000000000000000000000000000000033333055555000005550000555503333
7717171717171777bbbbb11bbb11bbbb000000000000000000000000000000000000000000000000000000000000000033330055500503305555030556603333
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033305555055503305555003066603333
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033065555055033330555603306603333
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033066600300333330066603330033333
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033066033333333333066603333333333
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033300333333333333300033333333333
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033333333333333333333333333333333
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033333333333333333333333333333333
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033333333333333333333333333333333
__gff__
0001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020100000000000000000000000000000000000000000000010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020100000000000000000000000000010101010101010101010202020202020202020101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020100000000000000000000000000010202020202020202010202020202020202020202020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020100000000000000000000000000010202020202020202010202020202020202020202020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020100000000000000000000000000010202020202020202010202020201020202020202020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020100000000000000000000000001010202020202020202010202020201020202020202020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000001020202020202020201010202020201020202020202020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000001020202020202020201020202020101020202020202020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000001020202020202020202020202020102020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000001020202020202020202020202020102020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000001020202020202020202020202020102020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000001010101010101010202020202020102020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000001020202020202020202020202020102020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000001020202020202020202020202020102020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000001020202020202020202020202020102020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000001020202020202020202020202020102020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000001010101010202020202020202020102020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000101010101010101010101020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
