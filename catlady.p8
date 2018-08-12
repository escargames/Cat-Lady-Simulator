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

    if (t.sec <= 0) then 
        t.min -= 1
        t.sec += 60
    end

    if t.min < 0  then
        t.sec = 0
        t.min = 0
        state = "pause"
        begin_pause()
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
    level = 0
    desc = make_level(level)
    player = {x = desc.player.x, y = desc.player.y, dir = desc.player.dir, spd = desc.player.spd, bob = 0, walk = 0.2}
    display = {cx = desc.display.cx, cy = desc.display.cy, height = desc.display.height, width = desc.display.width}
    cats = {}
end

function update_menu()
    update_cats()
    if btnp(3) then
        player.y = 74
    elseif btnp(2) then
        player.y = 54
    end

    if btnp(4) and player.y == 54 then
        state = "play"
        level = 1
        begin_play()
    elseif btnp(4) and player.y == 74 then
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
    local sdisplay, stimer, splayer, scats, sspd, sbowls, sfridges, fscoremin
    if level == 0 then
        sdisplay = {cx = 0, cy = 48, width = 16, height = 16}
        splayer = {x = 28, y = 54, dir = 1, spd = 2}
        scats = {{x = 64, y = 110}}
        sbowls = {}
        sresources = {}
    end

    if level == 1 then
        sdisplay = {cx = 0, cy = 0, width = 16, height = 16}
        stimer = {min = 1, sec = 5}
        splayer = {x = 64, y = 64, dir = 1, spd = 2}
        scats = { {x = 26, y = 60},
                  {x = 92, y = 40},
                  {x = 86, y = 86},
                  {x = 40, y = 80},
                  {x = 36, y = 98},
                  {x = 100, y = 106} }
        sspd = 1
        sbowls = { { cx = 1.5, cy = 2.5, color = 0 },
                   { cx = 3.5, cy = 9.5, color = 1 },
                   { cx = 13.5, cy = 12.5, color = 2 },
                   { cx = 6.5, cy = 12.5, color = 3 } }
        fscoremin = 100
        -- fish in fridge #0, meat in fridge #1, cookie in cupboard #3
        sresources = { fish = {0}, meat = {1}, cookie = {3} }
    end

    if level == 2 then
        sdisplay = {cx = 16, cy = 0, width = 12, height = 12}
        stimer = {min = 1, sec = 30}
        splayer = {x = 22*8, y = 5.2*8, dir = 1, spd = 2}
        scats = { {x = 19*8, y = 4*8, color = 1, dir = 1, want = 0},
                  {x = 20*8, y = 9*8, color = 2, dir = 1, want = 1} }
        sspd = 1
        sbowls = { {cx = 23.5, cy = 5.5, color = 0},
                   {cx = 26, cy = 9, color = 1} }

        fscoremin = 100
        sresources = { fish = {0}, meat = {1} }
    end

    return {display = sdisplay, timer = stimer, player = splayer, cats = scats, spd = sspd, bowls = sbowls, scoremin = fscoremin, resources = sresources}
end

function contains(table, value)
    if table then for _,v in pairs(table) do if v == value then return true end end end return false
end

function begin_play()
    desc = make_level(level)
    display = {cx = desc.display.cx, cy = desc.display.cy, width = desc.display.width, height = desc.display.height}
    timer = {min = desc.timer.min, sec = desc.timer.sec}
    player = {x = desc.player.x, y = desc.player.y, dir = desc.player.dir, spd = desc.player.spd, bob = 0, walk = 0.2}
    
    cats = {}
    spd = desc.spd

    bowls = {}
    for i = 1, #desc.bowls do
        add(bowls, {cx = desc.bowls[i].cx, cy = desc.bowls[i].cy, color = desc.bowls[i].color})
    end
    score = 110
    scoremin = desc.scoremin
    compute_resources()
    compute_paths()
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

