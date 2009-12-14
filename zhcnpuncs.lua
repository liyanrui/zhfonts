zhcnpuncs = zhcnpuncs or {}

local glyph = nodes.register (node.new ("glyph", 0))

local glyph_flag = node.id ('glyph')
local glue_flag  = node.id ('glue')
local hlist_flag = node.id ('hlist')
local kern_flag  = node.id ('kern')
local penalty_flag = node.id ('penalty')
local math_flag = node.id ('math')
local fontdata   = fonts.ids

local node_count = node.count
local node_dimensions = node.dimensions
local node_traverse_id = node.traverse_id
local node_slide = node.slide
local list_tail = node.tail
local insert_before = node.insert_before
local insert_after = node.insert_after
local new_glue = nodes.glue
local new_kern = nodes.kern
local new_glue_spec = nodes.glue_spec
local new_penalty = nodes.penalty
local new_rule    = nodes.rule


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
    -- [0x2014] = {-0.1, -0.1, 1.0, 1.0}, -- —
    -- [0x2026] = {0.1, 0.1, 1.0, 1.0},    -- …
    -- [0x2500] = {0.0, 0.0, 1.0, 1.0},    -- ─
    [0x3001] = {0.15, 0.5, 1.0, 0.5},   -- 、
    [0x3002] = {0.15, 0.6, 1.0, 0.0},   -- 。
    [0xFF01] = {0.15, 0.5, 1.0, 0.5},   -- ！
    [0xFF05] = {0.0, 0.0, 1.0, 0.5},    -- ％
    [0xFF0C] = {0.15, 0.5, 1.0, 1.0},   -- ，
    [0xFF0E] = {0.15, 0.5, 1.0, 0.5},   -- ．
    [0xFF1A] = {0.15, 0.5, 1.0, -0.1},   -- ：
    [0xFF1B] = {0.15, 0.5, 1.0, 0.5},   -- ；
    [0xFF1F] = {0.15, 0.5, 1.0, 0.5},   -- ？
}

local function is_zhcnpunc_node (n)
    local n_is_punc = 0
    if puncs[n.char] then
	return true
    end  
    return false
end

local function is_zhcnpunc_node_group (n)
    local n_is_punc = 0
    if puncs[n.char] then
	n_is_punc = 1
    end
    local nn = n.next
    local nn_is_punc = 0
    -- 还需要穿越那些非 glyph 结点
    while nn_is_punc == 0 and nn and n_is_punc == 1 do
	if nn.id == glyph_flag then
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
    local parameters = fontdata[font].parameters
    local quad = (parameters and parameters.quad or parameters[6]) or 0
    return r * quad
end

local function process_punc (head, n, punc_flag, punc_table)
    local desc = fontdata[n.font].descriptions[n.char]
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

local function shrink_glues (head)
    for n in node_traverse_id (glyph_flag, head) do
	local desc = fontdata[n.font].descriptions[n.char]
	local r = quad_multiple (n.font, 1)
	local s = 0
	if desc then
	    s = r * (desc.width - (desc.boundingbox[3] 
				   - desc.boundingbox[1])) / desc.width
	end
	local i = 1
	local those_glue = {}
	local nn = n.next
	while nn do
	    if nn.id == glyph_flag then
		break
	    elseif nn.id == math_flag then
		those_glue = nil
		break
	    elseif nn.id == glue_flag then
		those_glue[i] = nn
	    end
	    nn = nn.next
	    i = i + 1
	end
	if those_glue and #those_glue ~= 0 then
	    for i in pairs (those_glue) do
		those_glue[i].spec.shrink = those_glue[i].spec.shrink + s
	    end
	end
    end
end

local function stretch_glues (head, orphan_width, restrict)
    local m = node_slide (head)
    local test_width = 0
    local upper = restrict * orphan_width
    while m do
	if (test_width >= upper) then
	    break;
	end
	insert_after (head, m, new_penalty (10000))
	test_width = test_width + node_dimensions (m)
	m = m.prev
    end
end

