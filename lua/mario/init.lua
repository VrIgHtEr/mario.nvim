local K, I, C = require 'meow', require 'meow.image', require 'mario.characters'

local fps = 25
local running, halting, active = false, false, 0

local function init()
    C.init()
    for _, c in ipairs(C.data) do
        function c.update(state)
            c.state = type(state) == 'string' and state or c.state
            if c.state == 'idle' then
                if halting then
                    return c.update 'halted'
                end
                c.state = 'waiting'
                c.counter = math.random(25, 25 * 11)
                c.dir = not c.dir
                c.xinc, c.xpos = c.dir and 1 or -1, c.dir and -c.anim.w or (K.win_w + c.anim.w)
                local maxspeed, minspeed = c.anim.frames - 1 + c.anim.frames, 1
                c.speed = math.max(minspeed, math.random() * (maxspeed - minspeed) + minspeed)
                c.frame_counter = 0
            elseif c.state == 'waiting' then
                if halting then
                    c.hide()
                    return c.update 'halted'
                end
                c.counter = c.counter - 1
                if c.counter == 0 then
                    active = active + 1
                    return c.update 'animating'
                end
            elseif c.state == 'animating' then
                c.xpos = c.xpos + c.xinc * c.speed
                c.anim.cur_frame = math.floor((c.frame_counter / c.anim.speed * c.speed) % (c.anim.frames > 1 and c.anim.frames - 2 + c.anim.frames or 1))
                if c.anim.cur_frame >= c.anim.frames then
                    c.anim.cur_frame = c.anim.frames - 1 + c.anim.frames - c.anim.cur_frame
                end
                c.frame_counter = c.frame_counter + 1
                c.display {
                    pos = { x = math.floor(c.xpos), y = K.win_h - 1 },
                    crop = {
                        x = c.anim.x + c.anim.cur_frame * c.anim.stride_x,
                        y = c.anim.y + (c.dir and 0 or c.anim.stride_y),
                        w = c.anim.w,
                        h = c.anim.h,
                    },
                    z = c.anim.z,
                    anchor = c.dir and 3 or 2,
                }
                if (not c.dir or c.xpos >= K.win_w) and (c.dir or c.xpos < 0) then
                    c.hide()
                    active = active - 1
                    return c.update 'idle'
                end
            elseif c.state == 'halted' then
                if not halting then
                    return c.update 'idle'
                end
            end
        end
    end
end

local queued_func = nil

local function animation_loop()
    if running and queued_func == nil then
        K.begin_transaction()
        C.exec 'update'
        if halting and active == 0 then
            running, halting = false, false
            C.destroy()
        elseif K.is_initialized() then
            vim.defer_fn(animation_loop, 1000 / fps)
        elseif queued_func == nil then
            queued_func = function()
                queued_func = nil
                animation_loop()
            end
            K.when_initialized(queued_func)
        end
        K.end_transaction()
    end
end

local M
M = {
    lets_a_gooo = function()
        if halting then
            halting = false
        elseif not running and K.supported() then
            running = true
            local start = function()
                init()
                animation_loop()
            end
            if not K.is_initialized() then
                local st = start
                start = function()
                    K.when_initialized(st)
                end
            end
            start()
        end
    end,
    oh_nooo = function()
        if running and not halting then
            halting = true
        end
    end,
    its_a_meee = function()
        ((not running or halting) and M.lets_a_gooo or M.oh_nooo)()
    end,
}
return M
