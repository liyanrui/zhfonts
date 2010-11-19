zhfonts = zhfonts or {}

local family_index = {'serif', 'sans', 'mono'}
local type_index = {'regular', 'bold', 'italic', 'bolditalic'}

local zh_font_model = {}
local latin_font_model = {}

local function values (t)
    local i = 0
    return function () i = i + 1; return t[i] end
end

local function strsplit(str, sep)
    local start_pos = 1
    local split_pos = 1
    local result = {}
    while true do
        local stop_pos = string.find (str, sep, start_pos)
        if not stop_pos then
            result[split_pos] = string.sub (str, start_pos, string.len(str))
            break
        end
        result[split_pos] = string.sub (str, start_pos, stop_pos - 1)
        start_pos = stop_pos + string.len(sep)
        split_pos = split_pos + 1
    end
    return result
end

local function strtrim (str)
     return string.gsub (str, "^%s*(.-)%s*$", "%1")
end

local function gen_default_font_model ()
    local zh_default_font = {[family_index[1]] = 'nsimsun', 
			     [family_index[2]] = 'youyuan', 
			     [family_index[3]] = 'fangsong'}
    for v1 in values (family_index) do
	zh_font_model[v1] = {}
	for v2 in values (type_index) do
	    zh_font_model[v1][v2] = zh_default_font[v1]
	end
    end


--    local latin_default_font = {[family_index[1]] = 'texgyrepagella', 
--				[family_index[2]] = 'texgyreheros', 
--				[family_index[3]] = 'texgyrecursor'}
--    for v1 in values (family_index) do
--	latin_font_model[v1] = {}
--	for v2 in values (type_index) do
--	    latin_font_model[v1][v2] = latin_default_font[v1] .. v2
--	end
--    end

    latin_font_model[family_index[1]] = {[type_index[1]]='lmroman12regular',
					 [type_index[2]]='lmroman12bold',
					 [type_index[3]]='lmroman12italic',
					 [type_index[4]]='lmroman10bolditalic'}
    latin_font_model[family_index[2]] = {[type_index[1]]='lmsans12regular',
					 [type_index[2]]='lmsans10bold',
					 [type_index[3]]='lmsans12oblique',
					 [type_index[4]]='lmsans10boldoblique'}
    latin_font_model[family_index[3]] = {[type_index[1]]='lmmono12regular',
					 [type_index[2]]='lmmonolt10bold',
					 [type_index[3]]='lmmono10italic',
					 [type_index[4]]='lmmonolt10boldoblique'}
end

local function verify_font_model ()
    for v1 in values (family_index) do
	if not zh_font_model[v1] or not latin_font_model[v1]  then return false end
	for v2 in values (type_index) do
	    if zh_font_model[v1][v2] == '' or latin_font_model[v1][v2] == ''  then return false end
	end
    end
    return true
end

function zhfonts.gen_text_typescript ()
    local families = {'Serif', 'Sans', 'Mono'}
    local types = {'', 'Bold', 'Italic', 'BoldItalic'}
    local override_area = '[0x00400-0x2FA1F]'

    for family in values (families) do
	local lp1 = string.lower (family)
	context ('\\starttypescript[' .. lp1 .. '][zhfonts]')
	context ('\\setups[font:fallbacks:' .. lp1 .. ']')
	for type in values (types) do
	    local lp2 = string.lower (type)
	    if lp2 == '' then lp2 = 'regular' end
	    context ('\\definefontsynonym[latin' .. family .. type .. ']'
		    .. '[name:' .. latin_font_model[lp1][lp2] .. ']')
	    context ('\\definefontfallback[zh' .. family .. type .. ']'
		    .. '[name:' .. zh_font_model[lp1][lp2] .. ']' .. override_area)
	    context ('\\definefontsynonym[zh' .. family .. type .. 'fallback]'
		       .. '[latin' .. family .. type .. ']'
		       .. '[fallbacks=zh' ..   family .. type .. ']')
	    context ('\\definefontsynonym[' .. family .. type .. '][zh' .. family .. type .. 'fallback]')
	end
	context ('\\stoptypescript')
    end

    context ('\\starttypescript[zhfonts]')
    context ('\\definetypeface[zhfonts][rm][serif][zhfonts][default][features=zh]')
    context ('\\definetypeface[zhfonts][ss][sans][zhfonts][default][features=zh]')
    context ('\\definetypeface[zhfonts][tt][mono][zhfonts][default][features=zh]')
    context ('\\stoptypescript')

    context ('\\usetypescript[zhfonts]')
end

function zhfonts.setup (language, family, types)
    if not verify_font_model () then gen_default_font_model () end
    local model = nil
    local font_array = strsplit (types, ',')

    if language == 'zh' then model = zh_font_model end
    if language == 'latin' then model = latin_font_model end

    for v in values (font_array) do
        local font_item = strsplit (v, '=')
        model[strtrim(family)][strtrim(font_item[1])] = strtrim (font_item[2])
    end
end

function zhfonts.refresh (lang_and_family, types)
    local lft = strsplit (lang_and_family, ',')
    if #lft == 1 then zhfonts.setup ('zh', lft[1], types) end
    if #lft == 2 then 
	local family = nil
	if strtrim (lft[1]) == 'latin' then family = lft[2] end
	if strtrim (lft[2]) == 'latin' then family = lft[1] end
	zhfonts.setup ('latin', family, types) 
    end    
end

local zhfonts_use_count = 1

function zhfonts.use (param)
    if not verify_font_model () then gen_default_font_model () end
    zhfonts.gen_text_typescript ()
    context ('\\setscript[hanzi]')
    dofile (resolvers.findfile ("t-zhspuncs.lua"))

    if zhfonts_use_count == 1 then
     	zhspuncs.opt ()
    end

    context ('\\setupbodyfont[zhfonts, ' .. param .. ']')
    
    zhfonts_use_count = zhfonts_use_count + 1
end