function compute_resources()
    -- find all fridges and sinks in the map and fill the resources table
    resources = {}
    local nfridges, ncupboards = 0, 0
    for j=desc.display.cy,desc.display.cy+desc.display.height do
        for i=desc.display.cx,desc.display.cx+desc.display.width do
            local tile = mget(i,j)
            if tile == 50 then -- this is a fridge
                if contains(desc.resources.meat, nfridges) then
                    add(resources, {x = i * 8 + 9, y = j * 8 - 3, xcol = i * 8 + 8, ycol = j * 8, color = 0})
                elseif contains(desc.resources.fish, nfridges) then
                    add(resources, {x = i * 8 + 9, y = j * 8 - 3, xcol = i * 8 + 8, ycol = j * 8, color = 1})
                end
                nfridges += 1
            elseif tile == 26 then -- this is a sink
                add(resources, {x = i * 8 + 9, y = j * 8 + 1, xcol = i * 8 + 8, ycol = j * 8 + 8, color = 2})
            elseif (tile == 36 or tile == 39) then -- this is a cupboard
                if contains(desc.resources.cookie, ncupboards) then
                    add(resources, {x = i * 8 + 8, y = j * 8 - 6, xcol = i * 8 + 8, ycol = j * 8, color = 3})
                end
                ncupboards += 1
            end
        end
    end
end

function compute_paths()
    paths = {}
    for i = 1, #bowls do
        local grid = {}
        local dist, bcell = 0, flr(desc.bowls[i].cx) + 128 * flr(desc.bowls[i].cy)
        local tovisit, visited = {bcell, bcell+1, bcell+128, bcell+129}, {}
        while #tovisit > 0 do
            -- store distance for all cells to visit
            for j = 1, #tovisit do
                grid[tovisit[j]] = dist
                visited[tovisit[j]] = true
            end
            -- find new cells to visit
            local nxt = {}
            for j = 1, #tovisit do
                local cell = tovisit[j]
                local x, y = cell % 128 * 8, flr(cell / 128) * 8
                if not visited[cell - 128] and not wall(x, y - 8) then nxt[cell - 128] = true end
                if not visited[cell + 128] and not wall(x, y + 8) then nxt[cell + 128] = true end
                if not visited[cell - 1] and not wall(x - 8, y) then nxt[cell - 1] = true end
                if not visited[cell + 1] and not wall(x + 8, y) then nxt[cell + 1] = true end
            end
            tovisit = {}
            for k, _ in pairs(nxt) do add(tovisit, k) end
            dist += 1
        end
        paths[i] = grid
    end
end

function dir_x(dir)
    if dir == 0 then
        return true
    else return false
    end
end

--
-- pause state handling
--

function pause_menu()
    menuitem(2, "menu", function() state = "menu" begin_menu() end)
end

function begin_pause()
    des = make_level(0)
    player = {x = des.player.x, y = des.player.y, dir = des.player.dir, spd = des.player.spd, bob = 0, walk = 0.2}
end

function update_pause()
    if score >= scoremin then
        if btnp(4) then
            level += 1
            state = "play"
            begin_play()
        end
    elseif btnp(4) then
        level = 0
        state = "menu"
        begin_menu()
    end 
    player.bob += 0.08
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
        if (player.x != x) walk = true player.dir = (player.x > x) and 0 or 1
        player.x = x
    end

    local y = player.y
    if btn(2) then
        y -= player.spd
        player.dir = 2
    elseif btn(3) then
        y += player.spd
        player.dir = 1
    end

    if not wall_area(player.x, y, 3, 3) and not has_cat_nearby(player.x, y) then
        if (player.y != y) walk = true
        player.y = y
    end

    if (walk) player.walk += 0.25
    player.bob += 0.08

    -- did the user throw something away?
    if btnp(5) and player.carry then
        player.throw = {color=player.carry, x=player.x, y=player.y-11, dir=dir_x(player.dir)}
        player.carry = nil
    end

    -- disable charging (will be reactivated in the next step)
    if player.charge then
        player.charge.active = false
    end

    -- if charging, update the progress
    if btn(4) and not player.carry then
        for i=1,#resources do
            local dx = player.x - resources[i].xcol
            local dy = player.y - resources[i].ycol
            if dx * dx + dy * dy / 9 < 6 * 6 then
                if not player.charge or player.charge.id != i then
                    player.charge = {id=i, active=true, progress=0}
                else
                    player.charge.active = true
                    player.charge.progress += 0.015
                    if player.charge.progress > 1 then
                        player.carry = resources[i].color
                        player.charge = nil
                    end
                end
                break
            end
        end
    end

    -- if we threw something, update its coordinates
    if player.throw then
        local dx = player.throw.dir and -5 or 5
        player.throw.x += dx
        player.throw.y += 1
        if player.throw.x < -10 or player.throw.x > 128 * 8 + 10 then
            player.throw = false
        end
    end