local function process_orphan (head, orphan_factor, stretch_factor)
    local natural_width = node_dimensions (head)
    local hsize = tex.hsize
    local possible_stretch_size = 0
    local glue_num = node_count (glue_flag, head)
    for n in node_traverse_id (glue_flag, head) do
	if (n.subtype == 0) then
	    possible_stretch_size = possible_stretch_size + n.spec.stretch
	end
    end
    local l = 1 + orphan_factor + natural_width / hsize
    local possible_width = natural_width + l * possible_stretch_size / glue_num
    local orphan_size = possible_width % hsize
    local r = orphan_size / hsize
    if r <= orphan_factor and l > 1 then
	local shrink = 0
	local desc = nil
	local r = 0
	local s = 0
	for n in node_traverse_id (glyph_flag, head) do
	    desc = fontdata[n.font].descriptions[n.char]
	    r = quad_multiple (n.font, l)
	    if desc then
		s = s + r * (desc.width - (desc.boundingbox[3] 
					   - desc.boundingbox[1])) / desc.width
	    end
	end
	local scale_l = stretch_factor * l
	if s < scale_l * orphan_size and s > 0 then
	    stretch_glues (head, orphan_size, scale_l)
	else
	    shrink_glues (head)
	end
    end
end

local function compress_punc (head)
    for n in node_traverse_id (glyph_flag, head) do
	local n_flag = is_zhcnpunc_node_group (n)
	if n_flag ~= 0 then
	    process_punc (head, n, n_flag, puncs)
	end
    end
end

local function margin_align (head)
    local hlist_num = node_count (hlist_flag, head)
    local hlist_count = 1
    for n in node_traverse_id (hlist_flag, head) do
	local glyph_num = node_count (glyph_flag, n.list)
	local glyph_count, offset, stretch = 1, 0, 0
	local offset_line_head = nil
	for e in node_traverse_id (glyph_flag, n.list) do
	    local desc = fontdata[e.font].descriptions[e.char]
	    local quad = quad_multiple (e.font, 1)
	    if glyph_count == 1 and is_zhcnpunc_node (e) then
		local m = puncs[e.char][1]
		offset = - m * quad 
		offset_line_head = e
	    elseif glyph_count == glyph_num and is_zhcnpunc_node (e) then
		local m = puncs[e.char][2]
		stretch = m  * quad
	    end
	    glyph_count = glyph_count + 1
	end
	if offset ~= 0 then
	    n.list = insert_before (n.list, offset_line_head, new_kern (offset))
	end
	-- 段落的最后一行不处理
	if hlist_count < hlist_num then
	    if offset ~= 0 or stretch ~= 0 then
		local offset_unit = (-offset + stretch) / glyph_num
		for e in node_traverse_id (glyph_flag, n.list) do
		    insert_after (n.list, e, new_kern (offset_unit))
		end
	    end
	end
    end
end

local function orphan_line_last_check (head, restrict)
    local hlist_num = node_count (hlist_flag, head)
    local hlist_count = 1
    for n in node_traverse_id (hlist_flag, head) do
	if hlist_count ~= 1 and hlist_count == hlist_num then
	    local hsize = tex.hsize
	    local line_width = node.dimensions (n.list)
	    local ratio = line_width / hsize
	    if ratio > 0 and ratio < restrict then
		local line_end = node_slide (n.list)
		while line_end do
		    if line_end.id == glyph_flag then
			insert_after (n.list, line_end, new_rule ((1 - ratio) * hsize))
			break
		    end
		    line_end = line_end.prev
		end
	    end
	end
	hlist_count = hlist_count + 1
    end
end

local old_pre_linebreak_filter = callback.find ('pre_linebreak_filter')
local old_post_linebreak_filter = callback.find ('pre_linebreak_filter')

local function my_pre_linebreak_filter (head, groupcode)
    if old_pre_linebreak_filter then 
	old_pre_linebreak_filter (head, groupcode)
    end
    if groupcode ~= '' then return true end
    compress_punc (head)
    process_orphan (head, 0.15, 6)
    return true
end

local function my_post_linebreak_filter (head, groupcode)
    if old_post_linebreak_filter then 
	old_post_linebreak_filter (head, groupcode)
    end
    if groupcode ~= '' then return true end
    margin_align (head)
    orphan_line_last_check (head, 0.1247)
    return true
end

function zhcnpuncs.opt ()
    callback.register ('pre_linebreak_filter', my_pre_linebreak_filter)
    callback.register ('post_linebreak_filter', my_post_linebreak_filter)
end
