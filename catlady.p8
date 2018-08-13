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
    flevel = 2
    levelsaved = dget(1)
    begin_menu()
    pause_menu()
end

function _update()
    if (state == "menu") then
        update_menu()
    elseif (state == "play") then
        update_play()
        if level >= 0 then
            update_time()
        end
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
    if t.min == 0 and (t.sec % 1 >= 29/30) then
        if t.sec < 1 then
            -- TODO SFX: timeout sound!
        elseif t.sec < 11 then
            -- TODO SFX: stressful clock sounds!
        end
    end

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
    music(0)
    grandmapos = 1
    level = 0
    selectlevel = 1
    desc = make_level(level)
    chooselevel = false
    player = {x = desc.start_x, y = desc.start_y, dir = 1, spd = desc.speed, bob = 0, walk = 0.2}
    cats = {}
end

function update_menu()
    update_cats()
    if btnp(3) then
        if grandmapos == 1 then
            player.y = 74
            grandmapos = 2
        elseif grandmapos == 2 then
            player.y = 99
            grandmapos = 3
            chooselevel = false
        end
        sfx(5)
    elseif btnp(2) then
        if grandmapos == 2 then
            player.y = 54
            grandmapos = 1
            chooselevel = false
        elseif grandmapos == 3 then
            player.y = 74
            grandmapos = 2
            chooselevel = true
        end
        sfx(5)
    end

    if btnp(4) and grandmapos == 1 then
        level = 1
        state = "play"
        begin_play()
        sfx(5)
    elseif grandmapos == 2 then
        chooselevel = true
        if selectlevel < levelsaved and btnp(1) then
            selectlevel += 1
            sfx(5)
        end
        if selectlevel > 1 and btnp(0) then
            selectlevel -= 1
            sfx(5)
        end
        if btnp(4) then
            level = selectlevel
            state = "play"
            begin_play()
            sfx(5)
        end
    elseif btnp(4) and grandmapos == 3 then
        level = -1
        state = "play"
        begin_play()
        sfx(5)
    end
    player.bob += 0.08
end

--
-- play state handling
--

function make_level(level)
     if level == -1 then
        return { cx = 0, cy = 16, width = 16, height = 16,
                 start_x = 64, start_y = 64, speed = 2, timer = 100000,
                 cats = {{x = 64, y = 110}},
                 resources = { fish = {1}, meat = {0}, cookie = {3} } }
    end
    
    if level == 0 then
        return { cx = 0, cy = 48, width = 16, height = 16,
                 start_x = 28, start_y = 54, speed = 2,
                 cats = {{x = 64, y = 110}},
                 resources = {} }
    end

    if level == 1 then
        return { cx = 0, cy = 0, width = 16, height = 16,
                 start_x = 64, start_y = 64, speed = 2, cat_speed = 1,
                 timer = 65, fscoremin = 100,
                 cats = { {x = 26, y = 60},
                          {x = 92, y = 40},
                          {x = 86, y = 86},
                          {x = 40, y = 80},
                          {x = 36, y = 98},
                          {x = 100, y = 106} },
                 -- fish in fridge #0, meat in fridge #1, cookie in cupboard #3
                 resources = { fish = {0}, meat = {1}, cookie = {3} } }
    end

    if level == 2 then
        return { cx = 16, cy = 0, width = 12, height = 12,
                 start_x = 22*8, start_y = 5.2*8, speed = 2, cat_speed = 1,
                 timer = 90, fscoremin = 100,
                 cats = { {x = 19*8, y = 4*8, color = 1, dir = 1, want = 0},
                          {x = 20*8, y = 9*8, color = 2, dir = 1, want = 1} },
                 resources = { fish = {0}, meat = {1} } }
    end
end

function contains(table, value)
    if table then for _,v in pairs(table) do if v == value then return true end end end return false
end

