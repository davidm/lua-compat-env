--[[

  compat_load v$(_VERSION) - Lua 5.2 compatable load/loadfile for Lua 5.1

SYNOPSIS

  -- If you wish to avoid dependence on this module in Lua 5.2, do this:
  local CL = pcall(load, '') and _G or require 'compat_load'
  local load     = CL.load
  local loadfile = CL.loadfile
  
  -- The following now works in both Lua 5.1 and 5.2:
  assert(load('return 2*pi', nil, 't', {pi=math.pi}))()
  assert(loadfile('ex.lua', 't', {print=print}))()

DESCRIPTION

  This module provides Lua 5.2 compatible `load` and `loadfile` functions
  for use in Lua 5.1.
 
API

  local CL = require 'compat_load'
  
  CL.load (ld [, source [, mode [, env] ] ]) --> f [, err]

    This behaves the same as `load` in Lua 5.2
    http://www.lua.org/manual/5.2/manual.html#pdf-load
    
  loadfile ([filename [, mode [, env] ] ]) --> f [, err]
  
    This behaves the same as `loadfile` in Lua 5.2
    http://www.lua.org/manual/5.2/manual.html#pdf-loadfile
    
DESIGN NOTES

  This module intends to provide very complete and robust reimplementations
  of the Lua 5.2 functions.
  
  This module might be merged into a more general Lua 5.2 compatibility
  library (e.g. a full reimplementation of Lua 5.2 `_G`).  However,
  `load/loadfile` perhaps are among the more cumbersome functions not
  to have.

INSTALLATION

  Download compat_load.lua:
  
    wget https://raw.github.com/gist/1654007/compat_load.lua

  Copy compat_load.lua into your LUA_PATH.
  
  Alternately, unpack, test, and install into LuaRocks:
  
     wget https://raw.github.com/gist/1422205/sourceunpack.lua
     lua sourceunpack.lua compat_load.lua
     (cd out && luarocks make)

Related work

  http://lua-users.org/wiki/LuaVersionCompatibility

Copyright

(c) 2012 David Manura.  Licensed under the same terms as Lua 5.1/5.2 (MIT license).

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

--]]---------------------------------------------------------------------

local M = {_TYPE='module', _NAME='compat_load', _VERSION='0.1.20120121'}

local function check_chunk_type(s, mode)
  local nmode = mode or 'bt' 
  local is_binary = s and #s > 0 and s:byte(1) == 27
  if is_binary and not nmode:match'b' then
    return nil, ("attempt to load a binary chunk (mode is '%s')"):format(mode)
  elseif not is_binary and not nmode:match't' then
    return nil, ("attempt to load a text chunk (mode is '%s')"):format(mode)
  end
  return true
end

local function compat_load(ld, source, mode, env)
  local f
  if type(ld) == 'string' then
    local s = ld
    local ok, err = check_chunk_type(s, mode); if not ok then return ok, err end
    local err; f, err = loadstring(s, source); if not f then return f, err end
  elseif type(ld) == 'function' then
    local ld2 = ld
    if (mode or 'bt') ~= 'bt' then
      local first = ld()
      local ok, err = check_chunk_type(first, mode); if not ok then return ok, err end
      ld2 = function()
        if first then
          local chunk=first; first=nil; return chunk
        else return ld() end
      end
    end
    local err; f, err = load(ld2, source); if not f then return f, err end
  else
    error(("bad argument #1 to 'load' (function expected, got %s)"):format(type(ld)), 2)
  end
  if env then setfenv(f, env) end
  return f
end

local function compat_loadfile(filename, mode, env)
  if (mode or 'bt') ~= 'bt' then
    local ioerr
    local fh, err = io.open(filename, 'rb'); if not fh then return fh, err end
    local function ld() local chunk; chunk,ioerr = fh:read(4096); return chunk end
    local f, err = M.load(ld, filename and '@'..filename, mode, env)
    fh:close()
    if not f then return f, err end
    if ioerr then return nil, ioerr end
    return f
  else
    local f, err = loadfile(filename); if not f then return f, err end
    if env then setfenv(f, env) end
    return f
  end
end

local IS_52_LOAD = pcall(load, '')
M.load     = IS_52_LOAD and _G.load     or compat_load
M.loadfile = IS_52_LOAD and _G.loadfile or compat_loadfile

return M

--[[ FILE rockspec.in

package = 'compat_load'
version = '$(_VERSION)-1'
source = {
  url = 'https://raw.github.com/gist/1654007/$(GITID)/compat_load.lua',
  --url = 'https://raw.github.com/gist/1654007/compat_load.lua', -- latest raw
  --url = 'https://gist.github.com/gists/1654007/download',
  md5 = '$(MD5)'
}
description = {
  summary = 'Lua 5.2 compatable load/loadfile for Lua 5.1',
  detailed =
    'Provides Lua 5.2 compatible `load` and `loadfile` functions for use in Lua 5.1.',
  license = 'MIT/X11',
  homepage = 'https://gist.github.com/1654007',
  maintainer = 'David Manura'
}
dependencies = {}
build = {
  type = 'builtin',
  modules = {
    ['compat_load'] = 'compat_load.lua'
  }
}

--]]---------------------------------------------------------------------

--[[ FILE test.lua

-- test.lua - test suite for compat_load module.

local CL = require 'compat_load'
local load     = CL.load
local loadfile = CL.loadfile

local function checkeq(a, b, e)
  if a ~= b then error(
    'not equal ['..tostring(a)..'] ['..tostring(b)..'] ['..tostring(e)..']')
  end
end
local function checkerr(pat, ok, err)
  assert(not ok)
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

print 'OK'

--]]---------------------------------------------------------------------

--[[ FILE CHANGES.txt
0.1.20120121
  Initial public release
--]]

