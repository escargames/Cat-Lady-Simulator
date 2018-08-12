pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--by niarkou & sam

config = {
    menu = {tl = "menu"},
    play = {tl = "play"},
    pause = {tl = "pause"},
}

--
-- standard pico-8 workflow
--

function _init()
    cartdata("ldjam42")
    state = "menu"
    begin_menu()
    pause_menu()
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

function ctimer(t)
    if t.sec > 0 then
        t.sec -= 1/30
    end

    if (t.sec <= 1) then 
        t.min -= 1
        t.sec += 60
    end

    if t.min < 0  then
        t.sec = 0
        t.min = 0
        state = "pause"
    end
end

-- cool tostring (adding "0")

function ctostr(n, l)
    local a = tostr(n)
    while #a<l do
        a = "0"..a
    end
    return a
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
        level = 1
        begin_play()
    elseif btn(4) and player.y == 74 then
        state="play"
        level = 2
        begin_play()
    end
    player.bob += 0.08
end

--
-- play state handling
--

function make_level(level)
    local splayer, scats, sbowls
    if level == 1 then
        stimer = {min = 1, sec = 15}
        splayer = {x = 64, y = 64, dir = false, spd = 2}
        scats = { {x = 26, y = 60},
                  {x = 92, y = 40},
                  {x = 86, y = 86},
                  {x = 40, y = 80},
                  {x = 36, y = 98},
                  {x = 100, y = 106} }
        sspd = 1
        sbowls = { { cx = 1.5, cy = 2.5, color = 0 },
                   { cx = 3.5, cy = 9.5, color = 1 } }
    end

    if level == 2 then
        stimer = {min = 1, sec = 30}
        splayer = {x = 26*8, y = 7*8, dir = false, spd = 2}
        scats = { {x = 19*8, y = 4*8, color = 1, dir = false, want = 0},
                  {x = 20*8, y = 9*8, color = 2, dir = false, want = 1} }
        sspd = 1
        sbowls = { {cx = 23.5, cy = 5.5, color = 0},
                   {cx = 26, cy = 9, color = 1} }
    end

    return {timer = stimer, player = splayer, cats = scats, spd = sspd, bowls = sbowls}
end

function begin_play()
    desc = make_level(level)
    timer = {min = desc.timer.min, sec = desc.timer.sec}
    player = {x = desc.player.x, y = desc.player.y, dir = desc.player.dir, spd = desc.player.spd, bob = 0, walk = 0}
    
    cats = {}
    spd = desc.spd

    bowls = {}
    for i = 1, #desc.bowls do
        add(bowls, {cx = desc.bowls[i].cx, cy = desc.bowls[i].cy, color = desc.bowls[i].color})
    end
end

function update_play()
    -- add a cat by pressing tab
    if btnp(4, 1) then add_cat() end

    update_player()
    update_cats()
end

function update_time()
    if timer.min < 1 and timer.sec < 11 then
        colortimer = 8
    else
        colortimer = 7
    end
    ctimer(timer)
end

--
-- pause state handling
--

function pause_menu()
    menuitem(2, "menu", function() state = "menu" begin_menu() end)
end

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

    if not wall_area(x, player.y, 3, 3) and not has_cat_nearby(x, player.y) then
        if (player.x != x) walk = true player.dir = player.x > x
        player.x = x
    end

    local y = player.y
    if btn(2) then
        y -= player.spd
    elseif btn(3) then
        y += player.spd
    end

    if not wall_area(player.x, y, 3, 3) and not has_cat_nearby(player.x, y) then
        if (player.y != y) walk = true
        player.y = y
    end

    if (walk) player.walk += 0.25
    player.bob += 0.08
end

--
-- cats
--