function begin_play()
    desc = make_level(level)
    timer = {min = flr(desc.timer / 60), sec = desc.timer % 60}
    player = {x = desc.start_x, y = desc.start_y, dir = 1, spd = desc.speed, bob = 0, walk = 0.2}
    cats = {}

    score = 110
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
    -- find all bowls and fridges and sinks in the map and fill the resources table
    bowls, resources = {}, {}
    local nfridges, ncupboards = 0, 0
    for j=desc.cy,desc.cy+desc.height do
        for i=desc.cx,desc.cx+desc.width do
            local tile = mget(i,j)
            if tile == 11 then -- this is a bowl
                add(bowls, { cx=i+0.5, cy=j+0.5, color=4 })
            elseif tile == 50 then -- this is a fridge
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
                    -- add two resources with different collisions because i can't make it work well :-(
                    add(resources, {x = i * 8 + 8, y = j * 8 - 6, xcol = i * 8 + 8, ycol = j * 8 - 8, color = 3})
                    add(resources, {x = i * 8 + 8, y = j * 8 - 6, xcol = i * 8 + 8, ycol = j * 8, color = 3})
                end
                ncupboards += 1
            end
        end
    end
end

function compute_paths()
    -- find all bowls in the map and compute the shortest path to them
    paths = {}
    for i = 1, #bowls do
        local grid = {}
        local dist, bcell = 0, flr(bowls[i].cx) + 128 * flr(bowls[i].cy)
        local tovisit, visited = {bcell, bcell+1, bcell+128, bcell+129}, {}
        while #tovisit > 0 do
            -- store distance for all cells of the current depth
            for j = 1, #tovisit do
                grid[tovisit[j]] = dist
                visited[tovisit[j]] = true
            end
            -- mark new cells to visit
            local nxt = {}
            for j = 1, #tovisit do
                local cell = tovisit[j]
                local x, y = cell % 128 * 8, flr(cell / 128) * 8
                if y > desc.cy and not visited[cell - 128] and not wall(x, y - 8) then nxt[cell - 128] = true end
                if y < desc.cy + desc.height - 1 and not visited[cell + 128] and not wall(x, y + 8) then nxt[cell + 128] = true end
                if x > desc.cx and not visited[cell - 1] and not wall(x - 8, y) then nxt[cell - 1] = true end
                if x < desc.cx + desc.width - 1 and not visited[cell + 1] and not wall(x + 8, y) then nxt[cell + 1] = true end
            end
            -- compute new list of cells to visit
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
    local des = make_level(0)
    player = {x = des.start_x, y = des.start_y, dir = 1, spd = des.speed, bob = 0, walk = 0.2}
end

function update_pause()
    if score >= desc.fscoremin then
        if btnp(4) then
            if level == flevel then
                state = "menu"
                begin_menu()
            else
                level += 1
                state = "play"
                begin_play()
            end
            if levelsaved < level then
                levelsaved = level
                dset(1,levelsaved)
            end
            sfx(5)
        end
    elseif btnp(4) then
        level = 0
        state = "menu"
        begin_menu()
        sfx(5)
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
        player.dir = 0
        x -= player.spd
    elseif btn(1) then
        player.dir = 1
        x += player.spd
    end

    if not wall_area(x, player.y, 3, 3) and not has_cat_nearby(x, player.y) then
        if (player.x != x) walk = true
        player.x = x
    end

    local y = player.y
    if btn(2) then
        player.dir = 2
        y -= player.spd
    elseif btn(3) then
        player.dir = 3
        y += player.spd
    end

    if not wall_area(player.x, y, 3, 3) and not has_cat_nearby(player.x, y) then
        if (player.y != y) walk = true
        player.y = y
    end

    if (walk) then
        player.walk += 0.25
        if player.walk % 1 < 0.25 then
            -- TODO SFX: walking sounds
        end
    end
    player.bob += 0.08

    -- point of view (depends on the facing direction)
    local povx, povy = player.x, player.y
    if (player.dir == 0) then povx -= 6 elseif (player.dir == 1) then povx += 6 end
    if (player.dir == 2) then povy -= 10 elseif (player.dir == 3) then povy += 2 end

    -- did the user throw something away?
    if btnp(5) and player.carry then
        sfx(6)
        player.throw = {color=player.carry, x=player.x, y=player.y-11, dir=dir_x(player.dir)}
        player.carry = nil
    end

    -- disable charging (will be reactivated in the next step)
    if player.charge then
        player.charge.active = false
    end

    -- if putting something in a bowl...
    if btnp(4) and player.carry then
        for i=1,#bowls do
            local dx = povx - (bowls[i].cx * 8 + 4)
            local dy = povy - (bowls[i].cy * 8 + 4)
            if dx / 128 * dx + dy / 128 * dy < 8 * 8 / 128 then
                sfx(7)
                bowls[i].color = player.carry
                player.carry = nil
                break
            end
        end
    end

    -- if charging or trying to charge, update the progress
    if btn(4) and not player.carry then
        for i=1,#resources do
            local dx = povx - resources[i].xcol
            local dy = povy - resources[i].ycol
            if dx / 128 * dx + dy / 128 * dy < 6 * 6 / 128 then
                if not player.charge or player.charge.id != i then
                    player.charge = {id=i, active=true, progress=0}
                else
                    if player.charge.progress % 0.08 < 0.015 then
                        sfx(8)
                    end
                    player.charge.active = true
                    player.charge.progress += 0.015
                    if player.charge.progress > 1 then
                        sfx(9)
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
            player.throw = nil
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
                x -= desc.cat_speed
            elseif cat.plan.dir == 1 then
                cat.dir = 1
                x += desc.cat_speed
            end

            if not wall_area(x, cat.y, 3, 3) and max(abs(x - player.x), abs(cat.y - player.y)) > 8 then
                cat.x = x
            end

            local y = cat.y
            if cat.plan.dir == 2 then
                y -= desc.cat_speed
            elseif cat.plan.dir == 3 then
                y += desc.cat_speed
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
    cosprint("cat", 16, 10, 20, 14)
    cosprint("lady", 62, 10, 20, 14)
    cosprint("simulator", 42, 30, 12, 12)
    cprint("play", 50, 7)
    cprint("choose level", 70, 7)
    cprint("help", 95, 7)