end

--
-- cats
--

function add_cat()
    -- spawn a cat at a random location found in desc.cats
    local startid = 1 + flr(rnd(#desc.cats))
    local catdesc = desc.cats[startid]
    local cat = {x = catdesc.x, y = catdesc.y, color = flr(1 + rnd(3)), dir = rnd() > 0.5}
    cat.want = flr(rnd(3))
    add(cats, cat)
end

function update_cats() 
    for i = 1,#cats do
        local cat = cats[i]
        if cat.plan then
            -- if the cat has a plan, make it move in that direction
            local x = cat.x
            if cat.plan.dir == 0 then
                cat.dir = 0
                x -= spd
            elseif cat.plan.dir == 1 then
                cat.dir = 1
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
                        cat.plan.bowl, cat.plan.x, cat.plan.y = i, bowls[i].cx * 8 + 4, bowls[i].cy * 8 + 4
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
    csprint("ldjam42", 25, 12, 14)
    cprint("play", 50, 7)
    cprint("choose level", 70, 7)
end

function draw_world()
    palt(0, false)
    map(display.cx, display.cy, display.cx*8, display.cy*8, display.height, display.width)
    palt(0, true)
    foreach(bowls, function(b)
        spr(66 + b.color, b.cx * 8, b.cy * 8)
    end)
    foreach(resources, function(r)
        spr(82 + r.color, r.x - 4, r.y - 4)
    end)
end

function draw_grandma()
    palt(11, true)
    palt(0, false)
    local sw, cw = sin(player.walk / 4), cos(player.walk / 4)
    if (not player.carry) spr(100, player.x - 4 - 3 * sw, player.y - 6 + 2 * abs(cw))
    spr(116, player.x - 4 - 3 * cw, player.y - 3 + 1.5 * abs(sw))
    spr(98 + 16 * flr(player.walk % 2), player.x - 8, player.y - 4, 2, 1, dir_x(player.dir))
    spr(116, player.x - 4 + 3 * cw, player.y - 3 + 1.5 * abs(sw))
    if (not player.carry) spr(100, player.x - 4 + 3 * sw, player.y - 6 + 2 * abs(cw))
    if player.carry then
        spr(100, player.x - 8, player.y - 9 - 2 * abs(cw), 1, 1, false, true)
        spr(100, player.x + 0, player.y - 11 + 2 * abs(cw), 1, 1, false, true)
    end
    if player.dir <= 1 then
        spr(96, player.x - 8, player.y - 12 + sin(player.bob), 2, 2, dir_x(player.dir))
    elseif player.dir == 2 then
        pal(14,6)
        pal(15,7)
        pal(5,7)
        pal(0,7)
        spr(96, player.x - 8, player.y - 12 + sin(player.bob), 2, 2, dir_x(player.dir))
        pal()
    end
    palt()
    -- display the carry
    if player.carry then
        spr(82 + player.carry, player.x - 4, player.y - 15 + sw, 1, 1, dir_x(player.dir))
    end
    -- display the throw
    if player.throw then
        spr(82 + player.throw.color, player.throw.x - 4, player.throw.y - 4, 1, 1, dir_x(player.dir))
    end
    -- display the charge widget
    if player.charge and player.charge.active then
        local t, col = player.charge.progress, 6 + rnd(2)
        local dx, dy = player.x - 8, player.y - 24
        for i=1,7 do if (i>t*28) palt(i, true) palt(i+7, true) else pal(i,0) pal(i+7,col) end
        spr(70, dx + 8, dy, 1, 1)
        for i=1,7 do if (i<14-t*28) palt(i, true) palt(i+7, true) else pal(i,0) pal(i+7,col) end
        spr(70, dx + 8, dy + 8, 1, 1, false, true)
        for i=1,7 do if (i>t*28-14) palt(i, true) palt(i+7, true) else pal(i,0) pal(i+7,col) end
        spr(70, dx, dy + 8, 1, 1, true, true)
        for i=1,7 do if (i<28-t*28) palt(i, true) palt(i+7, true) else pal(i,0) pal(i+7,col) end
        spr(70, dx, dy, 1, 1, true)
    end
    pal()
end

function draw_pause()
    csprint("time out", 25, 9, 14)
    if score >= scoremin then
        cprint("next level", 50, 7)
    else
        cprint("menu", 50, 7)
    end
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
        spr(72, cat.x - 8, cat.y - 12, 2, 2, dir_x(cat.dir))

        -- if the cat wants something, draw a bubble
        if cat.want then
            local x, y = cat.x - 8, cat.y - 22
            spr(64, x, y, 2, 2, cat.dir)
            palt(11, false)
            palt(0, true)
            spr(82 + cat.want, x + 4, y + 1, 1, 1, dir_x(cat.dir))
        end

        -- debug: if the cat has a plan, draw a line
        if cat.plan and cat.plan.bowl then
            local col = 12 + cat.plan.bowl
            local d = paths[cat.plan.bowl]
            local cell = flr(cat.x / 8) + 128 * flr(cat.y / 8)
            while cell and d[cell] and d[cell] > 0 do
                local nextcell = nil
                if ((d[cell + 1] or 1000) < d[cell]) nextcell = cell + 1
                if ((d[cell - 1] or 1000) < d[cell]) nextcell = cell - 1
                if ((d[cell + 128] or 1000) < d[cell]) nextcell = cell + 128
                if ((d[cell - 128] or 1000) < d[cell]) nextcell = cell - 128
                if (nextcell) line(cell % 128 * 8 + 4, flr(cell / 128) * 8 + 4, nextcell % 128 * 8 + 4, flr(nextcell / 128) * 8 + 4, col)
                cell = nextcell
            end
            --line(cat.x, cat.y, cat.plan.x, cat.plan.y, rnd(15))
        end
    end)
    pal()
end

function draw_ui()
    cosprint(tostr(timer.min)..":"..ctostr(flr(timer.sec), 2), 96, 116, 9, colortimer)
    cosprint(tostr(score), 9, 116, 9, 14)
end

function display_camera()
   if display.width > 16 then
        camera(player.x - 64, (display.cy - (16 - display.height)/2)*8)
    elseif display.height > 16 then
        camera((display.cx - (16 - display.width)/2)*8, player.y -64)
    else
        camera((display.cx - (16 - display.width)/2)*8, (display.cy - (16 - display.height)/2)*8)
    end
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
    display_camera()
    draw_world()
    draw_cats()
    draw_grandma()
    camera()
    draw_ui()
end

config.pause.draw = function ()
    draw_background()
    display_camera()
    draw_world()
    draw_cats()
    camera()
    draw_ui()
    draw_pause()
    draw_grandma() 
end

__gfx__
00000000f9999999999999947777777677776766fffffffffffffff49999999999999999ffffffff777777760000000033333333333333333333333333333333
00000000f9999999999999947777777677767676ff9f9f9f9994949499999999999999999f9f9f9f777777760000000033333333333333333333333330003333
00700700f9999999999999947777777677776766f9f9f999999949449999999999999999f9f9f9f9767dd6760000000033333333333333333333333301503333
00077000f9999999999999947777777677767676ff99999999999994999999999999999999999999777767760000000033333000003333333333333011500333
00077000f9999999999999947777777677776766f9f9999999999994999999999999999999999999777777760000000033330555503333333333300001110333
00700700f9999999999999947777777677767676f999999999999994494949499999999999999999777677760000000033305555503333333330055550000333
00000000f9999999999999947777776677776766f999999999999994949494949999999999999999777777660000000033005550003333333305555555550333
00000000f9999999999999946666666f6666666df9999999999999944444444499999999999999996666666f0000000033055003333000003055555550055033
0000000000000000955555505505000991111111111111101101000911111111111111101101000091111111110100093055503333301111055555550e005033
00000000000000005567777777777600112888888888888888888200112444444444444444444200112666666666620030555033333066611550055500705033
0000000000000000567777777777776012888888888888888888882012444444444444444444442012666666666666203055503333330666550e005550055003
0000000000000000567777777777776012888888888888888888882012444444444444444444442012666dddddd6662030555033333306655500705556600033
000000000000000056777777777777601288888888888888888888201244444444444444444444201266d555555d662030555003333300555550055666666033
00000000000000005677777777777760128888888888888888888820124444444444444444444420126d51111115d62033055550033333055555566600660003
00000000000000005566666666666600112222222222222222222200112222222222222222222200112222222222220033005555500000005555666606660333
00000000000000005655555055050060121111111111111011010020121111111111111011010020121111111101002033300555555555550506666666660333
00000000000000005667777777777660122888812888888128888220122444412444444124444220000000000000000033333005555555555056066666603333
00000000000000005677777777777760128888812888888128888820124444412444444124444420000000000000000033333055555555550500666666033333
00000000000000005677777777777760121f888121f8888121f88820121d444121d4444121d44420000000000000000033330055555555555505000000333333
00000000000000005600777777777760128888812888888128888820124444412444444124444420000000000000000033330555555555555555555550333333
00000000000000005666777777777760128888812888888128888820124444412444444124444420000000000000000033330555555555555555555550033333
00000000000000005677777777777760128888812888888128888820124444412444444124444420000000000000000033330555555555555505505555003333
00000000000000005677777777777760128888812888888128888800124444412444444124444400000000000000000033333055555000005550000555503333
00000000000000005677777777777760511111111111111011010005511111111111111011010005000000000000000033330055500503305555030556603333
00000000000000005777777777777760122444444444444444444220122767666767676667676220000000000000000033305555055503305555003066603333
00000000000000005777777777777760124444444444444444444420127676767676767676767620000000000000000033065555055033330555603306603333
00000000000000005777777777777760124444444444444444444420126767666767676667676720000000000000000033066600300333330066603330033333
00000000000000005777777777777760124444444444444444444420127777767777777677767620000000000000000033066033333333333066603333333333
00000000000000005777777777777760124444444444444444444420127777767777777677776720000000000000000033300333333333333300033333333333
00000000000000005777777777777760124444444444444444444420127777767777777677767620000000000000000033333333333333333333333333333333
00000000000000005566666666666600124444444444444444444400127777667777777677776720000000000000000033333333333333333333333333333333
000000000000000065555550550500065111111111111110110100056666666f6666666f66666665000000000000000033333333333333333333333333333333
bbbbb50005bbbbbb000000000000000000000000000000000000000000000000bbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000
bbb006676600bbbb000000000000000000000000000000000000000000000000bbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000
bb06777777760bbb080000800300003001000010040000401230000000000000bbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000
b5677777777765bb8ee88ef83bb33ba31cc11c61499449a489a3400000000000bbbbbbbbbbb0bb0b000000000000000000000000000000000000000000000000
b0677777777760bb8effffe83baaaab31c6666c149aaaa9489abb50000000000bbbbbbbbbb09b090000000000000000000000000000000000000000000000000
b0777777777770bb088888860333333601111116044444468abbcc5000000000bbbbbbbbb0490490000000000000000000000000000000000000000000000000
b0677777777760bb606060606060606060606060606060609accddd600000000bbbbbbbbb0919190000000000000000000000000000000000000000000000000
b5677777777765bb06060606060606060606060606060606cddeeee700000000bbbb000000909090000000000000000000000000000000000000000000000000
bb06777777760bbbf880000000000000000c0000004444000000000000000000bbb0444949999990000000000000000000000000000000000000000000000000
bbb506777605bbbbf8888000a000bb00000c0000049797400000000000000000bb0949494999900b000000000000000000000000000000000000000000000000
bbbbb05770bbbbbbf8888800ba0b33b000cc100047aaaa740000000000000000bb04949999990bbb000000000000000000000000000000000000000000000000
bbbbbb0570bbbbbb0f888e800bb3373b0c7cd100494a4a940000000000000000bb0909909090bbbb000000000000000000000000000000000000000000000000
bbbbbbb070bbbbbb0f88817803333333c7cccd1049aaaa740000000000000000bb0909009040bbbb000000000000000000000000000000000000000000000000
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
0001010000010101010100000000000000000101010101010101010100000000000001010101010101010000000000000000010101010101000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0608080808080808081416121308080506080808080808080812130100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02070712131a1b14152426222314160102070707070707070722230100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203042223343535353536323324260102030303030303030432330100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02030422230a03030303030a030304010203030317181819030a040100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203043233030303030303030303040102030303373838390303040100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02030303030303030a0303030303040102121303030303030303040100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020a030317181903030317190303040702222314151603030303040111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020303033738390a03033739030a030402323324252617181903040111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203030303030303030303030303030402030a03030337383903040100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203030a03041416050603030303040502030303030303030303040100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02030303030424260102030a0303040108090909090903040509090800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02171819030a0304010203030303040100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0227293903030304010203030303040100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203030303030304010203030a03040100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0809090909090909080809090909090800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0808080808080808080808080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
