-- test.lua - test suite for compat_env module.

-- 'findbin' -- https://github.com/davidm/lua-find-bin
package.preload.findbin = function()
  local M = {_TYPE='module', _NAME='findbin', _VERSION='0.1.1.20120406'}
  local script = arg and arg[0] or ''
  local bin = script:gsub('[/\\]?[^/\\]+$', '') -- remove file name
  if bin == '' then bin = '.' end
  M.bin = bin
  setmetatable(M, {__call = function(_, relpath) return bin .. relpath end})
  return M
end
package.path = require 'findbin' '/lua/?.lua;' .. package.path

local CE = require 'compat_env'
local load     = CE.load
local loadfile = CE.loadfile
local setfenv  = CE.setfenv
local getfenv  = CE.getfenv

local function checkeq(a, b, e)
  if a ~= b then error(
    'not equal ['..tostring(a)..'] ['..tostring(b)..'] ['..tostring(e)..']')
  end
end
local function checkerr(pat, ok, err)
  assert(not ok, 'checkerr')
  assert(type(err) == 'string' and err:match(pat), err)
end

-- test `load`
checkeq(load('return 2')(), 2)
checkerr('expected near', load'return 2 2')
checkerr('text chunk', load('return 2', nil, 'b'))
checkerr('text chunk', load('', nil, 'b'))
checkerr('binary chunk', load('\027', nil, 't'))
checkeq(load('return 2*x',nil,'bt',{x=5})(), 10)
checkeq(debug.getinfo(load('')).source, '')
checkeq(debug.getinfo(load('', 'foo')).source, 'foo')

-- test `loadfile`
local fh = assert(io.open('tmp.lua', 'wb'))
fh:write('return (...) or x')
fh:close()
checkeq(loadfile('tmp.lua')(2), 2)
checkeq(loadfile('tmp.lua', 't')(2), 2)
checkerr('text chunk', loadfile('tmp.lua', 'b'))
checkeq(loadfile('tmp.lua', nil, {x=3})(), 3)
checkeq(debug.getinfo(loadfile('tmp.lua')).source, '@tmp.lua')
checkeq(debug.getinfo(loadfile('tmp.lua', 't', {})).source, '@tmp.lua')
os.remove'tmp.lua'

-- test `setfenv`/`getfenv`
x = 5
local a,b=true; local function f(c) if a then return x,b,c end end
assert(setfenv(f, {x=3}) == f)
checkeq(f(), 3)
checkeq(getfenv(f).x, 3)
checkerr('cannot change', pcall(setfenv, string.len, {})) -- C function
checkeq(getfenv(string.len), _G) -- C function
local function g()
  assert(setfenv(1, {x=4}) == g)
  checkeq(getfenv(1).x, 4)
  return x
end
checkeq(g(), 4) -- numeric level
if _G._VERSION ~= 'Lua 5.1' then
  checkerr('unsupported', pcall(setfenv, 0, {}))
end
checkeq(getfenv(0), _G)
checkeq(getfenv(), _G) -- no arg
checkeq(x, 5) -- main unaltered
setfenv(function()end, {}) -- no upvalues, ignore
checkeq(getfenv(function()end), _G) -- no upvaluse
if _G._VERSION ~= 'Lua 5.1' then
  checkeq(getfenv(setfenv(function()end, {})), _G) -- warning: incompatible with 5.1
end
x = nil

print 'OK'

