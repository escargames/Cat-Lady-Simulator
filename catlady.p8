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
    cartdata("ldjam42")
    state = "menu"
    begin_menu()
end

function _update()
    if (state == "menu") then
        update_menu()
    elseif (state == "play") then
        update_play()
        update_time()
    elseif (state == "pause") then
        update_pause()
    end
end

function _draw()
    config[state].draw()
end

--
-- cool functions
--

-- cool print (outlined)

function coprint(text, x, y)
    for i = -1,1 do
        for j = -1,1 do
            print(text, x+i, y+j, 0)
        end
    end
end

-- cool print (centered)

function cprint(text, y, color)
    local x = 64 - 2 * #text
    coprint(text, x, y)
    print(text, x, y, color)
end

-- cool print (outlined, scaled)

function cosprint(text, x, y, height, color)
    -- save first line of image
    local save={}
    for i=1,96 do save[i]=peek4(0x6000+(i-1)*4) end
    memset(0x6000,0,384)
    print(text, 0, 0, 7)
    -- restore image and save first line of sprites
    for i=1,96 do local p=save[i] save[i]=peek4((i-1)*4) poke4((i-1)*4,peek4(0x6000+(i-1)*4)) poke4(0x6000+(i-1)*4, p) end
    -- cool blit
    pal() pal(7,0)
    for i=-1,1 do for j=-1,1 do sspr(0, 0, 128, 6, x+i, y+j, 128 * height / 6, height) end end
    pal(7,color)
    sspr(0, 0, 128, 6, x, y, 128 * height / 6, height)
    -- restore first line of sprites
    for i=1,96 do poke4(0x0000+(i-1)*4, save[i]) end
    pal()
end

-- cool print (centered, outlined, scaled)

