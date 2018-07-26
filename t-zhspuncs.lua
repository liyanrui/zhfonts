zhspuncs = zhspuncs or {}

local hlist = nodes.nodecodes.hlist
local glyph   = nodes.nodecodes.glyph --node.id ('glyph')
local fonthashes = fonts.hashes
local fontdata   = fonthashes.identifiers
local quaddata   = fonthashes.quads
local node_count = node.count
local node_dimensions = node.dimensions
local node_traverse_id = node.traverse_id
local insert_before = node.insert_before
local insert_after = node.insert_after
local new_kern = nodes.pool.kern
local tasks = nodes.tasks

local left_puncs = {
    [0x2018] = 0.35, -- ‘
    [0x201C] = 0.35, -- “
    [0x3008] = 0.35, -- 〈
    [0x300A] = 0.35, -- 《
    [0x300C] = 0.35, -- 「
    [0x300E] = 0.35, -- 『
    [0x3010] = 0.35, -- 【
    [0x3014] = 0.35, -- 〔
    [0x3016] = 0.35, -- 〖
    [0xFF08] = 0.35, -- （
    [0xFF3B] = 0.35, -- ［
    [0xFF5B] = 0.35  -- ｛
}

local function is_left_punc(n)
    if left_puncs[n.char] then return true end
    return false
end

local puncs = {
    [0x2018] = {0.5, 0.1, 1.0, 1.0}, -- ‘
    [0x201C] = {0.5, 0.1, 0.5, 1.0}, -- “
    [0x3008] = {0.5, 0.1, 1.0, 1.0}, -- 〈
    [0x300A] = {0.5, 0.1, 1.0, 1.0}, -- 《
    [0x300C] = {0.5, 0.1, 1.0, 1.0}, -- 「
    [0x300E] = {0.5, 0.1, 1.0, 1.0}, -- 『
    [0x3010] = {0.5, 0.1, 1.0, 1.0}, -- 【
    [0x3014] = {0.5, 0.1, 1.0, 1.0}, -- 〔
    [0x3016] = {0.5, 0.1, 1.0, 1.0}, -- 〖
    [0xFF08] = {0.5, 0.1, 1.0, 1.0}, -- （
    [0xFF3B] = {0.5, 0.1, 1.0, 1.0}, -- ［
    [0xFF5B] = {0.5, 0.1, 1.0, 1.0}, -- ｛
    [0x2019] = {0.1, 0.5, 1.0, 0.0}, -- ’
    [0x201D] = {0.1, 0.5, 1.0, 0.0}, -- ”
    [0x3009] = {0.1, 0.5, 1.0, 0.5}, -- 〉
    [0x300B] = {0.1, 0.5, 1.0, 0.5}, -- 》
    [0x300D] = {0.1, 0.5, 1.0, 0.5}, -- 」
    [0x300F] = {0.1, 0.5, 1.0, 0.5}, -- 』
    [0x3011] = {0.1, 0.5, 1.0, 0.5}, -- 】
    [0x3015] = {0.1, 0.5, 1.0, 0.5}, -- 〕
    [0x3017] = {0.1, 0.5, 1.0, 0.5}, -- 〗
    [0xFF09] = {0.1, 0.5, 1.0, 0.5}, -- ）
    [0xFF3D] = {0.1, 0.5, 1.0, 0.5}, -- ］
    [0xFF5D] = {0.1, 0.5, 1.0, 0.5}, -- ｝
    -- 需要特殊处理
    [0x2014] = {0.0, 0.0, 1.0, 1.0}, -- —
    [0x2026] = {0.1, 0.1, 1.0, 1.0},    -- …
    [0x2500] = {0.0, 0.0, 1.0, 1.0},    -- ─
    [0x3001] = {0.15, 0.5, 1.0, 0.5},   -- 、
    [0x3002] = {0.15, 0.6, 1.0, 0.3},   -- 。
    [0xFF01] = {0.15, 0.5, 1.0, 0.5},   -- ！
    [0xFF05] = {0.0, 0.0, 1.0, 0.5},    -- ％
    [0xFF0C] = {0.15, 0.5, 1.0, 0.3},   -- ，
    [0xFF0E] = {0.15, 0.5, 1.0, 0.5},   -- ．
    [0xFF1A] = {0.15, 0.5, 1.0, -0.1},   -- ：
    [0xFF1B] = {0.15, 0.5, 1.0, 0.5},   -- ；
    [0xFF1F] = {0.15, 0.5, 1.0, 0.5},   -- ？
}

