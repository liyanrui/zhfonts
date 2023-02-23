moduledata = moduledata or {}
moduledata.zhfonts = moduledata.zhfonts or {}

local zhfonts = moduledata.zhfonts
local zhspuncs = require "t-zhspuncs"

local string_strip = string.strip
local string_split = string.split
local string_match = string.match
local string_gsub  = string.gsub

local function string_split_and_strip(str, sep)
    local strlist = string_split(str, sep)
    local result  = {}
    for i, v in ipairs(strlist) do
	result[i] = string_strip(v)
    end
    return result
end

local function init_fonts_table()
    local f = {}
    f.chinese = {
        serif = {regular = {name = "simsun", rscale = "1.0"},
                 bold = {name = "simsun", rscale = "1.0"},
                 italic = {name = "simsun", rscale = "1.0"},
                 bolditalic = {name = "simsun", rscale = "1.0"}},
        sans = {regular = {name = "simhei", rscale = "1.0"},
                bold = {name = "simhei", rscale = "1.0"},
                italic = {name = "simhei", rscale = "1.0"},
                bolditalic = {name = "simhei", rscale = "1.0"}},
        mono = {regular = {name = "kaiti", rscale = "1.0"},
                bold = {name = "kaiti", rscale = "1.0"},
                italic = {name = "kaiti", rscale = "1.0"},
                bolditalic = {name = "kaiti", rscale = "1.0"}}
    }
    f.latin = {
        serif = {regular = "lmroman10regular", bold = "lmroman10bold",
                 italic = "lmroman10italic", bolditalic = "lmroman10bolditalic"},
        sans = {regular = "lmsans10regular", bold = "lmsans10bold",
                italic = "lmsans10oblique", bolditalic = "lmsans10boldoblique"},
        mono = {regular = "lmmono10regular", bold = "lmmonolt10bold",
                italic = "lmmonolt10oblique", bolditalic = "lmmonolt10boldoblique"}        
    }
    return f
end

fonts.protrusions.vectors["myvector"] = {  
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
fonts.protrusions.classes["myvector"] = {
    vector = "myvector",
    factor = 1
}

local text_fonts = init_fonts_table()
local math_typescript = "modern"
local fontfeatures = "protrusion=myvector"

function zhfonts.gen_typescript()
    local path = resolvers.findfile("typescript.template")
    local template = assert(io.open(path, "r"))
    local typescript = template:read("*all")
    local rep, k = {}, 1
    local style = {"serif", "sans", "mono"}
    local type = {"regular", "bold", "italic", "bolditalic"}
    -- substitute chinese and latin fonts.
    for _, a in pairs(style) do
        for _, b in pairs(type) do
            local fontname = a .. b
            rep[k] = {"zh" .. fontname .. "!",
                      "name:" .. text_fonts.chinese[a][b].name}
            rep[k + 1] = {"zh" .. fontname .. "@rscale!",
                          text_fonts.chinese[a][b].rscale}
            rep[k + 2] = {"latin" .. fontname .. "!",
                          "name:" .. text_fonts.latin[a][b]}
            k = k + 3
        end
    end
    -- substitute math fonts.
    rep[k] = {"mathtypescriptname!", math_typescript}
    rep[k + 1] = {"features!", fontfeatures}
    local real_typescript = lpeg.replacer(rep):match(typescript)
    context(real_typescript)
    template:close()
    return real_typescript
end

local function setup_chinesefonts(meta, fontlist)
    local f, g = nil, nil
    for i, v in ipairs(fontlist) do
	f = string_split_and_strip(v, "=")
	g = string_split_and_strip(f[2], "@")
	if g[1] ~= "" then text_fonts.chinese[meta][f[1]].name = g[1] end
	if g[2] then text_fonts.chinese[meta][f[1]].rscale = g[2] end
    end
end
local function setup_latinfonts(meta, fontlist)
    local f, g = nil, nil
    for i, v in ipairs(fontlist) do
	f = string_split_and_strip(v, "=")
	text_fonts.latin[meta][f[1]] = f[2]
    end   
end
local function setup_math_typescript(name)
    math_typescript = string_strip(name)
end
local function setup_fontfeatures (s)
    fontfeatures = fontfeatures .. "," .. s
end
function zhfonts.setup(metainfo, fontinfo)
    local m = string_split_and_strip(metainfo, ",")
    local f = string_split_and_strip(fontinfo, ",")
    if #m == 1 and m[1] == "features" then
        setup_fontfeatures(fontinfo)
    end
    if #m == 1 and text_fonts.chinese[m[1]]then
        setup_chinesefonts(m[1], f)
    end
    if #m == 1 and m[1] == "math" then
        setup_math_typescript(f[1]) end
    if #m == 2 then
	if m[1] == "latin" and text_fonts.latin[m[2]] then
            setup_latinfonts(m[2], f)
        end
	if m[2] == "latin" and text_fonts.latin[m[1]] then
            setup_latinfonts(m[1], f)
        end	
    end
end

function zhfonts.main(param)
    context("\\setscript[hanzi]")
    zhspuncs.opt()
    local arg_list = string_split_and_strip(param, ",")
    if arg_list[1] ~= "none" and arg_list[2] ~= "none" then
        zhfonts.gen_typescript()
        if arg_list[1] ~= "hack" and arg_list[2] ~= "hack" then
            context("\\usetypescript[zhfonts]")
            context("\\setupbodyfont[zhfonts, " .. param .. "]")
            context("\\setupalign[hanging, hz]")
        end
    end
end
