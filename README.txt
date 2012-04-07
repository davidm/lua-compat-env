NAME

  compat_env v$(_VERSION) - Lua 5.1/5.2 environment compatibility functions

SYNOPSIS

  -- Get load/loadfile compatibility functions only if using 5.1.
  local CE = pcall(load, '') and _G or require 'compat_env'
  local load     = CE.load
  local loadfile = CE.loadfile
  
  -- The following now works in both Lua 5.1 and 5.2:
  assert(load('return 2*pi', nil, 't', {pi=math.pi}))()
  assert(loadfile('ex.lua', 't', {print=print}))()
  
  -- Get getfenv/setfenv compatibility functions only if using 5.2.
  local getfenv = _G.getfenv or require 'compat_env'.getfenv
  local setfenv = _G.setfenv or require 'compat_env'.setfenv
  local function f() return x end
  setfenv(f, {x=2})
  print(x, getfenv(f).x) --> 2, 2

DESCRIPTION

  This module provides Lua 5.1/5.2 environment related compatibility functions.
  This includes implementations of Lua 5.2 style `load` and `loadfile`
  for use in Lua 5.1.  It also includes Lua 5.1 style `getfenv` and `setfenv`
  for use in Lua 5.2.
 
API

  local CE = require 'compat_env'
  
  CE.load (ld [, source [, mode [, env] ] ]) --> f [, err]

    This behaves the same as the Lua 5.2 `load` in both
    Lua 5.1 and 5.2.
    http://www.lua.org/manual/5.2/manual.html#pdf-load
    
  CE.loadfile ([filename [, mode [, env] ] ]) --> f [, err]
  
    This behaves the same as the Lua 5.2 `loadfile` in both
    Lua 5.1 and 5.2.
    http://www.lua.org/manual/5.2/manual.html#pdf-loadfile
    
  CE.getfenv ([f]) --> t

    This is identical to the Lua 5.1 `getfenv` in Lua 5.1.
    This behaves similar to the Lua 5.1 `getfenv` in Lua 5.2.
    When a global environment is to be returned, or when `f` is a
    C function, this returns `_G`  since Lua 5.2 doesn't have
    (thread) global and C function environments.  This will also
    return `_G` if the Lua function `f` lacks an `_ENV`
    upvalue, but it will raise an error if uncertain due to lack of
    debug info.  It is not normally considered good design to use
    this function; when possible, use `load` or `loadfile` instead.
    http://www.lua.org/manual/5.1/manual.html#pdf-getfenv
    
  CE.setfenv (f, t)
  
    This is identical to the Lua 5.1 `setfenv` in Lua 5.1.
    This behaves similar to the Lua 5.1 `setfenv` in Lua 5.2.
    This will do nothing if `f` is a Lua function that
    lacks an `_ENV` upvalue, but it will raise an error if uncertain
    due to lack of debug info.  See also Design Notes below.
    It is not normally considered good design to use
    this function; when possible, use `load` or `loadfile` instead.
    http://www.lua.org/manual/5.1/manual.html#pdf-setfenv
    
DESIGN NOTES

  This module intends to provide robust and fairly complete reimplementations
  of the environment related Lua 5.1 and Lua 5.2 functions.
  No effort is made, however, to simulate rare or difficult to simulate features,
  such as thread environments, although this is liable to change in the future.
  Such 5.1 capabilities are discouraged and ideally
  removed from 5.1 code, thereby allowing your code to work in both 5.1 and 5.2.
  
  In Lua 5.2, a `setfenv(f, {})`, where `f` lacks any upvalues, will be silently
  ignored since there is no `_ENV` in this function to write to, and the
  environment will have no effect inside the function anyway.  However,
  this does mean that `getfenv(setfenv(f, t))` does not necessarily equal `t`,
  which is incompatible with 5.1 code (a possible workaround would be [1]).
  If `setfenv(f, {})` has an upvalue but no debug info, then this will raise
  an error to prevent inadvertently executing potentially untrusted code in the
  global environment.
  
  It is not normally considered good design to use `setfenv` and `getfenv`
  (one reason they were removed in 5.2).  When possible, consider replacing
  these with `load` or `loadfile`, which are more restrictive and have native
  implementations in 5.2.
  
  This module might be merged into a more general Lua 5.1/5.2 compatibility
  library (e.g. a full reimplementation of Lua 5.2 `_G`).  However,
  `load/loadfile/getfenv/setfenv` perhaps are among the more cumbersome
  functions not to have.

INSTALLATION

  To install using LuaRocks:
  
    luarocks install compat-env

  Otherwise, download <ttps://github.com/davidm/lua-compat-env>.

  You may simply copy compat_env.lua into your LUA_PATH.
  
  Otherwise:
  
     make test
     make install  (or make install-local)  -- to install into LuaRocks
     make remove  (or make remove-local)  -- to remove from LuaRocks

Related work

  http://lua-users.org/wiki/LuaVersionCompatibility
  https://github.com/stevedonovan/Penlight/blob/master/lua/pl/utils.lua
    - penlight implementations of getfenv/setfenv
  http://lua-users.org/lists/lua-l/2010-06/msg00313.html
    - initial getfenv/setfenv implementation
    
References

  [1] http://lua-users.org/lists/lua-l/2010-06/msg00315.html

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
