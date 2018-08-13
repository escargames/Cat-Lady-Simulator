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
-- some constants
--
g_player_cat_dist = 6
g_player_res_dist = 6
g_cat_bowl_dist = 6

g_sfx_eaten = 9
g_sfx_acquiring = 8
g_sfx_acquired = 13

--
-- standard pico-8 workflow
--

function _init()
    cartdata("cat_lady_simulator")
    state = "menu"
    flevel = 2
    levelsaved = dget(0)
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
            sfx(12)
        elseif t.sec < 11 then
            sfx(11)
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
    while #a < l do
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
            player.y = 94
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
        if btnp(4) and levelsaved != 0 then
            level = selectlevel
            state = "play"
            begin_play()
            sfx(5)
        end

    elseif btnp(4) and grandmapos == 3 then
        level = -1
        state = "play"
        begin_play()
        player.carry = 1
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
                 start_x = 64, start_y = 24*8, speed = 2, cat_speed = 1, timer = 100000,
                 cats = {{x = 64, y = 23*8}},
                 resources = { fish = {1}, meat = {0}, cookie = {3} } }
    end
    
    if level == 0 then
        return { cx = 0, cy = 48, width = 16, height = 16,
                 start_x = 28, start_y = 54, speed = 2,
                 cats = {{x = 64, y = 110}},
                 resources = {} }
    end

    if level == 1 then
        return { cx = 28, cy = 0, width = 10, height = 10,
                 start_x = 33*8, start_y = 9*8, speed = 2, cat_speed = 1,
                 timer = 90, fscoremin = 100,
                 cats = { {x = 30*8, y = 4*8, color = 1, dir = 1, want = 0},
                          {x = 34*8, y = 8*8, color = 2, dir = 1, want = 1} },
                 resources = { fish = {0} } }
    end

    if level == 2 then
        return { cx = 16, cy = 0, width = 12, height = 12,
                 start_x = 22*8, start_y = 5.2*8, speed = 2, cat_speed = 1,
                 timer = 90, fscoremin = 100,
                 cats = { {x = 19*8, y = 4*8, color = 1, dir = 1, want = 0},
                          {x = 20*8, y = 9*8, color = 2, dir = 1, want = 1} },
                 resources = { fish = {0}, meat = {1} } }
    end

    if level == 3 then
        return { cx = 0, cy = 0, width = 16, height = 16,
                 start_x = 64, start_y = 64, speed = 2, cat_speed = 1,
                 timer = 90, fscoremin = 100,
                 cats = { {x = 26, y = 60},
                          {x = 92, y = 40},
                          {x = 86, y = 86},
                          {x = 40, y = 80},
                          {x = 36, y = 98},
                          {x = 100, y = 106} },
                 -- fish in fridge #0, meat in fridge #1, cookie in cupboard #3
                 resources = { fish = {0}, meat = {1}, cookie = {3} } }
    end
end

function contains(table, value)
    if table then for _,v in pairs(table) do if v == value then return true end end end return false
end

-- check that dx*dx + dy*dy < r*r
function test_radius(dx, dy, r)
    return dx / 256 * dx + dy / 256 * dy - r / 256 * r
end

function begin_play()
    desc = make_level(level)
    timer = {min = flr(desc.timer / 60), sec = desc.timer % 60}
    player = {x = desc.start_x, y = desc.start_y, dir = 1, spd = desc.speed, bob = 0, walk = 0.2}
    cats = {}

    score = 0
    compute_resources()
    compute_paths()
end

function update_play()
    -- add a cat by pressing tab
    if btnp(4, 1) then add_cat() end
    -- add 50 to score by pressing s
    if btnp(0, 1) then score += 50 end
    -- set timer to 5 seconds by pressing f
    if btnp(1, 1) then timer = {min=0,sec=5} end
    update_score()
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

function update_score()
    if score < 0 then
        score = 0
    end
end