function add_cat()
    -- spawn a cat at a random location found in desc.cats
    local startid = 1 + flr(rnd(#desc.cats))
    local catdesc = desc.cats[startid]
    add(cats, {x = catdesc.x, y = catdesc.y, color = flr(1 + rnd(3)), dir = rnd() > 0.5})
end

function update_cats() 
    for i = 1,#cats do
        local cat = cats[i]
        if cat.plan then
            -- if the cat has a plan, make it move in that direction
            local x = cat.x
            if cat.plan.dir == 0 then
                cat.dir = true
                x -= spd
            elseif cat.plan.dir == 1 then
                cat.dir = false
                x += spd
            end

            if not wall_area(x, cat.y, 3, 3) and max(abs(x - player.x), abs(cat.y - player.y)) > 8 then
                cat.x = x
            end

            local y = cat.y
            if cat.plan.dir == 2 then
                y -= spd
            elseif cat.plan.dir == 3 then
                y += spd
            end

            if not wall_area(cat.x, y, 3, 3) and max(abs(cat.x - player.x), abs(y - player.y)) > 8 then
                cat.y = y
            end

            -- at the end of the plan, remove the plan
            cat.plan.length -= 1/30
            if cat.plan.length < 0 then
                cat.plan = nil
            end
        else
            -- if it does not have a plan, maybe compute one
            if rnd() > 0.5 then
                cat.plan = { dir = flr(rnd(5)), length = rnd(2) }
                for i=1,#bowls do
                    if bowls[i].color == cat.want then
                        cat.plan.x, cat.plan.y = bowls[i].cx * 8 + 4, bowls[i].cy * 8 + 4
                    end
                end
            end
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
    palt(0, false)
    map(0,0,0,0,128,64)
    palt(0, true)
    foreach(bowls, function(b)
        spr(66 + b.color, b.cx * 8, b.cy * 8)
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
        spr(72, cat.x - 8, cat.y - 12, 2, 2, cat.dir)

        -- if the cat wants something, draw a bubble
        if cat.want then
            local x, y = cat.x - 8, cat.y - 22
            spr(64, x, y, 2, 2, cat.dir)
            palt(11, false)
            palt(0, true)
            spr(82 + cat.want, x + 4, y + 1, 1, 1, cat.dir)
        end

        -- if the cat has a plan, draw a line
        if cat.plan and cat.plan.x then
            line(cat.x, cat.y, cat.plan.x, cat.plan.y, rnd(15))
        end
    end)
    pal()
end

function draw_ui()
    cosprint(tostr(timer.min)..":"..ctostr(flr(timer.sec), 2), 96, 4, 9, colortimer)
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
    camera(player.x - 64, player.y - 64)
    draw_world()
    draw_cats()
    camera()
    draw_ui()
    draw_pause()
    
end

__gfx__
00000000799999999999999477777776777767667777777777777774999999999999999977777777777777760000000033333333333333333333333333333333
00000000799999999999999477777776777676767797979799949494999999999999999997979797777777760000000033333333333333333333333330003333
00700700799999999999999477777776777767667979799999994944999999999999999979797979767dd6760000000033333333333333333333333301503333
00077000799999999999999477777776777676767799999999999994999999999999999999999999777767760000000033333000003333333333333011500333
00077000799999999999999477777776777767667979999999999994999999999999999999999999777777760000000033330555503333333333300001110333
00700700799999999999999477777776777676767999999999999994494949499999999999999999777677760000000033305555503333333330055550000333
00000000799999999999999477777766777767667999999999999994949494949999999999999999777777660000000033005550003333333305555555550333
0000000079999999999999946666666f6666666d79999999999999944444444499999999999999996666666f0000000033055003333000003055555550055033
0000000000000000955555505505000991111111111111101101000911111111111111101101000000000000000000003055503333301111055555550e005033
00000000000000005567777777777600112888888888888888888200112444444444444444444200000000000000000030555033333066611550055500705033
0000000000000000567777777777776012888888888888888888882012444444444444444444442000000000000000003055503333330666550e005550055003
00000000000000005677777777777760128888888888888888888820124444444444444444444420000000000000000030555033333306655500705556600033
00000000000000005677777777777760128888888888888888888820124444444444444444444420000000000000000030555003333300555550055666666033
00000000000000005677777777777760128888888888888888888820124444444444444444444420000000000000000033055550033333055555566600660003
00000000000000005566666666666600112222222222222222222200112222222222222222222200000000000000000033005555500000005555666606660333
00000000000000005655555055050060121111111111111011010020121111111111111011010020000000000000000033300555555555550506666666660333
00000000000000005667777777777660122888812888888128888220122767666767676667676220000000000000000033333005555555555056066666603333
00000000000000005677777777777760128888812888888128888820127676767676767676767620000000000000000033333055555555550500666666033333
00000000000000005677777777777760121f888121f8888121f88820126767666767676667676720000000000000000033330055555555555505000000333333
00000000000000005600777777777760128888812888888128888820127777767777777677767620000000000000000033330555555555555555555550333333
00000000000000005666777777777760128888812888888128888820127777767777777677776720000000000000000033330555555555555555555550033333
00000000000000005677777777777760128888812888888128888820127777767777777677767620000000000000000033330555555555555505505555003333
00000000000000005677777777777760128888812888888128888800127777667777777677776720000000000000000033333055555000005550000555503333
000000000000000056777777777777606111111111111110110100056666666f6666666f66666665000000000000000033330055500503305555030556603333
00000000000000005777777777777760911111111101000900000000000000000000000000000000000000000000000033305555055503305555003066603333
00000000000000005777777777777760112666666666620000000000000000000000000000000000000000000000000033065555055033330555603306603333
00000000000000005777777777777760126666666666662000000000000000000000000000000000000000000000000033066600300333330066603330033333
0000000000000000577777777777776012666dddddd6662000000000000000000000000000000000000000000000000033066033333333333066603333333333
000000000000000057777777777777601266d555555d662000000000000000000000000000000000000000000000000033300333333333333300033333333333
00000000000000005777777777777760126d51111115d62000000000000000000000000000000000000000000000000033333333333333333333333333333333
00000000000000005566666666666600112222222222220000000000000000000000000000000000000000000000000033333333333333333333333333333333
00000000000000006555555055050006121111111101002000000000000000000000000000000000000000000000000033333333333333333333333333333333
bbbbb50005bbbbbb000000000000000000000000000000000000000000000000bbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000
bbb006676600bbbb000000000000000000000000000000000000000000000000bbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000
bb06777777760bbb080000800300003001000010040000400000000000000000bbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000
b5677777777765bb8ee88ef83bb33ba31cc11c61499449a40000000000000000bbbbbbbbbbb0bb0b000000000000000000000000000000000000000000000000
b0677777777760bb8effffe83baaaab31c6666c149aaaa940000000000000000bbbbbbbbbb09b090000000000000000000000000000000000000000000000000
b0777777777770bb088888800333333001111110044444400000000000000000bbbbbbbbb0490490000000000000000000000000000000000000000000000000
b0677777777760bb000000000000000000000000000000000000000000000000bbbbbbbbb0919190000000000000000000000000000000000000000000000000
b5677777777765bb000000000000000000000000000000000000000000000000bbbb000000909090000000000000000000000000000000000000000000000000
bb06777777760bbbf880000000000000000c0000004444000000000000000000bbb0444949999990000000000000000000000000000000000000000000000000
bbb506777605bbbbf8888000a000bb00000c0000049797400000000000000000bb0949494999900b000000000000000000000000000000000000000000000000
bbbbb05770bbbbbbf8888800ba0b33b000cc100047aaaa740000000000000000bb04949999990bbb000000000000000000000000000000000000000000000000
bbbbbb0570bbbbbb0f888e800bb3373b0c7cd100494a4a940000000000000000bb0909909090bbbb000000000000000000000000000000000000000000000000
bbbbbbb070bbbbbb0f88807803333333c7cccd1049aaaa740000000000000000bb0909009040bbbb000000000000000000000000000000000000000000000000
bbbbbbbb0bbbbbbb0f88888831013310c7cccd1049a4aa940000000000000000bb0909009090bbbb000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbb00f88887100011000c7cd100049997400000000000000000bbb0b0bb0b0bbbbb000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbb000777700000000000dd1000004444000000000000000000bbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000
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
0001010000010101010100000000000000000101010101010101000000000000000001010101010100010000000000000000010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0608080808080808080808121308080506080808080808080812130100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0207071213070714151516222314160102070707070707070722230100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203042223030424252526323324260102030303030303030432330100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02030422230a03030303030a030304010203030317181819030a040100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203043233030303030303030303040102030303272828290303040100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02030303030303030a0303030303040102121303030303030303040100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020a030317181903030317190303040702222314151603030303040111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020303032728290a03032729030a030402323324252617181903040111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203030303030303030303030303030402030a03030327282903040100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203030a03041416050603030303040502030303030303030303040100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02030303030424260102030a0303040108090909090903040509090800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02171819030a0304010203030303040100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0227282903030304010203030303040100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203030303030304010203030a03040100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0809090909090909080809090909090800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0808080808080808080808080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
