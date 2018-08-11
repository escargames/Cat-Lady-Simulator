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
    player = {x = 64, y = 64, spd = 2}
    cats = { {x = 32, y = 20, color = 1, dir = false, spd = 1.5},
             {x = 92, y = 40, color = 2, dir = false, spd = 1.5},
             {x = 40, y = 80, color = 3, dir = false, spd = 1.5}}
    bowls = { { cx = 5, cy = 4, color = 0 },
              { cx = 2, cy = 10, color = 1 }}
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
    if btn(0) then
        x -= player.spd
    elseif btn(1) then
        x += player.spd
    end

    if not wall_area(x, player.y, 4, 4) then
        player.x = x
    end

    local y = player.y
    if btn(2) then
        y -= player.spd
    elseif btn(3) then
        y += player.spd
    end

    if not wall_area(player.x, y, 4, 4) then
        player.y = y
    end
end

--
-- cats
--

function update_cats()
    for i = 1,#cats do
        local x = cats[i].x
        local y = cats[i].y
        if cats[i].dir then
            x -= cats[i].spd
        else
            x += cats[i].spd
        end

        if not wall_area(x, y, 4, 4) then
            cats[i].x = x
            cats[i].y = y
        else 
            cats[i].dir = not cats[i].dir
        end
    end
end

--
-- drawing
--
function draw_world()
    cls()
    map(0,0,0,0,16,16)
    foreach(bowls, function(b)
        spr(23 + b.color, b.cx * 8, b.cy * 8)
    end)
end

function draw_play()
    palt(11, true)
    palt(0, false)
    spr(18, player.x - 8, player.y - 12, 2, 2)
    palt()
end

function draw_cats()
    palt(11, true)
    palt(0, false)
    foreach(cats, function(cat)
        if cat.color == 1 then
            pal(4,5) pal(9,6)
        elseif cat.color == 2 then
            pal(4,4) pal(9,4)
        elseif cat.color == 3 then
            pal(4,4) pal(9,9)
        end
        spr(16, cat.x - 8, cat.y - 12, 2, 2, cat.dir)
        
        if cat.dir then
        spr(64, cat.x - 15, cat.y - 16, 1, 1, cat.dir)
        else
        spr(64, cat.x + 7, cat.y - 16, 1, 1, cat.dir)
        end
    end)
    pal()
end

function draw_ui()
    palt(11, true)
    palt(0, false)
    spr(20, 2, 110, 2, 2)
    palt()
end

config.play.draw = function ()
    camera(player.x - 64, player.y - 64)
    draw_world()
    draw_cats()
    draw_play()
    camera()
    draw_ui()
end

__gfx__
00000000677777777777767d77777776777777760000000000000000000000000000000000000000000000000000000033333333333333333333333333333333
00000000766666666666666577777776777777760000000000000000000000000000000000000000000000000000000033333333333333333333333330003333
00700700766666666666666577777776777777760000000000000000000000000000000000000000000000000000000033333333333333333333333301503333
00077000766666666666666577777776777777760000000000000000000000000000000000000000000000000000000033333000003333333333333011500333
00077000766666666666666577777776777777760000000000000000000000000000000000000000000000000000000033330555503333333333300001110333
00700700766666666666666577777776777777760000000000000000000000000000000000000000000000000000000033305555503333333330055550000333
00000000766666666666666577777766777777660000000000000000000000000000000000000000000000000000000033005550003333333305555555550333
00000000555555555555555d6666666f6666666f0000000000000000000000000000000000000000000000000000000033055003333000003055555550055033
7777777777777777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0666666000000000000000000000000000000000000000003055503333301111055555550e005033
7777777777777777bbbbbbdddbbbbbbbbb000000000000bb67777776000000000000000000000000000000000000000030555033333066611550055500705033
7777777777777777bbbbb6776dbbbbbbb0011111d11d1d5b6777777608000080030000300100001000000000000000003055503333330666550e005550055003
7777777777707707bbbb677776dbbbbbb017777777777d5b6777777c8ee88ef83bb33ba31cc11c61000000000000000030555033333306655500705556600033
7777777777097090bbb677777766bbbbb01777777747765b605777768effffe83baaaab31c6666c1000000000000000030555003333300555550055666666033
7777777770490490bbb66fff7776bbbbb017744774947d5b6777777c088888800333333001111110000000000000000033055550033333055555566600660003
7777777770919190bbb6f5f5f776bbbbb01749f47747765b0666c6c0000000000000000000000000000000000000000033005555500000005555666606660333
7777000000909090bbbbf0f0f77bbbbbb01749947777765b67777776000000000000000000000000000000000000000033300555555555550506666666660333
7770444949999990bbbbfffff2bbbbbbb0d7744774477d5b67777776000000000000000000000000000000000000000033333005555555555056066666603333
7709494949999007bbbbbfffe8222bbbb017777749f4765b60577776000000000000000000000000000000000000000033333055555555550500666666033333
7704949999990777bbbb28ee888882bbb01777774994765b67777776000000000000000000000000000000000000000033330055555555555505000000333333
7709099090907777bbb288888882882bb0d777777447765b67777776000000000000000000000000000000000000000033330555555555555555555550333333
7709090090407777bbb28888888222bbb01777777777765b6777777c000000000000000000000000000000000000000033330555555555555555555550033333
7709090090907777bbb222222222bbbbb0dd6d66d6666d5b67777776000000000000000000000000000000000000000033330555555555555505505555003333
7770707707077777bbbb1dd1b1dd1bbbbb555555555555bb6777777c000000000000000000000000000000000000000033333055555000005550000555503333
7777777777777777bbbbb11bbb11bbbbbbbbbbbbbbbbbbbb0666c6c0000000000000000000000000000000000000000033330055500503305555030556603333
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033305555055503305555003066603333
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033065555055033330555603306603333
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033066600300333330066603330033333
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033066033333333333066603333333333
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033300333333333333300033333333333
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033333333333333333333333333333333
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033333333333333333333333333333333
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033333333333333333333333333333333
bb0000bb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b077770b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b077770b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b60000bb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b0bbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0102010201020102010201020102010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102010201020102010201020102010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102030403040304030403040304010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102030403040304030403040304010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102030403040304030403040304010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102030403040304030403040304010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102030403040304030403040304010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102030403040304030403040304010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102030403040304030403040304010202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102030403040304010203040304010200000000000000000000000000000000000000000000010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102030403040304010203040304010200000000000000000000000000010101010101010101010202020202020202020101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102030403040304010203040304010200000000000000000000000000010202020202020202010202020202020202020202020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102030403040304010203040304010200000000000000000000000000010202020202020202010202020202020202020202020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102030403040304010203040304010200000000000000000000000000010202020202020202010202020201020202020202020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102010201020102010201020102010200000000000000000000000001010202020202020202010202020201020202020202020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102010201020102010201020102010200000000000000000000000001020202020202020201010202020201020202020202020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