function compute_resources()
    -- find all bowls and fridges and sinks in the map and fill the resources table
    targets, resources, wanted = {}, {}, {}
    local nfridges, ncupboards = 0, 0
    for j=desc.cy,desc.cy+desc.height do
        for i=desc.cx,desc.cx+desc.width do
            local tile = mget(i,j)
            if tile == 11 then -- this is a bowl
                add(targets, { is_bowl=true, cx=i+0.5, cy=j+0.5, color=4 })
            elseif tile == 50 then -- this is a fridge
                if contains(desc.resources.meat, nfridges) then
                    add(resources, {x = i * 8 + 9, y = j * 8 - 3, xcol = i * 8 + 8, ycol = j * 8, color = 0})
                    if not contains(wanted, 0) then add(wanted, 0) end
                elseif contains(desc.resources.fish, nfridges) then
                    add(resources, {x = i * 8 + 9, y = j * 8 - 3, xcol = i * 8 + 8, ycol = j * 8, color = 1})
                    if not contains(wanted, 1) then add(wanted, 1) end
                end
                nfridges += 1
            elseif tile == 26 then -- this is a sink
                add(resources, {x = i * 8 + 9, y = j * 8 + 1, xcol = i * 8 + 8, ycol = j * 8 + 8, color = 2})
                if not contains(wanted, 2) then add(wanted, 2) end
            elseif (tile == 36 or tile == 39) then -- this is a cupboard
                if contains(desc.resources.cookie, ncupboards) then
                    -- add two resources with different collisions because i can't make it work well :-(
                    add(resources, {x = i * 8 + 8, y = j * 8 - 6, xcol = i * 8 + 8, ycol = j * 8 - 8, color = 3})
                    add(resources, {x = i * 8 + 8, y = j * 8 - 6, xcol = i * 8 + 8, ycol = j * 8, color = 3})
                    if not contains(wanted, 3) then add(wanted, 3) end
                end
                ncupboards += 1
            end
        end
    end
end

function find_path(cx, cy)
    local grid, tovisit, visited = {}, {}, {}
    local dist = 0
    local xmin, xmax = desc.cx * 8, (desc.cx + desc.width - 1) * 8
    local ymin, ymax = desc.cy * 8, (desc.cy + desc.height - 1) * 8
    add(tovisit, flr(cx) + 128 * flr(cy))
    add(tovisit, flr(cx) + 128 * ceil(cy))
    add(tovisit, ceil(cx) + 128 * flr(cy))
    add(tovisit, ceil(cx) + 128 * ceil(cy))
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
            if (y > ymin) and not visited[cell - 128] and not wall(x, y - 8) then nxt[cell - 128] = true end
            if (y < ymax) and not visited[cell + 128] and not wall(x, y + 8) then nxt[cell + 128] = true end
            if (x > xmin) and not visited[cell - 1] and not wall(x - 8, y) then nxt[cell - 1] = true end
            if (x < xmax) and not visited[cell + 1] and not wall(x + 8, y) then nxt[cell + 1] = true end
        end
        -- compute new list of cells to visit
        tovisit = {}
        for k, _ in pairs(nxt) do add(tovisit, k) end
        dist += 1
    end
    --for k, v in pairs(grid) do printh('path['..tostr(k)..'] = '..tostr(v)) end
    return grid
end

function compute_paths()
    -- find all bowls in the map and compute the shortest path to them
    paths = {}
    for i = 1, #targets do
        --printh("find path for target "..tostr(i))
        paths[i] = find_path(targets[i].cx, targets[i].cy)
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
    level += 1
end

function update_pause()
    if score >= desc.fscoremin then
        if levelsaved < level and level <= flevel then
            levelsaved = level
            dset(0, levelsaved)
        end

        if btnp(4) then
            if level > flevel then
                state = "menu"
                begin_menu()
            else
                state = "play"
                begin_play()
            end
            sfx(5)
        end

        for i = 1,3 do
            if score > tscore[i] then
                dset(level - 1, i)
            end
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

