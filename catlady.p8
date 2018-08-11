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
    state = "play"
    player = {x = 64, y = 64, dir = true, spd = 2, bob = 0, walk = 0}
    cats = { {x = 32, y = 20, color = 1, dir = false, spd = 1.5},
             {x = 92, y = 40, color = 2, dir = false, spd = 1.5},
             {x = 40, y = 80, color = 3, dir = false, spd = 1.5}}
    bowls = { { cx = 5, cy = 4, color = 0 },
              { cx = 2, cy = 10, color = 1 }}
end

function _update()
    if (state == "menu") then
        update_menu()
    elseif (state == "play") then
        update_play()
    --elseif (state == "pause") then
        --update_pause()
    end
end

function _draw()
    config[state].draw()
end

--
-- menu state handling
--

function update_menu()

end

--
-- play state handling
--

function update_play()
    update_player()
    update_cats()
end

--
-- collisions
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
    spr(130 + 2 * flr(player.walk % 2), player.x - 8, player.y - 12, 2, 2, player.dir)
    spr(128, player.x - 8, player.y - 12 + sin(player.bob), 2, 2, player.dir)
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
        spr(64, cat.x - 16, cat.y - 18, 2, 2, cat.dir)
        else
        spr(64, cat.x, cat.y - 18, 2, 2, cat.dir)
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
00000000799999999999999477777776777777767777777777777774999999999999999977777777000000000000000033333333333333333333333333333333
00000000799999999999999477777776777777767797979799949494999999999999999997979797000000000000000033333333333333333333333330003333
00700700799999999999999477777776777777767979799999994944999999999999999979797979000000000000000033333333333333333333333301503333
00077000799999999999999477777776777777767799999999999994999999999999999999999999000000000000000033333000003333333333333011500333
00077000799999999999999477777776777777767979999999999994999999999999999999999999000000000000000033330555503333333333300001110333
00700700799999999999999477777776777777767999999999999994494949499999999999999999000000000000000033305555503333333330055550000333
00000000799999999999999477777766777777667999999999999994949494949999999999999999000000000000000033005550003333333305555555550333
0000000079999999999999946666666f6666666f7999999999999994444444449999999999999999000000000000000033055003333000003055555550055033
bbbbbbbbbbbbbbbb0000000000000000bbbbbbbbbbbbbbbb0666666000000000000000000000000000000000000000003055503333301111055555550e005033
bbbbbbbbbbbbbbbb0000000000000000bb000000000000bb67777776000000000000000000000000000000000000000030555033333066611550055500705033
bbbbbbbbbbbbbbbb0000000000000000b0011111d11d1d5b6777777608000080030000300100001000000000000000003055503333330666550e005550055003
bbbbbbbbbbb0bb0b0000000000000000b017777777777d5b6777777c8ee88ef83bb33ba31cc11c61000000000000000030555033333306655500705556600033
bbbbbbbbbb09b0900000000000000000b01777777747765b605777768effffe83baaaab31c6666c1000000000000000030555003333300555550055666666033
bbbbbbbbb04904900000000000000000b017744774947d5b6777777c088888800333333001111110000000000000000033055550033333055555566600660003
bbbbbbbbb09191900000000000000000b01749f47747765b0666c6c0000000000000000000000000000000000000000033005555500000005555666606660333
bbbb0000009090900000000000000000b01749947777765b67777776000000000000000000000000000000000000000033300555555555550506666666660333
bbb04449499999900000000000000000b0d7744774477d5b67777776000000000000000000000000000000000000000033333005555555555056066666603333
bb0949494999900b0000000000000000b017777749f4765b60577776000000000000000000000000000000000000000033333055555555550500666666033333
bb04949999990bbb0000000000000000b01777774994765b67777776000000000000000000000000000000000000000033330055555555555505000000333333
bb0909909090bbbb0000000000000000b0d777777447765b67777776000000000000000000000000000000000000000033330555555555555555555550333333
bb0909009040bbbb0000000000000000b01777777777765b6777777c000000000000000000000000000000000000000033330555555555555555555550033333
bb0909009090bbbb0000000000000000b0dd6d66d6666d5b67777776000000000000000000000000000000000000000033330555555555555505505555003333
bbb0b0bb0b0bbbbb0000000000000000bb555555555555bb6777777c000000000000000000000000000000000000000033333055555000005550000555503333
bbbbbbbbbbbbbbbb0000000000000000bbbbbbbbbbbbbbbb0666c6c0000000000000000000000000000000000000000033330055500503305555030556603333
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033305555055503305555003066603333
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033065555055033330555603306603333
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033066600300333330066603330033333
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033066033333333333066603333333333
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033300333333333333300033333333333
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033333333333333333333333333333333
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033333333333333333333333333333333
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033333333333333333333333333333333
bb00000bbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b0677770bbbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
067777770bbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
067777770bbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
077777770bbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
077777760bbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b07776605bbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb00000b0bbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbb0bbbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbb0bbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbdddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbd6776bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbd677776bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb667777776bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb6777fff66bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb677f5f5f6bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbb77f0f0fbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbfffffbbbbbbbbb2222222bbbbbbbbbbbbb2222bbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbefffbbbbbbbbb288888882bbbbbbbbb22288882bbb00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbeeebbbbbbbb28888888882bbbbbbb288888882bbb00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbb28888888882bbbbbb2888888882bbb00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbb222888882bbbbbbb288888882bbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbb1c22222c1bbbbbb28822222bbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbb1cc1bb1cc1bbbbbbb221cc1c1bbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbb11bbbb11bbbbbbbbbb111111bbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0001010000010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0608080808080808080808080808080500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0207070707070707070707070707070100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203030403040304030403040304030100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203030403040304030403040304030100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203030403040304030403040304030100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203030403040304030403040304030100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203030403040304030403040304030700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203030403040304030403040304030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203030403040304050603040304030500000000000000000000000000000000000000000000010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203030403040304010203040304030100000000000000000000000000010101010101010101010202020202020202020101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203030403040304010203040304030100000000000000000000000000010202020202020202010202020202020202020202020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203030403040304010203040304030100000000000000000000000000010202020202020202010202020202020202020202020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203030403040304010203040304030100000000000000000000000000010202020202020202010202020201020202020202020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0809090909090909080809090909090800000000000000000000000001010202020202020202010202020201020202020202020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0808080808080808080808080808080800000000000000000000000001020202020202020201010202020201020202020202020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
