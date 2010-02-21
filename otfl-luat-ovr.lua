if not modules then modules = { } end modules ['luat-ovr'] = {
    version   = 1.001,
    comment   = "companion to luatex-*.tex",
    author    = "Khaled Hosny and Elie Roux",
    copyright = "Luaotfload Development Team",
    license   = "GPL"
}


local write_nl, format, name = texio.write_nl, string.format, "luaotfload"
local dummyfunction = function() end

callbacks = {
    register      = dummyfunction,
}

function logs.report(category,fmt,...)
    if fmt then
        write_nl('log', format("%s | %s: %s",name,category,format(fmt,...)))
    elseif category then
        write_nl('log', format("%s | %s",name,category))
    else
        write_nl('log', format("%s |",name))
    end
end

function logs.simple(fmt,...)
    if fmt then
        write_nl('log', format("%s | %s",name,format(fmt,...)))
    else
        write_nl('log', format("%s |",name))
    end
end

tex.ctxcatcodes = luatextra.catcodetables.latex