moduledata = moduledata or {}
moduledata.zhfonts = moduledata.zhfonts or {}
local zhfonts = moduledata.zhfonts
local zhspuncs = require "t-zhspuncs"

local string_strip = string.strip
local string_split = string.split
local string_match = string.match
local string_gsub  = string.gsub

local function string_split_and_strip (str, sep)
    local strlist = string_split (str, sep)
    local result  = {}
    for i, v in ipairs (strlist) do
	result[i] = string_strip (v)
    end
    return result
end

local function init_fonts_table ()
    local f = {}
    f.serif, f.sans, f.mono = {}, {}, {}
    for k in pairs (f) do
	f[k] = {regular = {},bold = {}, italic = {}, bolditalic = {}}
    end
    return f
end

local cjkfonts, latinfonts = init_fonts_table (), init_fonts_table ()

cjkfonts.serif.regular    = {name = 'simsun',  rscale = '1.0'}
cjkfonts.serif.bold       = {name = 'simhei',   rscale = '1.0'}
cjkfonts.serif.italic     = {name = 'simsun',  rscale = '1.0'}
cjkfonts.serif.bolditalic = {name = 'simhei',   rscale = '1.0'}
cjkfonts.sans.regular     = {name = 'youyuan',  rscale = '1.0'}
cjkfonts.sans.bold        = {name = 'simhei',   rscale = '1.0'}
cjkfonts.sans.italic      = {name = 'youyuan',  rscale = '1.0'}
cjkfonts.sans.bolditalic  = {name = 'simhei',   rscale = '1.0'}
cjkfonts.mono.regular     = {name = 'fangsong', rscale = '1.0'}
cjkfonts.mono.bold        = {name = 'simkai',   rscale = '1.0'}
cjkfonts.mono.italic      = {name = 'fangsong', rscale = '1.0'}
cjkfonts.mono.bolditalic  = {name = 'simkai',   rscale = '1.0'}

latinfonts.serif.regular    = {name = 'texgyrepagellaregular'}
latinfonts.serif.bold       = {name = 'texgyrepagellabold'}
latinfonts.serif.italic     = {name = 'texgyrepagellaitalic'}
latinfonts.serif.bolditalic = {name = 'texgyrepagellabolditalic'}
latinfonts.sans.regular     = {name = 'texgyreherosregular'}
latinfonts.sans.bold        = {name = 'texgyreherosbold'}
latinfonts.sans.italic      = {name = 'texgyreherositalic'}
latinfonts.sans.bolditalic  = {name = 'texgyreherosbolditalic'}
latinfonts.mono.regular     = {name = 'lmmono10regular'}
latinfonts.mono.bold        = {name = 'lmmonolt10bold'}
latinfonts.mono.italic      = {name = 'lmmono10italic'}
latinfonts.mono.bolditalic  = {name = 'lmmonolt10boldoblique'}

local math_typeface = {}
math_typeface.name = 'xits'

local function gen_cjk_typescript (ft)
    local fb = '\\definefontfallback'
    local fb_area = '[0x00400-0x2FA1F]'
    local s1 = nil

    context ('\\starttypescript[serif][zhfonts]')
    context ('\\setups[font:fallbacks:serif]')
    s = ft.serif.regular
    context (fb..'[zhSerif][name:'..s.name..']'..fb_area..'[force=yes,rscale='..s.rscale..']')
    s = ft.serif.bold
    context (fb..'[zhSerifBold][name:'..s.name..']'..fb_area..'[force=yes,rscale='..s.rscale..']')
    s = ft.serif.italic
    context (fb..'[zhSerifItalic][name:'..s.name..']'..fb_area..'[force=yes,rscale='..s.rscale..']')
    s = ft.serif.bolditalic
    context (fb..'[zhSerifBoldItalic][name:'..s.name..']'..fb_area..'[force=yes,rscale='..s.rscale..']')
    context ('\\stoptypescript')

    context ('\\starttypescript[sans][zhfonts]')
    context ('\\setups[font:fallbacks:sans]')
    s = ft.sans.regular
    context (fb..'[zhSans][name:'..s.name..']'..fb_area..'[force=yes,rscale='..s.rscale..']')
    s = ft.sans.bold
    context (fb..'[zhSansBold][name:'..s.name..']'..fb_area..'[force=yes,rscale='..s.rscale..']')
    s = ft.sans.italic
    context (fb..'[zhSansItalic][name:'..s.name..']'..fb_area..'[force=yes,rscale='..s.rscale..']')
    s = ft.sans.bolditalic
    context (fb..'[zhSansBoldItalic][name:'..s.name..']'..fb_area..'[force=yes,rscale='..s.rscale..']')
    context ('\\stoptypescript')

    context ('\\starttypescript[mono][zhfonts]')
    context ('\\setups[font:fallbacks:mono]')
    s = ft.mono.regular
    context (fb..'[zhMono][name:'..s.name..']'..fb_area..'[force=yes,rscale='..s.rscale..']')
    s = ft.mono.bold
    context (fb..'[zhMonoBold][name:'..s.name..']'..fb_area..'[force=yes,rscale='..s.rscale..']')
    s = ft.mono.italic
    context (fb..'[zhMonoItalic][name:'..s.name..']'..fb_area..'[force=yes,rscale='..s.rscale..']')
    s = ft.mono.bolditalic
    context (fb..'[zhMonoBoldItalic][name:'..s.name..']'..fb_area..'[force=yes,rscale='..s.rscale..']')
    context ('\\stoptypescript')
