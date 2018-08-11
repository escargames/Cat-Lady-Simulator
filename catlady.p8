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
        if cat.color == 1 then
            pal(4,5) pal(9,6)
        elseif cat.color == 2 then
            pal(4,4) pal(9,4)
        elseif cat.color == 3 then
            pal(4,4) pal(9,9)
        end
        spr(16, cat.x - 8, cat.y - 12, 2, 2, cat.dir)
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
00000000544449925d55555d54444992000000000000000000000000000000000000000000000000000000000000000033333333333333333333333333333333
00000000544444425555555554444442000000000000000000000000000000000000000000000000000000000000000033333333333333333333333330003333
0070070025555542555d5d5d25555542000000000000000000000000000000000000000000000000000000000000000033333333333333333333333301503333
00077000222222255555555522222225000000000000000000000000000000000000000000000000000000000000000033333000003333333333333011500333
0007700044925444555555d544925444000000000000000000000000000000000000000000000000000000000000000033330555503333333333300001110333
00700700444254445555555542401242000000000000000000000000000000000000000000000000000000000000000033305555503333333330055550000333
00000000554225555d5dd55511200111000000000000000000000000000000000000000000000000000000000000000033005550003333333305555555550333
00000000222522225555555500010000000000000000000000000000000000000000000000000000000000000000000033055003333000003055555550055033
7777777777777777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000003055503333301111055555550e005033
7777777777777777bbbbbbdddbbbbbbbbb000000000000bb00000000000000000000000000000000000000000000000030555033333066611550055500705033
7777777777777777bbbbb6776dbbbbbbb0011111d11d1d5b0000000000000000000000000000000000000000000000003055503333330666550e005550055003
7777777777707707bbbb677776dbbbbbb017777777777d5b00000000000000000000000000000000000000000000000030555033333306655500705556600033
7777777777097090bbb677777766bbbbb01777777747765b00000000000000000000000000000000000000000000000030555003333300555550055666666033
7777777770490490bbb66fff7776bbbbb017744774947d5b00000000000000000000000000000000000000000000000033055550033333055555566600660003
7777777770919190bbb6f5f5f776bbbbb01749f47747765b00000000000000000000000000000000000000000000000033005555500000005555666606660333
7777000000909090bbbbf0f0f77bbbbbb01749947777765b00000000000000000000000000000000000000000000000033300555555555550506666666660333
7770444949999990bbbbfffff2bbbbbbb0d7744774477d5b00000000000000000000000000000000000000000000000033333005555555555056066666603333
7709494949999007bbbbbfffe8222bbbb017777749f4765b00000000000000000000000000000000000000000000000033333055555555550500666666033333
7704949999990777bbbb28ee888882bbb01777774994765b00000000000000000000000000000000000000000000000033330055555555555505000000333333
7709099090907777bbb288888882882bb0d777777447765b00000000000000000000000000000000000000000000000033330555555555555555555550333333
7709090090407777bbb28888888222bbb01777777777765b00000000000000000000000000000000000000000000000033330555555555555555555550033333
7709090090901777bbb222222222bbbbb0dd6d66d6666d5b00000000000000000000000000000000000000000000000033330555555555555505505555003333
7170707101017177bbbb1dd1b1dd1bbbbb555555555555bb00000000000000000000000000000000000000000000000033333055555000005550000555503333
7717171717171777bbbbb11bbb11bbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000033330055500503305555030556603333
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033305555055503305555003066603333
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033065555055033330555603306603333
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033066600300333330066603330033333
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033066033333333333066603333333333
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033300333333333333300033333333333
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033333333333333333333333333333333
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033333333333333333333333333333333
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033333333333333333333333333333333
__gff__
0001000101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101030303030303030303030303010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101020202020202020202020202010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101020202020202020202020202010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101020202020202020202020202010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101020202020202020202020202010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101020202020202020202020202010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101020202020202020202020202010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101020202020202020202020202010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101020202020202010102020202010100000000000000000000000000000000000000000000010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101020202020202010102020202010100000000000000000000000000010101010101010101010202020202020202020101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101020202020202010102020202010100000000000000000000000000010202020202020202010202020202020202020202020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101020202020202010102020202010100000000000000000000000000010202020202020202010202020202020202020202020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101020202020202010102020202010100000000000000000000000000010202020202020202010202020201020202020202020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000001010202020202020202010202020201020202020202020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030300000000000000000000000001020202020202020201010202020201020202020202020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