local function is_zhcnpunc_node_group (n)
    local n_is_punc = 0
    if puncs[n.char] then
	n_is_punc = 1
    end
    local nn = n.next
    local nn_is_punc = 0
    -- 还需要穿越那些非 glyph 结点
    while nn_is_punc == 0 and nn and n_is_punc == 1 do
	if nn.id == glyph then
	    if puncs[nn.char] then nn_is_punc = 1 end
	    break
	end
	nn = nn.next
    end
    return n_is_punc + nn_is_punc
end

local function is_cjk_ideo (n)
    -- CJK Ext A
    if n.char >= 13312 and n.char <= 19893 then
	return true
	-- CJK
    elseif n.char >= 19968 and n.char <= 40891 then
	return true
	-- CJK Ext B
    elseif n.char >= 131072 and n.char <= 173782 then
	return true
    else
	return false
    end
end

local function quad_multiple (font, r)
    local quad = quaddata[font]
    return r * quad
end

local function process_punc (head, n, punc_flag, punc_table)
    local desc = fontdata[n.font].descriptions[n.char]
    if not desc then return end
    local quad = quad_multiple (n.font, 1)

    local l_space = desc.boundingbox[1] / desc.width
    local r_space = (desc.width - desc.boundingbox[3]) / desc.width
    local l_kern, r_kern = 0.0, 0.0

    if punc_flag == 1 then
	l_kern = (punc_table[n.char][1] - l_space) * quad
	r_kern = (punc_table[n.char][2] - r_space) * quad
    elseif punc_flag == 2 then
	l_kern = (punc_table[n.char][1] * punc_table[n.char][3] - l_space) * quad
	r_kern = (punc_table[n.char][2] * punc_table[n.char][4] - r_space) * quad
    end

    insert_before (head, n, new_kern (l_kern))
    insert_after (head, n, new_kern (r_kern))
end

local function compress_punc (head)
    for n in node_traverse_id (glyph, head) do
	local n_flag = is_zhcnpunc_node_group (n)
	if n_flag ~= 0 then
	    process_punc (head, n, n_flag, puncs)
	end
    end
end

function zhspuncs.my_linebreak_filter (head, is_display)
    compress_punc (head)
    return head, true
end

function zhspuncs.align_left_puncs(head)
    local it = head
    while it do
        if it.id == hlist then
            local e = it.head
            local neg_kern = nil
            local hit = nil
            while e do
                if e.id == glyph then
                    if is_left_punc(e) then
                        hit = e
                    end
                    break
                end
                e = e.next
            end
            if hit ~= nil then
                -- 文本行整体向左偏移
                neg_kern = -left_puncs[hit.char] * quad_multiple(hit.font, 1)
                insert_before(head, hit, new_kern(neg_kern))
                -- 统计字符个数
                local w = 0
                local x = hit
                while x do
                    if x.id == glyph then w = w + 1 end
                    x = x.next
                end
                if w == 0 then w = 1 end
                -- 将 neg_kern 分摊出去
                x = it.head -- 重新遍历
                av_neg_kern = -neg_kern/w
                local i = 0
                while x do
                    if x.id == glyph then
                        i = i + 1
                        -- 最后一个字符之后不插入 kern
                        if i < w then 
                            insert_after(head, x, new_kern(av_neg_kern))
                        end
                    end
                    x = x.next
                end
            end
        end
        it = it.next
    end
    return head, done
end


function zhspuncs.opt ()
    tasks.appendaction("processors","after","zhspuncs.my_linebreak_filter")
    nodes.tasks.appendaction("finalizers", "after", "zhspuncs.align_left_puncs")
end

fonts.protrusions.vectors['myvector'] = {  
   [0xFF0c] = { 0, 0.60 },  -- ，
   [0x3002] = { 0, 0.60 },  -- 。
   [0x2018] = { 0.60, 0 },  -- ‘
   [0x2019] = { 0, 0.60 },  -- ’
   [0x201C] = { 0.50, 0 },  -- “
   [0x201D] = { 0, 0.35 },  -- ”
   [0xFF1F] = { 0, 0.60 },  -- ？
   [0x300A] = { 0.60, 0 },  -- 《
   [0x300B] = { 0, 0.60 },  -- 》
   [0xFF08] = { 0.50, 0 },  -- （
   [0xFF09] = { 0, 0.50 },  -- ）
   [0x3001] = { 0, 0.50 },  -- 、
   [0xFF0E] = { 0, 0.50 },  -- ．
}
fonts.protrusions.classes['myvector'] = {
   vector = 'myvector', factor = 1
}

return zhspuncs