function csprint(text, y, height, color)
    local x = 64 - (2 * #text - 0.5) * height / 6
    cosprint(text, x, y, height, color)
end

-- cool timer

function ctimer()
    sec -= 1/30
    if (sec <= 1) then 
        min -= 1
        sec += 60
    end
    if min < 0  then
        state = "pause"
    end
end

-- cool tostring

function ctostr(n, l)
    local z = 10
    if #tostr(n) < l then
        for i = 1,l-#tostr(n) do
            local z *= 10
        end
        return sub(tostr(z), 2, #tostr(z))..tostr(n)
    else return tostr(n)
    end
end

--
-- menu state handling
--

function begin_menu()
    player = {x = 28, y = 54, dir = false, spd = 2, bob = 0, walk = 0}
    cats = {}
    bowls = {}
end

function update_menu()
    update_cats()
    if btnp(3) then
        player.y = 74
    elseif btnp(2) then
        player.y = 54
    end

    if btn(4) and player.y == 54 then
        state = "play"
        begin_play()
    end
    player.bob += 0.08
end

--
-- play state handling
--

function begin_play()
    level = 1
    player = {x = 64, y = 64, dir = false, spd = 2, bob = 0, walk = 0}
    cats = { {x = 62, y = 20, color = 1, dir = false, spd = 1.5, want = 0},
             {x = 92, y = 40, color = 2, dir = false, spd = 1.5, want = 1},
             {x = 86, y = 86, color = 3, dir = false, spd = 1.5},
             {x = 40, y = 80, color = 2, dir = false, spd = 1.5},
             {x = 26, y = 106, color = 1, dir = false, spd = 1.5},
             {x = 96, y = 106, color = 1, dir = false, spd = 1.5, want = 2}}
    bowls = { { cx = 5, cy = 4, color = 0 },
              { cx = 2, cy = 10, color = 1 }}
    min=0
    sec=15
end

function update_play()
    update_player()
    update_cats()
end

function update_time()
    if min < 1 and sec < 11 then
        colortimer = 8
    else
        colortimer = 7
    end
    ctimer(min, sec)
end

--
-- pause state handling
--

function update_pause()
end
--
-- collisions
--

function wall(x,y)
    local m = mget(x/8,y/8)
    return m==0 or fget(m,0)
end

function wall_area(x,y,w,h)
    return
        wall(x-w,y-h) or
        wall(x+w,y-h) or
        wall(x-w,y+h) or
        wall(x+w,y+h)
end

function has_cat_nearby(x, y)
    for i=1,#cats do
        local cat=cats[i]
        if max(abs(cat.x - x), abs(cat.y - y)) < 8 then return true end
    end
end

--
-- player
--

function update_player()
    local walk = false
    local x = player.x
    if btn(0) then
        x -= player.spd
    elseif btn(1) then
        x += player.spd
    end

    if not wall_area(x, player.y, 4, 4) and not has_cat_nearby(x, player.y) then
        if (player.x != x) walk = true player.dir = player.x > x
        player.x = x
    end

    local y = player.y
    if btn(2) then
        y -= player.spd
    elseif btn(3) then
        y += player.spd
    end

    if not wall_area(player.x, y, 4, 4) and not has_cat_nearby(player.x, y) then
        if (player.y != y) walk = true
        player.y = y
    end

    if (walk) player.walk += 0.25
    player.bob += 0.08
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

        if not wall_area(x, y, 4, 4) and max(abs(x - player.x), abs(y - player.y)) > 8 then
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

function draw_background()
    fillp(0x5a5a)
    rectfill(0,0,128,128,1)
    fillp()
end

function draw_menu()
    csprint("ldjam42", 25, 10, 12)
    cprint("play", 50, 7)
    cprint("choose level", 70, 7)
end

function draw_world()
    map(0,0,0,0,128,64)
    foreach(bowls, function(b)
        spr(23 + b.color, b.cx * 8, b.cy * 8)
    end)
end

function draw_grandma()
    palt(11, true)
    palt(0, false)
    local sw, cw = sin(player.walk / 4), cos(player.walk / 4)
    spr(100, player.x - 4 - 3 * sw, player.y - 6 + 2 * abs(cw))
    spr(116, player.x - 4 - 3 * cw, player.y - 3 + 1.5 * abs(sw))
    spr(98 + 16 * flr(player.walk % 2), player.x - 8, player.y - 4, 2, 1, player.dir)
    spr(116, player.x - 4 + 3 * cw, player.y - 3 + 1.5 * abs(sw))
    spr(100, player.x - 4 + 3 * sw, player.y - 6 + 2 * abs(cw))
    spr(96, player.x - 8, player.y - 12 + sin(player.bob), 2, 2, player.dir)
    palt()
end

function draw_pause()
    cprint("time out", 25, 7)
end

function draw_cats()
    foreach(cats, function(cat)
        palt(11, true)
        palt(0, false)
        if cat.color == 1 then
            pal(4,5) pal(9,6)
        elseif cat.color == 2 then
            pal(4,4) pal(9,4)
        elseif cat.color == 3 then
            pal(4,4) pal(9,9)
        end
        spr(16, cat.x - 8, cat.y - 12, 2, 2, cat.dir)

        if cat.want then
            local x, y = cat.x - 8, cat.y - 22
            spr(64, x, y, 2, 2, cat.dir)
            palt(11, false)
            palt(0, true)
            spr(82 + cat.want, x + 4, y + 1, 1, 1, cat.dir)
        end
    end)
    pal()
end

function draw_ui()
    palt(11, true)
    palt(0, false)
    spr(20, 2, 110, 2, 2)
    palt()
    cosprint(tostr(min)..":"..ctostr(flr(sec), 2), 96, 4, 9, colortimer)
end

config.menu.draw = function ()
    camera(0, 48*8)
    draw_world()
    draw_cats()
    camera()
    draw_menu()
    draw_grandma()
end

config.play.draw = function ()
    draw_background()
    camera(player.x - 64, player.y - 64)
    draw_world()
    draw_cats()
    draw_grandma()
    camera()
    draw_ui()
end

config.pause.draw = function ()
    draw_background()
    camera(player.x-64, player.y - 64)
    draw_world()
    draw_cats()
    camera()
    draw_pause()
    
end

__gfx__
00000000799999999999999477777776777767667777777777777774999999999999999977777777000000000000000033333333333333333333333333333333
00000000799999999999999477777776777676767797979799949494999999999999999997979797000000000000000033333333333333333333333330003333
00700700799999999999999477777776777767667979799999994944999999999999999979797979000000000000000033333333333333333333333301503333
00077000799999999999999477777776777676767799999999999994999999999999999999999999000000000000000033333000003333333333333011500333
00077000799999999999999477777776777767667979999999999994999999999999999999999999000000000000000033330555503333333333300001110333
00700700799999999999999477777776777676767999999999999994494949499999999999999999000000000000000033305555503333333330055550000333
00000000799999999999999477777766777767667999999999999994949494949999999999999999000000000000000033005550003333333305555555550333
0000000079999999999999946666666f6666666d7999999999999994444444449999999999999999000000000000000033055003333000003055555550055033
bbbbbbbbbbbbbbbb9555555055050009bbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000003055503333301111055555550e005033
bbbbbbbbbbbbbbbb5567777777777600bb000000000000bb00000000000000000000000000000000000000000000000030555033333066611550055500705033
bbbbbbbbbbbbbbbb5677777777777760b0011111d11d1d5b0000000000000000000000000000000000000000000000003055503333330666550e005550055003
bbbbbbbbbbb0bb0b5677777777777760b017777777777d5b00000000000000000000000000000000000000000000000030555033333306655500705556600033
bbbbbbbbbb09b0905677777777777760b01777777747765b00000000000000000000000000000000000000000000000030555003333300555550055666666033
bbbbbbbbb04904905677777777777760b017744774947d5b00000000000000000000000000000000000000000000000033055550033333055555566600660003
bbbbbbbbb09191905566666666666600b01749f47747765b00000000000000000000000000000000000000000000000033005555500000005555666606660333
bbbb0000009090905655555055050060b01749947777765b00000000000000000000000000000000000000000000000033300555555555550506666666660333
bbb04449499999905667777777777660b0d7744774477d5b00000000000000000000000000000000000000000000000033333005555555555056066666603333
bb0949494999900b5677777777777760b017777749f4765b00000000000000000000000000000000000000000000000033333055555555550500666666033333
bb04949999990bbb5677777777777760b01777774994765b00000000000000000000000000000000000000000000000033330055555555555505000000333333
bb0909909090bbbb5600777777777760b0d777777447765b00000000000000000000000000000000000000000000000033330555555555555555555550333333
bb0909009040bbbb5666777777777760b01777777777765b00000000000000000000000000000000000000000000000033330555555555555555555550033333
bb0909009090bbbb5677777777777760b0dd6d66d6666d5b00000000000000000000000000000000000000000000000033330555555555555505505555003333
bbb0b0bb0b0bbbbb5677777777777760bb555555555555bb00000000000000000000000000000000000000000000000033333055555000005550000555503333
bbbbbbbbbbbbbbbb5677777777777760bbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000033330055500503305555030556603333
00000000000000005777777777777760000000000000000000000000000000000000000000000000000000000000000033305555055503305555003066603333
00000000000000005777777777777760000000000000000000000000000000000000000000000000000000000000000033065555055033330555603306603333
00000000000000005777777777777760000000000000000000000000000000000000000000000000000000000000000033066600300333330066603330033333
00000000000000005777777777777760000000000000000000000000000000000000000000000000000000000000000033066033333333333066603333333333
00000000000000005777777777777760000000000000000000000000000000000000000000000000000000000000000033300333333333333300033333333333
00000000000000005777777777777760000000000000000000000000000000000000000000000000000000000000000033333333333333333333333333333333
00000000000000005566666666666600000000000000000000000000000000000000000000000000000000000000000033333333333333333333333333333333
00000000000000006555555055050006000000000000000000000000000000000000000000000000000000000000000033333333333333333333333333333333
bbbbb50005bbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb006676600bbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb06777777760bbb0800008003000030010000100400004000000000000000000000000000000000000000000000000000000000000000000000000000000000
b5677777777765bb8ee88ef83bb33ba31cc11c61499449a400000000000000000000000000000000000000000000000000000000000000000000000000000000
b0677777777760bb8effffe83baaaab31c6666c149aaaa9400000000000000000000000000000000000000000000000000000000000000000000000000000000
b0777777777770bb0888888003333330011111100444444000000000000000000000000000000000000000000000000000000000000000000000000000000000
b0677777777760bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b5677777777765bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb06777777760bbbf880000000000000000c00000044440000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb506777605bbbbf8888000a000bb00000c00000497974000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbb05770bbbbbbf8888800ba0b33b000cc100047aaaa7400000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbb0570bbbbbb0f888e800bb3373b0c7cd100494a4a9400000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbb070bbbbbb0f88807803333333c7cccd1049aaaa7400000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbb0bbbbbbb0f88888831013310c7cccd1049a4aa9400000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbb00f88887100011000c7cd1000499974000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbb000777700000000000dd10000044440000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbb2222222bbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbdddbbbbbbbbbb288888882bbbbbbb22bbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbd6776bbbbbbbb28888888882bbbbb2882bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbd677776bbbbbbb28888888882bbbbb8ff8bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb667777776bbbbbbb222888882bbbbbbeffebb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb6777fff66bbbbbbbbbb22222bbbbbbbbeebbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb677f5f5f6bbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbb77f0f0fbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbfffffbbbbbbbbbbbbb2222bbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbefffbbbbbbbbbbb22288882bbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbeeebbbbbbbbbb288888882bbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbb2888888882bbbbb1221bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbb288888882bbbbbb1cc1bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbb28822222bbbbbbbb11bbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbb22bbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60808080808080808080808080808050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20707070707070707070707070707010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20303030303030303030303030304010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20303030303030303030303030304010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20303030303030303030303030304010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20303030303030303030303030304010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000032000000000000000000
20303030303030303030303030304010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20303030303030303030303030304010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20303030303030303030303030304010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20303030303030303030303030304010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20303030303030303030303030304010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20303030303030303030303030304010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20303030303030303030303030304010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20303030303030303030303030304010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
80909090909090909090909090909080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
80808080808080808080808080808080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0001010000010101010100000000000000000101000000000000000000000000000001010000000000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0608080808080808080808080808080500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0207071213070707070707121307070100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203042223030303030304222303040100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203042223030303030304323303040100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203043233030303030303030303040100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203030303030303030303030303040100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203030303030303030303030303040700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203030303030303030303030303030400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203030303030303030303030303030400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203030303030304050603030303040500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203030303030304010203030303040100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203030303030304010203030303040100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203030303030304010203030303040100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203030303030304010203030303040100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0809090909090909080809090909090800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0808080808080808080808080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