end

local function gen_latin_typescript (ft)
    local la = '\\definefontsynonym[latin'

    context ('\\starttypescript[serif][zhfonts]')
    context (la..'Serif][name:' .. ft.serif.regular.name .. ']')
    context (la..'SerifBold][name:' .. ft.serif.bold.name .. ']')
    context (la..'SerifItalic][name:' .. ft.serif.italic.name .. ']')
    context (la..'SerifBoldItalic][name:' .. ft.serif.bolditalic.name .. ']')
    context ('\\stoptypescript')

    context ('\\starttypescript[sans][zhfonts]')
    context (la..'Sans][name:' .. ft.sans.regular.name .. ']')
    context (la..'SansBold][name:' .. ft.sans.bold.name .. ']')
    context (la..'SansItalic][name:' .. ft.sans.italic.name .. ']')
    context (la..'SansBoldItalic][name:' .. ft.sans.bolditalic.name .. ']')
    context ('\\stoptypescript')

    context ('\\starttypescript[mono][zhfonts]')
    context (la..'Mono][name:' .. ft.mono.regular.name .. ']')
    context (la..'MonoBold][name:' .. ft.mono.bold.name .. ']')
    context (la..'MonoItalic][name:' .. ft.mono.italic.name .. ']')
    context (la..'MonoBoldItalic][name:' .. ft.mono.bolditalic.name .. ']')
    context ('\\stoptypescript')
end

local function gen_fallback_typescript ()
    context ('\\starttypescript[serif][zhfonts]')
    context ('\\setups[font:fallbacks:serif]')
    context ('\\definefontsynonym[zhSeriffallback][latinSerif][fallbacks=zhSerif]')
    context ('\\definefontsynonym[Serif][zhSeriffallback]')    
    context ('\\definefontsynonym[zhSerifBoldfallback][latinSerifBold][fallbacks=zhSerifBold]')
    context ('\\definefontsynonym[SerifBold][zhSerifBoldfallback]')   
    context ('\\definefontsynonym[zhSerifItalicfallback][latinSerifItalic][fallbacks=zhSerifItalic]')
    context ('\\definefontsynonym[SerifItalic][zhSerifItalicfallback]')
    context ('\\definefontsynonym[zhSerifBoldItalicfallback][latinSerifBoldItalic][fallbacks=zhSerifBoldItalic]')
    context ('\\definefontsynonym[SerifBoldItalic][zhSerifBoldItalicfallback]')
    context ('\\stoptypescript')

    context ('\\starttypescript[sans][zhfonts]')
    context ('\\setups[font:fallbacks:sans]')
    context ('\\definefontsynonym[zhSansfallback][latinSans][fallbacks=zhSans]')
    context ('\\definefontsynonym[Sans][zhSansfallback]')    
    context ('\\definefontsynonym[zhSansBoldfallback][latinSansBold][fallbacks=zhSansBold]')
    context ('\\definefontsynonym[SansBold][zhSansBoldfallback]')   
    context ('\\definefontsynonym[zhSansItalicfallback][latinSansItalic][fallbacks=zhSansItalic]')
    context ('\\definefontsynonym[SansItalic][zhSansItalicfallback]')
    context ('\\definefontsynonym[zhSansBoldItalicfallback][latinSansBoldItalic][fallbacks=zhSansBoldItalic]')
    context ('\\definefontsynonym[SansBoldItalic][zhSansBoldItalicfallback]')
    context ('\\stoptypescript')

    context ('\\starttypescript[mono][zhfonts]')
    context ('\\setups[font:fallbacks:mono]')
    context ('\\definefontsynonym[zhMonofallback][latinMono][fallbacks=zhMono]')
    context ('\\definefontsynonym[Mono][zhMonofallback]')    
    context ('\\definefontsynonym[zhMonoBoldfallback][latinMonoBold][fallbacks=zhMonoBold]')
    context ('\\definefontsynonym[MonoBold][zhMonoBoldfallback]')   
    context ('\\definefontsynonym[zhMonoItalicfallback][latinMonoItalic][fallbacks=zhMonoItalic]')
    context ('\\definefontsynonym[MonoItalic][zhMonoItalicfallback]')
    context ('\\definefontsynonym[zhMonoBoldItalicfallback][latinMonoBoldItalic][fallbacks=zhMonoBoldItalic]')
    context ('\\definefontsynonym[MonoBoldItalic][zhMonoBoldItalicfallback]')
    context ('\\stoptypescript')