end

function draw_chooselevel()
    if chooselevel then
        for i = 1, levelsaved do
            cosprint(tostr(i), 64 - (levelsaved - 1)*10 + (i - 1)*20, 80, 6, 7)
        end
        if levelsaved > 0 then
            rect(64 - (levelsaved - 1)*10 + (selectlevel - 1)*20 - 3, 80-3, 64 - (levelsaved - 1)*10 + (selectlevel - 1)*20 + 5, 80+7, 14)
        end
    end
end

function draw_world()
    palt(0, false)
    map(desc.cx, desc.cy, desc.cx*8, desc.cy*8, desc.height, desc.width)
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
    if player.dir != 2 then
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
        spr(71, dx + 8, dy, 1, 1)
        for i=1,7 do if (i<14-t*28) palt(i, true) palt(i+7, true) else pal(i,0) pal(i+7,col) end
        spr(71, dx + 8, dy + 8, 1, 1, false, true)
        for i=1,7 do if (i>t*28-14) palt(i, true) palt(i+7, true) else pal(i,0) pal(i+7,col) end
        spr(71, dx, dy + 8, 1, 1, true, true)
        for i=1,7 do if (i<28-t*28) palt(i, true) palt(i+7, true) else pal(i,0) pal(i+7,col) end
        spr(71, dx, dy, 1, 1, true)
    end
    pal()
end

function draw_pause()
    csprint("time out", 25, 9, 14)
    if score >= desc.fscoremin then
        if level == flevel then
            cprint("you win", 50, 7)
        else cprint("next level", 50, 7)
        end
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
    if level >=0 then
        cosprint(tostr(timer.min)..":"..ctostr(flr(timer.sec), 2), 96, 116, 9, colortimer)
        cosprint(tostr(score), 9, 116, 9, 14)
    elseif level == -1 then
        cosprint("meat", 26, 4, 6, 7)
        cosprint("fish", 82, 4, 6, 7)
        cosprint("water", 12*8, 22, 6, 7)
        cosprint("cookie", 30, 62, 6, 7)
        csprint("feed the cats by", 110, 6, 7)
        csprint("filling the bowls", 118, 6, 7)
    end
end

function display_camera()
   if desc.width > 16 then
        camera(player.x - 64, (desc.cy - (16 - desc.height)/2)*8)
    elseif desc.height > 16 then
        camera((desc.cx - (16 - desc.width)/2)*8, player.y -64)
    else
        camera((desc.cx - (16 - desc.width)/2)*8, (desc.cy - (16 - desc.height)/2)*8)
    end
end