function has_cat_nearby(x, y, cat_to_ignore)
    for i=1,#cats do
        local cat=cats[i]
        local dx, dy = cat.x - x, cat.y - y
        if cat != cat_to_ignore and (test_radius(dx, dy, g_player_cat_dist) < 0) then return true end
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
            sfx(10)
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
        for i=1,#targets do
            if targets[i].is_bowl and not targets[i].is_taken then
                local dx = povx - (targets[i].cx * 8 + 4)
                local dy = povy - (targets[i].cy * 8 + 4)
                if test_radius(dx, dy, 8) < 0 then
                    sfx(7)
                    targets[i].color = player.carry
                    player.carry = nil
                    break
                end
            end
        end
    end

    -- if charging or trying to charge, update the progress
    if btn(4) and not player.carry then
        for i=1,#resources do
            local dx = povx - resources[i].xcol
            local dy = povy - resources[i].ycol
            if test_radius(dx, dy, g_player_res_dist) < 0 then
                if not player.charge or player.charge.id != i then
                    player.charge = {id=i, active=true, progress=0}
                else
                    if player.charge.progress % 0.08 < 0.015 then
                        sfx(g_sfx_acquiring)
                    end
                    player.charge.active = true
                    player.charge.progress += 0.015
                    if player.charge.progress > 1 then
                        sfx(g_sfx_acquired)
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
    -- choose a "wanted" resource at random from the level
    cat.want = wanted[1 + flr(rnd(#wanted))]
    add(cats, cat)
end

function update_cats() 
    for i = 1,#cats do
        local cat = cats[i]
        if cat.happy then
            cat.happy -= 1/30
            if cat.happy < 0 then
                cat.happy = nil
                cat.want = wanted[1 + flr(rnd(#wanted))]
            end
        elseif cat.eating then
            -- if the cat is eating, it won't move
            if cat.eating % 0.04 < 0.008 then
                sfx(g_sfx_acquiring)
            end
            cat.eating += 0.008
            if cat.eating > 1 then
                sfx(g_sfx_eaten)
                targets[cat.plan.target].color = 4
                targets[cat.plan.target].is_taken = false
                score += 20
                cat.want = nil
                cat.eating = nil
                cat.plan = nil
                cat.happy = 2 + rnd(5)
            end
        elseif cat.plan then
            local moved = false

            -- if the cat has a plan, make it move in that direction
            local d = paths[cat.plan.target]
            local cell = flr(cat.x / 8) + 128 * flr(cat.y / 8)
            if cell and d[cell] and (d[cell] > 0) then
                if ((d[cell + 1] or 1000) < d[cell]) cat.dir = 1
                if ((d[cell - 1] or 1000) < d[cell]) cat.dir = 0
                if ((d[cell + 128] or 1000) < d[cell]) cat.dir = 3
                if ((d[cell - 128] or 1000) < d[cell]) cat.dir = 2
            end

            local x = cat.x
            if cat.dir == 0 or (cat.dir >= 2 and cat.x % 8 > 4) then
                x -= desc.cat_speed
            elseif cat.dir == 1 or (cat.dir >= 2 and cat.x % 8 < 4) then
                x += desc.cat_speed
            end

            --if not wall_area(x, cat.y, 3, 3) and
            if not wall_area(x, cat.y, 3, 3) and not has_cat_nearby(x, cat.y, cat) and
               max(abs(x - player.x), abs(cat.y - player.y)) >= g_player_cat_dist then
                moved = true
                cat.x = x
            end

            local y = cat.y
            if cat.dir == 2 or (cat.dir <= 1 and cat.y % 8 > 4) then
                y -= desc.cat_speed
            elseif cat.dir == 3 or (cat.dir <= 1 and cat.y % 8 < 4) then
                y += desc.cat_speed
            end

            --if not wall_area(cat.x, y, 3, 3) and
            if not wall_area(cat.x, y, 3, 3) and not has_cat_nearby(cat.x, y, cat) and
               max(abs(cat.x - player.x), abs(y - player.y)) >= g_player_cat_dist then
                moved = true
                cat.y = y
            end

            -- always decrease the timeout so that we can recompute the trajectory
            cat.plan.timeout -= 1/30

            -- did we reach the destination?
            local dx = cat.x - (targets[cat.plan.target].cx * 8 + 4)
            local dy = cat.y - (targets[cat.plan.target].cy * 8 + 4)
            if (test_radius(dx, dy, g_cat_bowl_dist) < 0) and
               targets[cat.plan.target].color == cat.want and
               not targets[cat.plan.target].is_taken then
                targets[cat.plan.target].is_taken = true
                cat.eating = 0
            elseif cat.plan.timeout < 0 then
                -- or maybe we timeouted
                cat.plan = nil
            end
        else
            -- if it does not have a plan, maybe compute one
            for i=1,#targets do
                if targets[i].is_bowl and targets[i].color == cat.want and not targets[i].is_taken then
                    cat.plan = { target = i, timeout = 2 + rnd(2) }
                    break
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
    if levelsaved == 0 then
        cprint("choose level", 70, 5)
    else
        cprint("choose level", 70, 7)
    end
    if grandmapos == 2 and levelsaved != 0 then
        cprint("help", 95, 7)
    else
        cprint("help", 90, 7)
    end
    cprint("an ld42 game by niarkou & sam", 119, 6)
end

function draw_chooselevel()
    if chooselevel then
        for i = 1, levelsaved do
            cosprint(tostr(i), 64 - (levelsaved - 1)*10 + (i - 1)*20, 80, 6, 7)
        end
        if levelsaved > 0 then
            rect(64 - (levelsaved - 1)*10 + (selectlevel - 1)*20 - 3, 80-3, 64 - (levelsaved - 1)*10 + (selectlevel - 1)*20 + 5, 80+7, 14)
        
            for i = 1,3 do
            local colr = 5
                if i <= dget(selectlevel) then
                    colr = 10
                end
            cosprint("★ ", 64 - 23 + (i - 1)*20, 60, 6, colr) 
            end
        end
    end
end

function draw_world()
    palt(0, false)
    map(desc.cx, desc.cy, desc.cx*8, desc.cy*8, desc.height, desc.width)
    palt(0, true)
    foreach(targets, function(t)
        if t.is_bowl then
            spr(66 + t.color, t.cx * 8, t.cy * 8)
        else
        end
    end)
    foreach(resources, function(r)
        spr(82 + r.color, r.x - 4, r.y - 4)
    end)
end

function draw_charge(x, y, t)
    pal()
    x, y = x - 8, y - 8
    local col = 6 + rnd(2)
    for i=1,7 do if (i>t*28) palt(i, true) palt(i+7, true) else pal(i,0) pal(i+7,col) end
    spr(71, x + 8, y, 1, 1)
    for i=1,7 do if (i<14-t*28) palt(i, true) palt(i+7, true) else pal(i,0) pal(i+7,col) end
    spr(71, x + 8, y + 8, 1, 1, false, true)
    for i=1,7 do if (i>t*28-14) palt(i, true) palt(i+7, true) else pal(i,0) pal(i+7,col) end
    spr(71, x, y + 8, 1, 1, true, true)
    for i=1,7 do if (i<28-t*28) palt(i, true) palt(i+7, true) else pal(i,0) pal(i+7,col) end
    spr(71, x, y, 1, 1, true)
    pal()
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
        draw_charge(player.x, player.y - 16, player.charge.progress)
    end
    pal()
end

function draw_pause()
    csprint("time out", 25, 9, 14)
    for i = 1,3 do
        local colr = 5
        tscore = {desc.fscoremin, desc.fscoremin * 1.5, desc.fscoremin * 2}
        if score >= tscore[i] then
            colr = 10
        end
        cosprint("★ ", 64 - 23 + (i - 1)*20, 40, 6, colr) 
    end
    cprint("score", 70, 7)
    cprint(tostr(score).." / "..tostr(desc.fscoremin), 80, 7)
    if score >= desc.fscoremin then
        palt(11,true)
        palt(0,false)
        spr(12, 48, 90, 4, 4)
        palt()

        if level > flevel then
            cprint("you win", 50, 7)
        else cprint("next level", 50, 7)
        end
    else
        cprint("try again", 50, 7)
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

        if cat.happy then
            spr(101, cat.x - 4, cat.y - 13 - 3 * abs(sin(cat.happy)))
        elseif cat.eating then
            -- if the cat is eating, draw the progress
            draw_charge(cat.x, cat.y - 16, cat.eating)
        elseif cat.want then
            -- if the cat wants something, draw a bubble
            local x, y = cat.x - 8, cat.y - 22
            spr(64, x, y, 2, 2, cat.dir)
            palt(11, false)
            palt(0, true)
            spr(82 + cat.want, x + 4, y + 1, 1, 1, dir_x(cat.dir))
        end

        -- debug: if the cat has a plan, draw a line
        if cat.plan and cat.plan.target then
            --printh("cat has a plan for target "..tostr(cat.plan.target).." at ("..tostr(cat.plan.x)..","..tostr(cat.plan.y)..")")
            local col = 12 + rnd(4)
            local d = paths[cat.plan.target]
            local cell = flr(cat.x / 8) + 128 * flr(cat.y / 8)
            --printh("  current cell "..tostr(cell)..": dist "..tostr(d[cell]))
            while cell and d[cell] and (d[cell] > 0) do
                local nextcell = nil
                if ((d[cell + 1] or 1000) < d[cell]) nextcell = cell + 1
                if ((d[cell - 1] or 1000) < d[cell]) nextcell = cell - 1
                if ((d[cell + 128] or 1000) < d[cell]) nextcell = cell + 128
                if ((d[cell - 128] or 1000) < d[cell]) nextcell = cell - 128
                --if (nextcell) line(cell % 128 * 8 + 4, flr(cell / 128) * 8 + 4, nextcell % 128 * 8 + 4, flr(nextcell / 128) * 8 + 4, col)
                cell = nextcell
            end
            --line(cat.x, cat.y, cat.plan.x, cat.plan.y, col)
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
        csprint("feed the cat", 102, 6, 14)
        csprint("press 🅾️ near a bowl", 110, 6, 7)
        csprint("press ❎ to throw away", 118, 6, 7)
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
00000000f9999999999999947777777677776766fffffffffffffff49999999999999999ffffffff7777777677777776bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
00000000f9999999999999947777777677767676ff9f9f9f9994949499999999999999999f9f9f9f7777777677777776bbbbbbbbbbbbbbbbbbbbbbbbb000bbbb
00700700f9999999999999947777777677776766f9f9f999999949449999999999999999f9f9f9f9767dd67677777776bbbbbbbbbbbbbbbbbbbbbbbb0150bbbb
00077000f9999999999999947777777677767676ff999999999999949999999999999999999999997777677677777776bbbbb00000bbbbbbbbbbbbb011500bbb
00077000f9999999999999947777777677776766f9f99999999999949999999999999999999999997777777677777776bbbb055550bbbbbbbbbbb00001110bbb
00700700f9999999999999947777777677767676f9999999999999944949494999999999999999997776777677777776bbb0555550bbbbbbbbb0055550000bbb
00000000f9999999999999947777776677776766f9999999999999949494949499999999999999997777776677777898bb00555000bbbbbbbb05555555550bbb
00000000f9999999999999946666666f6666666df9999999999999944444444499999999999999996666666f66666888bb05500bbbb00000b0555555500550bb
000000000000000095555550550500099111111111111110110100091111111111111110110100009111111111010009b05550bbbbb01111055555550e0050bb
000000000000000055677777777776001128888888888888888882001124444444444444444442001126666666666200b05550bbbbb0666115500555007050bb
000000000000000056777777777777601288888888888888888888201244444444444444444444201266666666666620b05550bbbbbb0666550e00555005500b
0000000000000000567777777777776012888888888888888888882012444444444444444444442012666dddddd66620b05550bbbbbb066555007055566000bb
000000000000000056777777777777601288888888888888888888201244444444444444444444201266d555555d6620b055500bbbbb005555500556666660bb
00000000000000005677777777777760128888888888888888888820124444444444444444444420126d51111115d620bb0555500bbbbb05555556660066000b
000000000000000055666666666666001122222222222222222222001122222222222222222222001122222222222200bb005555500000005555666606660bbb
000000000000000056555550550500601211111111111110110100201211111111111110110100201211111111010020bbb00555555555550506666666660bbb
000000000000000056677777777776601228888128888881288882201224444124444441244442200000000000000000bbbbb00555555555505606666660bbbb
000000000000000056777777777777601288888128888881288888201244444124444441244444200000000000000000bbbbb0555555555505006666660bbbbb
00000000000000005677777777777760121f888121f8888121f88820121d444121d4444121d444200000000000000000bbbb0055555555555505000000bbbbbb
000000000000000056007777777777601288888128888881288888201244444124444441244444200000000000000000bbbb0555555555555555555550bbbbbb
000000000000000056667777777777601288888128888881288888201244444124444441244444200000000000000000bbbb05555555555555555555500bbbbb
000000000000000056777777777777601288888128888881288888201244444124444441244444200000000000000000bbbb055555555555550550555500bbbb
000000000000000056777777777777601288888128888881288888001244444124444441244444000000000000000000bbbbb05555500000555000055550bbbb
000000000000000056777777777777605111111111111110110100055111111111111110110100050000000000000000bbbb005550050bb0555503055660bbbb
000000000000000057777777777777601224444444444444444442201227676667676766676762200000000000000000bbb0555505550bb0555500b06660bbbb
000000000000000057777777777777601244444444444444444444201276767676767676767676200000000000000000bb0655550550bbbb055560bb0660bbbb
000000000000000057777777777777601244444444444444444444201267676667676766676767200000000000000000bb066600b00bbbbb006660bbb00bbbbb
000000000000000057777777777777601244444444444444444444201277777677777776777676200000000000000000bb0660bbbbbbbbbbb06660bbbbbbbbbb
000000000000000057777777777777601244444444444444444444201277777677777776777767200000000000000000bbb00bbbbbbbbbbbbb000bbbbbbbbbbb
000000000000000057777777777777601244444444444444444444201277777677777776777676200000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
000000000000000055666666666666001244444444444444444444001277776677777776777767200000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
000000000000000065555550550500065111111111111110110100056666666f6666666f666666650000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
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
bbbbbbbbbbbbbbbbbbbb2222222bbbbbbbbbbbbbb00b00bb00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbdddbbbbbbbbbb288888882bbbbbbb22bbb07e0820b00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbd6776bbbbbbbb28888888882bbbbb2882bb0e88820b00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbd677776bbbbbbb28888888882bbbbb8ff8bbb08820bb00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb667777776bbbbbbb222888882bbbbbbeffebbbb020bbb00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb6777fff66bbbbbbbbbb22222bbbbbbbbeebbbbbb0bbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb677f5f5f6bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbb77f0f0fbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000
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
0608080808080808081416121308080506080808080808080812130106080808121308080801000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02070712131a1b14152426222314160102070707070707070722230102141516222314151601000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020b0422233435353535363233242601020b0303030303030432330102242526323324252601000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02030422230a03030303030b030304010203030317181819030a040102030303030a03030401000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203043233030303030303030303040102030303373838390303040102030303030303030401000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02030303030303030a030303030304010212130303030b0303030401020304171818190a0401000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020a030317181903030317190303040702222314151603030303040102030427282829030401000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020303033738390a03033739030a0304023233242526171819030401020b0a030303030b0401000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203030303030303030303030303030402030a03030337383903040102030303030303030301000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203030a03041416050603030303040502030303030303030303040108090906030405090908000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
000100000f6240c6210a6210762105611036110361500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200002e750307503375033750307502e7502c70035700317002c70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00040000337742f7702b77025770217701c7701877015770117700d7700c7700a7700877006770057700377002770027700177001770017750000000000000000000000000000000000000000000000000000000
0102000033557345573555737557395573b5573d5573f557000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 01004044
02 04020344