end

local function gen_typeface ()
    context ('\\starttypescript[zhfonts]')
    context ('\\definetypeface[zhfonts][rm][serif][zhfonts][default][features=zh]')
    context ('\\definetypeface[zhfonts][ss][sans][zhfonts][default][features=zh]')
    context ('\\definetypeface[zhfonts][tt][mono][zhfonts][default]')
    if math_typeface then
	context ('\\definetypeface[zhfonts][mm][math]['.. math_typeface.name .. '][default][rscale=auto]')
    end
    context ('\\stoptypescript')
end

function zhfonts.gen_typescript ()
    gen_cjk_typescript (cjkfonts)
    gen_latin_typescript (latinfonts)
    gen_fallback_typescript ()
    gen_typeface ()
end

local function setup_cjkfonts (meta, fontlist)
    local f, g = nil, nil
    for i, v in ipairs (fontlist) do
	f = string_split_and_strip (v, '=')
	g = string_split_and_strip (f[2], '@')
	if g[1] ~= '' then cjkfonts[meta][f[1]].name = g[1] end
	if g[2] then cjkfonts[meta][f[1]].rscale = g[2] end
    end
end

local function setup_latinfonts (meta, fontlist)
    local f, g = nil, nil
    for i, v in ipairs (fontlist) do
	f = string_split_and_strip (v, '=')
	latinfonts[meta][f[1]].name = f[2]
    end   
end

local function setup_math_typeface (name)
    math_typeface.name = string_strip (name)
end

local fontfeatures = "mode=node,protrusion=myvector,liga=yes"
local function setup_fontfeatures (s)
    fontfeatures = fontfeatures .. s
end

function zhfonts.setup (metainfo, fontinfo)
    local m = string_split_and_strip (metainfo, ',')
    local f = string_split_and_strip (fontinfo, ',')
    if #m == 1 and m[1] == 'feature' then setup_fontfeatures (fontinfo) end
    if #m == 1 and cjkfonts[m[1]] then setup_cjkfonts (m[1], f)  end
    if #m == 1 and m[1] == 'math' then setup_math_typeface (f[1]) end
    if #m == 2 then
	if m[1] == 'latin' and latinfonts[m[2]] then setup_latinfonts (m[2], f) end
	if m[2] == 'latin' and latinfonts[m[1]] then setup_latinfonts (m[1], f) end	
    end
end

function zhfonts.main (param)
    context ('\\setscript[hanzi]')
    zhspuncs.opt ()
    local arg_list = string_split_and_strip (param, ',')
    if arg_list[1] ~= "none" and arg_list[2] ~= "none" then
	context ('\\definefontfeature[zh][default][' .. fontfeatures .. ']')
	context ('\\setupalign[hz,hanging]')
        zhfonts.gen_typescript ()
        if arg_list[1] ~= "hack" and arg_list[2] ~= "hack" then
	    context ('\\usetypescript[zhfonts]')
            context ('\\setupbodyfont[zhfonts, ' .. param .. ']') 
        end
    end
end

