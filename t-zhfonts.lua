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
        serif = {regular = {name = "nsimsun", rscale = "1.0"},
                 bold = {name = "simhei", rscale = "1.0"},
                 italic = {name = "nsimsun", rscale = "1.0"},
                 bolditalic = {name = "simhei", rscale = "1.0"}},
        sans = {regular = {name = "simhei", rscale = "1.0"},
                bold = {name = "simhei", rscale = "1.0"},
                italic = {name = "simhei", rscale = "1.0"},
                bolditalic = {name = "simhei", rscale = "1.0"}},
        mono = {regular = {name = "kaiti", rscale = "1.0"},
                bold = {name = "simhei", rscale = "1.0"},
                italic = {name = "kaiti", rscale = "1.0"},
                bolditalic = {name = "simhei", rscale = "1.0"}}
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

local text_fonts = init_fonts_table()
local math_typescript = "modern"
-- It would break the features of latin fonts.
-- local fontfeatures = "mode=node,script=hang,lang=zhs,protrusion=zhspuncs"
local hanzifeatures = "mode=node,script=hang,lang=zhs,protrusion=zhspuncs"
local latinfeatures = "default"

function zhfonts.gen_typescript()
    local path = resolvers.findfile("t-zhfonts.template")
    local template = assert(io.open(path, "r"))
    local typescript = template:read("*all")
    local rep, k = {}, 1
    local family = {"serif", "sans", "mono"}
    local style = {"regular", "bold", "italic", "bolditalic"}
    -- substitute chinese and latin fonts.
    for _, a in pairs(family) do
        for _, b in pairs(style) do
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
    rep[k + 1] = {"hanzifeatures!", hanzifeatures}
    rep[k + 2] = {"latinfeatures!", latinfeatures}
    local real_typescript = lpeg.replacer(rep):match(typescript)
    context.tobuffer("zhfonts:typescript", real_typescript)
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
local function setup_hanzifeatures (s)
    hanzifeatures = hanzifeatures .. "," .. s
end
local function setup_latinfeatures (s)
    latinfeatures = latinfeatures .. "," .. s
end
function zhfonts.setup(metainfo, fontinfo)
    local m = string_split_and_strip(metainfo, ",")
    local f = string_split_and_strip(fontinfo, ",")
    if #m == 1 and m[1] == "features" then
        setup_hanzifeatures(fontinfo)
    end
    if #m == 1 and text_fonts.chinese[m[1]]then
        setup_chinesefonts(m[1], f)
    end
    if #m == 1 and m[1] == "math" then
        setup_math_typescript(f[1]) end
    if #m == 2 then
	if m[1] == "latin" then
            if text_fonts.latin[m[2]] then
                setup_latinfonts(m[2], f)
            elseif m[2] == "features" then
                setup_latinfeatures(fontinfo)
            end
        end
	if m[2] == "latin" then
            if text_fonts.latin[m[1]] then
                setup_latinfonts(m[1], f)
            elseif  m[1] == "features" then
                setup_latinfeatures(fontinfo)
            end
        end
    end
end

function zhfonts.main(param)
    zhspuncs.opt()
    local arg_list = string_split_and_strip(param, ",")
    if arg_list[1] ~= "none" and arg_list[2] ~= "none" then
        zhfonts.gen_typescript()
        context("\\getbuffer[zhfonts:typescript]")
        if arg_list[1] ~= "hack" and arg_list[2] ~= "hack" then
            context("\\usetypescript[zhfonts]")
            context("\\setupbodyfont[zhfonts, " .. param .. "]")
        end
    end
    context("\\setscript[hanzi]\\setupalign[hanging, hz]")
end