config.menu.draw = function ()
    camera(0, 48*8)
    draw_world()
    draw_cats()
    camera()
    draw_menu()
    draw_grandma() 
    draw_chooselevel()
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
00000000f9999999999999947777777677776766fffffffffffffff49999999999999999ffffffff777777767777777633333333333333333333333333333333
00000000f9999999999999947777777677767676ff9f9f9f9994949499999999999999999f9f9f9f777777767777777633333333333333333333333330003333
00700700f9999999999999947777777677776766f9f9f999999949449999999999999999f9f9f9f9767dd6767777777633333333333333333333333301503333
00077000f9999999999999947777777677767676ff99999999999994999999999999999999999999777767767777777633333000003333333333333011500333
00077000f9999999999999947777777677776766f9f9999999999994999999999999999999999999777777767777777633330555503333333333300001110333
00700700f9999999999999947777777677767676f999999999999994494949499999999999999999777677767777777633305555503333333330055550000333
00000000f9999999999999947777776677776766f999999999999994949494949999999999999999777777667777778833005550003333333305555555550333
00000000f9999999999999946666666f6666666df9999999999999944444444499999999999999996666666f6666668833055003333000003055555550055033
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
bb06777777760bbb088888800333333001111110044444400555555012300000bbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000
b5677777777765bb8ee88ef83bb33ba31cc11c61499449a45dd55d6589a34000bbbbbbbbbbb0bb0b000000000000000000000000000000000000000000000000
b0677777777760bb8effffe83baaaab31c6666c149aaaa945d6666d589abb500bbbbbbbbbb09b090000000000000000000000000000000000000000000000000
b0777777777770bb08888886033333360111111604444446055555568abbcc50bbbbbbbbb0490490000000000000000000000000000000000000000000000000
b0677777777760bb60606060606060606060606060606060606060609accddd6bbbbbbbbb0919190000000000000000000000000000000000000000000000000
b5677777777765bb0606060606060606060606060606060606060606cddeeee7bbbb000000909090000000000000000000000000000000000000000000000000
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
020b0422233435353535363233242601020b0303030303030432330100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02030422230a03030303030b030304010203030317181819030a040100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203043233030303030303030303040102030303373838390303040100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02030303030303030a030303030304010212130303030b030303040100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020a030317181903030317190303040702222314151603030303040111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020303033738390a03033739030a030402323324252617181903040111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203030303030303030303030303030402030a03030337383903040100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203030a03041416050603030303040502030303030303030303040100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02030303030424260102030a0303040108090909090903040509090800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02171819030a0304010203030303040100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0227293903030b0401020b030303040100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203030303030304010203030a03040100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0809090909090909080809090909090800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0808080808080808080808080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0612130808080808121308080808080500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0222230707070707222307070707070100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
023233030b030303323303030303040100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203030303030303030303030303040100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203030303030303031718191a1b190100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203030303030303032728292728290100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203030303030303030303030303040100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020b030303030303030303030303040100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020303030303030303030303030b040100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0214151614160303030303030303040100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0224252624260303030317181819040100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203030303030303030337383839040100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020b030303030303030303030303040100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203030303030303030303030303040100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0809090909090909090909090909090800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0808080808080808080808080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
011e000000000000000000000000000000000000000000000000000000000000000000000000002d0252d0252c0152c0152d0252d0252c0152c0152d0252d02528015280152d0252d02526014260112601126015
011e001112745127450d7450d7451e7441e7411e7411e7450e7450e745157451574510744107411074110741107450c2000c2000c2000c2000c00000000000000000000000000000000000000000000000000000
011e0000107441074512745127450d7450d7451274512745127450e7450e74515745157451c7441c7411c74500000000000000000000000000000000000000000000000000000000000000000000000000000000
011e000021015250152d0252d025080152d025210152c0152d0152d01521015280152d0152d015210152101528005280052d0052d005260042600126001260050000000000000000000000000000000000000000
000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001401016020180201a0201b0201e0202102025020290202c0102e010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200002b554255511d55117551135410e5310952500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000027514295212b5312e5312b531295312753124531225311f5311d5311b5211851500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300001503418031075010750107501075010750107501075010750500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0004000027050220501d0501b0501d050220502905030050370500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 01004044
02 04020344

