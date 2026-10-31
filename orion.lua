--[[----------------------------------------------------------------------------

    Orion — a small, single-file Lua utility toolkit.

    WHAT IT IS
        A drop-in library of everyday helpers: table utilities, string
        trimming/padding, type validation, memoization, an event emitter,
        and a couple of object-oriented building blocks (Date, Cache).

    HOW TO USE
        Put orion.lua next to your script and simply require it:

            local Orion = require("orion")

            local words = Orion.split("a,b,c", ",")      --> {"a", "b", "c"}
            local text  = Orion.join(words, "-")         --> "a-b-c"
            print(Orion.trim("  hello  "))               --> "hello"

        No configuration is required; every function has sensible defaults.
        Run `lua orion.lua` by itself to see the built-in demo.

    CONVENTIONS (standard Lua best practices)
        * The module returns a table and uses NO global variables.
        * Sub-modules (Orion.table, Orion.string, ...) are plain tables with
          static functions ("semi-OOP"), per Programming in Lua, ch. 16.
        * Class-like objects (Date, Cache) use the metatable + __index
          prototype pattern, so they can be subclassed if needed.
        * Errors are raised with `error(msg, level)` pointing at the CALLER's
          line, and every public function validates its arguments up front.
        * Compatible with Lua 5.1 / 5.2 / 5.3 / 5.4 and LuaJIT.

    EXTENDING
        Add pure helpers as fields on the matching sub-table (Orion.table.foo)
        or directly on Orion for cross-cutting ones. Keep argument checks and
        error messages in the same style as the existing functions.

------------------------------------------------------------------------------]]

local Orion = {}

Orion._VERSION = "1.0.0"

-- Small internal aliases, keep the code below tidy and 5.1-compatible.
local type, pairs, ipairs, setmetatable, select =
    type, pairs, ipairs, setmetatable, select

-- Lua 5.1/LuaJIT spell it `unpack`; 5.2+ moved it into the `table` library.
local unpack = table.unpack or unpack


--[[ ==========================  INTERNAL HELPERS  ========================== ]]

--- Raises a standardised argument error pointing at the *caller* of the
--- public function (hence level 3: assert -> argCheck -> public function).
local function argCheck(cond, fmt, ...)
    if not cond then
        error("bad argument: " .. string.format(fmt, ...), 3)
    end
    return cond
end

local function checkTable(v, name)
    return argCheck(type(v) == "table", "%s must be a table, got %s", name, type(v))
end

local function checkString(v, name)
    return argCheck(type(v) == "string", "%s must be a string, got %s", name, type(v))
end

local function checkFunction(v, name)
    return argCheck(type(v) == "function", "%s must be a function, got %s", name, type(v))
end

--- Returns the first non-nil value, or `fallback`. (Lua 5.4 has `<close>`
--- and nil-coalescing idioms; this keeps them unnecessary for us.)
local function defaultTo(value, fallback)
    if value == nil then return fallback end
    return value
end


--[[ ==============================  ORION.TABLE  =========================== ]]
--- Table utilities. All comparison-based functions accept either a
--- comparator function `function(a, b) -> boolean` or `nil` for natural order.

local Table = {}

--- Shallow copy: top-level keys only; nested tables stay shared.
function Table.copy(t)
    checkTable(t, "table")
    local out = {}
    for k, v in pairs(t) do out[k] = v end
    return out
end

--- Deep copy: recursively clones tables and their metatables.
--- Handles cycles via a visited map, so self-referencing tables are safe.
function Table.deepcopy(t, seen)
    checkTable(t, "table")
    seen = seen or {}
    if seen[t] then return seen[t] end
    local out = {}
    seen[t] = out
    for k, v in pairs(t) do
        if type(v) == "table" then
            out[k] = Table.deepcopy(v, seen)
        else
            out[k] = v
        end
    end
    return setmetatable(out, getmetatable(t))
end

--- Fills missing keys in `t` with values from `defaults` (in place).
--- Useful for normalising option tables.
function Table.defaults(t, defaults)
    checkTable(t, "table")
    checkTable(defaults, "defaults")
    for k, v in pairs(defaults) do
        if t[k] == nil then t[k] = v end
    end
    return t
end

--- Inverts keys and values: {a=1} becomes {[1]="a"}.
function Table.invert(t)
    checkTable(t, "table")
    local out = {}
    for k, v in pairs(t) do out[v] = k end
    return out
end

--- Number of entries (`#`-style counts work too, but this also handles
--- hash parts and Lua 5.2+ __len semantics consistently).
function Table.size(t)
    checkTable(t, "table")
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

--- Collect all keys into an array (order unspecified, like pairs()).
function Table.keys(t)
    checkTable(t, "table")
    local out = {}
    for k in pairs(t) do out[#out + 1] = k end
    return out
end

--- Collect all values into an array.
function Table.values(t)
    checkTable(t, "table")
    local out = {}
    for _, v in pairs(t) do out[#out + 1] = v end
    return out
end

--- First value whose predicate accepts it (like PL-Python's next()).
function Table.find(t, predicate)
    checkTable(t, "table")
    checkFunction(predicate, "predicate")
    for k, v in pairs(t) do
        if predicate(v, k) then return v, k end
    end
    return nil
end

--- True when predicate accepts EVERY entry. Empty tables return true.
function Table.every(t, predicate)
    checkTable(t, "table")
    checkFunction(predicate, "predicate")
    for k, v in pairs(t) do
        if not predicate(v, k) then return false end
    end
    return true
end

--- True when predicate accepts AT LEAST ONE entry.
function Table.some(t, predicate)
    checkTable(t, "table")
    checkFunction(predicate, "predicate")
    for k, v in pairs(t) do
        if predicate(v, k) then return true end
    end
    return false
end

--- Map over an array part: returns a new table of transformed values.
function Table.map(t, fn)
    checkTable(t, "table")
    checkFunction(fn, "fn")
    local out = {}
    for i, v in ipairs(t) do out[i] = fn(v, i) end
    return out
end

--- Filter an array part: keeps values for which fn returns truthy.
function Table.filter(t, fn)
    checkTable(t, "table")
    checkFunction(fn, "fn")
    local out = {}
    for i, v in ipairs(t) do
        if fn(v, i) then out[#out + 1] = v end
    end
    return out
end

--- Left fold over the array part. `acc` may be nil (starts at element 1).
function Table.reduce(t, fn, acc)
    checkTable(t, "table")
    checkFunction(fn, "fn")
    local start = 1
    if acc == nil then
        argCheck(#t > 0, "cannot reduce an empty table without an initial accumulator")
        acc, start = t[1], 2
    end
    for i = start, #t do acc = fn(acc, t[i], i) end
    return acc
end

--- Reverse an array (non-mutating).
function Table.reverse(t)
    checkTable(t, "table")
    local out = {}
    local n = #t
    for i = 1, n do out[i] = t[n - i + 1] end
    return out
end

--- Remove duplicate values, keeping first occurrences (array part).
function Table.dedupe(t)
    checkTable(t, "table")
    local seen, out = {}, {}
    for _, v in ipairs(t) do
        if not seen[v] then
            seen[v] = true
            out[#out + 1] = v
        end
    end
    return out
end

--- Group array values into buckets keyed by fn(value) -> key.
function Table.groupBy(t, fn)
    checkTable(t, "table")
    checkFunction(fn, "fn")
    local out = {}
    for _, v in ipairs(t) do
        local key = fn(v)
        out[key] = out[key] or {}
        out[key][#out[key] + 1] = v
    end
    return out
end

--- Merge several arrays/tables into a fresh one (later keys win).
function Table.merge(...)
    local out = {}
    for _, t in ipairs({ ... }) do
        checkTable(t, "table to merge")
        for k, v in pairs(t) do out[k] = v end
    end
    return out
end

--- Sorted shallow copy of the array part (uses table.sort internally).
function Table.sort(t, comparator)
    checkTable(t, "table")
    argCheck(comparator == nil or type(comparator) == "function",
        "comparator must be a function or nil, got %s", type(comparator))
    local out = Table.copy(t)
    table.sort(out, comparator)
    return out
end


--[[ =============================  ORION.STRING  =========================== ]]

local Str = {}

--- Split a string by a plain separator (not a Lua pattern).
--- Empty input yields an empty list; empty pieces are dropped unless
--- keepEmpty is true.
function Str.split(text, sep, keepEmpty)
    checkString(text, "text")
    sep = defaultTo(sep, ",")
    argCheck(type(sep) == "string" and #sep > 0,
        "sep must be a non-empty string, got %s", type(sep))
    if text == "" then return {} end

    -- Plain-text search (init=true): the separator is matched literally,
    -- so users can pass "," "." "|" or even "::" without escaping worries.
    local out, pos = {}, 1
    while true do
        local s = text:find(sep, pos, true)
        if not s then
            local piece = text:sub(pos)
            if piece ~= "" or keepEmpty then out[#out + 1] = piece end
            break
        end
        local piece = text:sub(pos, s - 1)
        if piece ~= "" or keepEmpty then out[#out + 1] = piece end
        pos = s + #sep
    end
    return out
end

--- Join array values with a separator (numbers/booleans are stringified).
function Str.join(values, sep)
    checkTable(values, "values")
    sep = defaultTo(sep, "")
    checkString(sep, "sep")
    local parts = {}
    for i, v in ipairs(values) do
        argCheck(type(v) == "string" or type(v) == "number" or type(v) == "boolean",
            "value at index %d must be string/number/boolean, got %s", i, type(v))
        parts[i] = tostring(v)
    end
    return table.concat(parts, sep)
end

--- Trim whitespace (or a custom character class, e.g. "abc" or "%s") from
--- both ends. The whole charset is treated as one Lua pattern class.
function Str.trim(text, charset)
    checkString(text, "text")
    local class = "[" .. (charset or "%s") .. "]"
    return (text:gsub("^" .. class .. "+", ""):gsub(class .. "+$", ""))
end

--- Left-trim only.
function Str.ltrim(text, charset)
    checkString(text, "text")
    local class = "[" .. (charset or "%s") .. "]"
    return (text:gsub("^" .. class .. "+", ""))
end

--- Right-trim only.
function Str.rtrim(text, charset)
    checkString(text, "text")
    local class = "[" .. (charset or "%s") .. "]"
    return (text:gsub(class .. "+$", ""))
end

--- Case conversion that works on Lua 5.1..5.4 (str:upper/lower are native).
function Str.upper(text)
    checkString(text, "text")
    return text:upper()
end

function Str.lower(text)
    checkString(text, "text")
    return text:lower()
end

--- "some_name here" -> "Some Name Here"
function Str.capitalize(text)
    checkString(text, "text")
    return (text:gsub("(%a)([%w_']*)",
        function(first, rest) return first:upper() .. rest:lower() end))
end

--- Pad to width with `char` (single byte). side: "left"|"right"|"center".
function Str.pad(text, width, char, side)
    checkString(text, "text")
    argCheck(type(width) == "number" and width >= 0,
        "width must be a non-negative number, got %s", tostring(width))
    char = defaultTo(char, " ")
    argCheck(#char == 1, "pad char must be exactly one character, got %q", char)
    side = defaultTo(side, "left")
    argCheck(side == "left" or side == "right" or side == "center",
        "side must be 'left', 'right' or 'center', got %q", side)

    local deficit = width - #text
    if deficit <= 0 then return text end
    if side == "left" then
        return char:rep(deficit) .. text
    elseif side == "right" then
        return text .. char:rep(deficit)
    else -- center: extra space goes on the right
        local left = math.floor(deficit / 2)
        return char:rep(left) .. text .. char:rep(deficit - left)
    end
end

--- Truncate with an ellipsis marker (never longer than width + marker).
function Str.truncate(text, width, marker)
    checkString(text, "text")
    width = defaultTo(width, 80)
    marker = defaultTo(marker, "...")
    argCheck(type(width) == "number" and width >= #marker,
        "width must be at least the marker length (%d)", #marker)
    if #text <= width then return text end
    return text:sub(1, width - #marker) .. marker
end

--- Escape Lua-pattern magic characters so user input can be matched
--- literally, e.g. text:find(Orion.string.escape(userInput))
function Str.escape(text)
    checkString(text, "text")
    return (text:gsub("[^%w]", "%%%0")) -- prefix every non-alphanumeric byte
end

--- Does `text` start/end with the literal prefix/suffix?
function Str.starts(text, prefix)
    checkString(text, "text")
    checkString(prefix, "prefix")
    return text:sub(1, #prefix) == prefix
end

function Str.ends(text, suffix)
    checkString(text, "text")
    checkString(suffix, "suffix")
    return suffix == "" or text:sub(-#suffix) == suffix
end

--- Repeat a string n times. NOTE: `repeat` is a reserved word in Lua, so
--- this lives as the string key Str["repeat"] (call it as Orion.string["repeat"](…)).
Str["repeat"] = function(text, n)
    checkString(text, "text")
    argCheck(type(n) == "number" and n >= 0, "n must be a non-negative number")
    return text:rep(n)
end


--[[ ============================  ORION.FUNCTION  ========================== ]]

local Fn = {}

--- Wrap `fn` so its result is computed only once, ever.
function Fn.memoize(fn)
    checkFunction(fn, "fn")
    local done, result = false, nil
    return function(...)
        if not done then
            done = true
            result = fn(...)
        end
        return result
    end
end

--- Memoise by the first argument only (cheap cache for unary-ish calls).
function Fn.memoizeKeyed(fn)
    checkFunction(fn, "fn")
    local cache = setmetatable({}, { __mode = "k" }) -- weak keys: no leaks
    return function(key, ...)
        if cache[key] == nil then
            cache[key] = fn(key, ...)
        end
        return cache[key]
    end
end

--- Compose functions right-to-left: compose(f, g, h)(x) == f(g(h(x)))
function Fn.compose(...)
    local fs = { ... }
    for i, f in ipairs(fs) do
        checkFunction(f, "function at index " .. i)
    end
    return function(...)
        local args = { ... }
        for i = #fs, 1, -1 do
            args = { fs[i](unpack(args)) }
        end
        return unpack(args)
    end
end

--- Curry a binary function: add(2)(3) == 5
function Fn.curry2(fn)
    checkFunction(fn, "fn")
    return function(a)
        return function(b) return fn(a, b) end
    end
end

--- Call `fn` only the first time the returned closure is invoked.
function Fn.once(fn)
    checkFunction(fn, "fn")
    local called = false
    return function(...)
        if called then return nil end
        called = true
        return fn(...)
    end
end


--[[ ==============================  ORION.EVENT  =========================== ]]
--- Minimal publish/subscribe emitter. Listeners receive (data, name).
--- Handlers are stored by insertion order; removal during iteration is safe
--- because emit() iterates over a snapshot copy.

local Event = {}
Event.__index = Event

--- Create a new emitter instance.
function Event.new()
    return setmetatable({ _handlers = {} }, Event)
end

--- Subscribe; returns a token usable with off().
function Event:on(name, handler)
    checkString(name, "event name")
    checkFunction(handler, "handler")
    local list = self._handlers[name]
    if not list then
        list = {}
        self._handlers[name] = list
    end
    list[#list + 1] = handler
    return handler -- token
end

--- Unsubscribe a previously returned token.
function Event:off(name, handler)
    checkString(name, "event name")
    local list = self._handlers[name]
    if not list then return false end
    for i = #list, 1, -1 do
        if list[i] == handler then
            table.remove(list, i)
            return true
        end
    end
    return false
end

--- Fire an event; returns number of listeners called.
function Event:emit(name, data)
    checkString(name, "event name")
    local list = self._handlers[name]
    if not list or #list == 0 then return 0 end
    local count = 0
    local snapshot = Table.copy(list) -- safe against on/off during emit
    for _, handler in ipairs(snapshot) do
        handler(data, name)
        count = count + 1
    end
    return count
end

--- Remove every listener for a name (or all names if omitted).
function Event:clear(name)
    if name == nil then
        self._handlers = {}
    else
        checkString(name, "event name")
        self._handlers[name] = nil
    end
end


--[[ ===============================  ORION.CACHE  ========================== ]]
--- A tiny LRU (least-recently-used) cache with a fixed capacity.
--- Eviction is O(capacity); good enough for typical helper-library sizes.

local Cache = {}
Cache.__index = Cache

function Cache.new(capacity)
    capacity = defaultTo(capacity, 128)
    argCheck(type(capacity) == "number" and capacity >= 1 and capacity == math.floor(capacity),
        "capacity must be a positive integer, got %s", tostring(capacity))
    return setmetatable({ _cap = capacity, _map = {}, _order = {} }, Cache)
end

local function orderRemove(self, key)
    for i, k in ipairs(self._order) do
        if k == key then
            table.remove(self._order, i)
            return
        end
    end
end

function Cache:get(key)
    argCheck(key ~= nil, "key must not be nil")
    local hit = self._map[key]
    if hit == nil then return nil end
    -- refresh recency
    orderRemove(self, key)
    self._order[#self._order + 1] = key
    return hit
end

function Cache:set(key, value)
    argCheck(key ~= nil, "key must not be nil")
    if value == nil then
        return self:delete(key)
    end
    if self._map[key] == nil then
        -- New key: maybe evict the least-recently-used entry first.
        if Table.size(self._map) >= self._cap and #self._order > 0 then
            local oldest = table.remove(self._order, 1)
            self._map[oldest] = nil
        end
    else
        orderRemove(self, key)
    end
    self._map[key] = value
    self._order[#self._order + 1] = key
end

function Cache:delete(key)
    argCheck(key ~= nil, "key must not be nil")
    local had = self._map[key] ~= nil
    self._map[key] = nil
    orderRemove(self, key)
    return had
end

function Cache:clear()
    self._map, self._order = {}, {}
end

function Cache:size()
    return Table.size(self._map)
end


--[[ ===============================  ORION.DATE  =========================== ]]
--- Thin convenience wrapper around os.time/os.date. Accepts a timestamp
--- (seconds) or nothing (= now). Month names are English.

local MONTHS = { "Jan", "Feb", "Mar", "Apr", "May", "Jun",
                 "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }

local Date = {}
Date.__index = Date

function Date.new(timestamp)
    argCheck(timestamp == nil or type(timestamp) == "number",
        "timestamp must be a number or nil, got %s", type(timestamp))
    return setmetatable({ _time = defaultTo(timestamp, os.time()) }, Date)
end

--- Parse "YYYY-MM-DD" into a Date (UTC-ish; uses local midnight).
function Date.parse(text)
    checkString(text, "date string")
    local y, m, d = text:match("^(%d%d%d%d)%-(%d%d?)%-(%d%d?)$")
    argCheck(y, "expected format YYYY-MM-DD, got %q", text)
    local t = os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d),
                        hour = 12 }) -- noon avoids DST edge cases
    return Date.new(t)
end

function Date:timestamp() return self._time end
function Date:year()   return tonumber(os.date("%Y", self._time)) end
function Date:month()  return tonumber(os.date("%m", self._time)) end
function Date:day()    return tonumber(os.date("%d", self._time)) end
function Date:hour()   return tonumber(os.date("%H", self._time)) end

--- Add days (fractional allowed) and return a NEW Date (immutable style).
function Date:addDays(days)
    argCheck(type(days) == "number", "days must be a number, got %s", type(days))
    return Date.new(self._time + days * 86400)
end

function Date:addSeconds(seconds)
    argCheck(type(seconds) == "number", "seconds must be a number")
    return Date.new(self._time + seconds)
end

--- Whole-day difference between two dates (b - a), ignoring clock drift.
function Date.diffDays(a, b)
    argCheck(getmetatable(a) == Date, "a must be an Orion.Date")
    argCheck(getmetatable(b) == Date, "b must be an Orion.Date")
    return math.floor((b._time - a._time) / 86400 + 0.5)
end

--- Format tokens: %Y %m %d %H %M %S and {Mon} (month name). Everything else
--- passes through to os.date.
function Date:format(pattern)
    pattern = defaultTo(pattern, "%Y-%m-%d")
    checkString(pattern, "pattern")
    local out = pattern:gsub("{Mon}", MONTHS[self:month()])
    return os.date(out, self._time)
end

function Date:__tostring()
    return self:format("%Y-%m-%d %H:%M:%S")
end

function Date:__eq(other)
    -- Guard against comparing against non-Date values.
    if getmetatable(other) ~= Date then return false end
    return self._time == other._time
end

function Date:__lt(other)
    return self._time < other._time
end


--[[ ============================  TOP-LEVEL EXPORTS  ======================= ]]

--- Validate a value's type; raises a clear error otherwise.
--- Usage: Orion.checkType(name, value, "string")
function Orion.checkType(name, value, expected)
    checkString(expected, "expected type")
    if type(value) ~= expected then
        error(string.format("%s must be %s, got %s", name, expected, type(value)), 2)
    end
    return value
end

--- Assert-style guard with a custom message.
function Orion.assert(cond, message)
    if not cond then
        error(message or "assertion failed", 2)
    end
    return cond
end

--- Safe pcall returning (ok, value-or-error-message-as-string).
function Orion.try(fn, ...)
    checkFunction(fn, "fn")
    local ok, err = pcall(fn, ...)
    if ok then return true, err end
    return false, tostring(err)
end

--- Attach defaults to an options table in place (shallow).
function Orion.options(opts, defaults)
    return Table.defaults(opts, defaults)
end

-- Expose the namespaces and classes on the module table.
Orion.table    = Table
Orion.string   = Str
Orion.fn       = Fn
Orion.Event    = Event
Orion.Cache    = Cache
Orion.Date     = Date

-- Convenience re-exports of the most-used helpers at the top level, so
-- common calls read nicely: Orion.split(...) instead of Orion.string.split(...)
Orion.split       = Str.split
Orion.join        = Str.join
Orion.trim        = Str.trim
Orion.pad         = Str.pad
Orion.truncate    = Str.truncate
Orion.capitalize  = Str.capitalize
Orion.copy        = Table.copy
Orion.deepcopy    = Table.deepcopy
Orion.map         = Table.map
Orion.filter      = Table.filter
Orion.reduce      = Table.reduce
Orion.memoize     = Fn.memoize


--[[ ================================  DEMO  ================================ ]]
--- Runs when the file is executed directly (`lua orion.lua`).
--- When the file is merely required, this block is skipped.

local function runDemo()
    print("Orion v" .. Orion._VERSION .. " - quick demo\n")

    -- Strings
    local csv = Orion.split("apple, banana,,cherry", ",")
    print("split csv        :", Orion.join(csv, " | "))
    print("trim             :", string.format("[%s]", Orion.trim("   padded   ")))
    print("pad              :", Orion.pad("7", 5, "0", "left"))
    print("capitalize       :", Orion.capitalize("hello WORLD again"))
    print("truncate         :", Orion.truncate("a longer sentence here", 12))

    -- Tables
    local nums = { 5, 3, 9, 3, 1 }
    print("sorted unique    :", Orion.join(Table.sort(Table.dedupe(nums)), ","))
    print("reversed         :", Orion.join(Table.reverse(nums), ","))
    print("evens            :", Orion.join(Orion.filter(nums, function(n)
        return n % 2 == 0
    end), ","))
    print("doubled          :", Orion.join(Orion.map(nums, function(n)
        return n * 2
    end), ","))
    print("sum              :", Orion.reduce(nums, function(a, b) return a + b end))
    local grouped = Table.groupBy({ "cat", "cow", "dog" },
        function(w) return w:sub(1, 1) end)
    print("grouped by first :", Table.size(grouped), "buckets for c,c,d")

    -- Functions
    local square = Fn.memoizeKeyed(function(x)
        print("   (computing square of " .. x .. ")")
        return x * x
    end)
    print("memoized squares :", square(9), square(9)) -- second call is cached
    local addThenShow = Fn.compose(Str.upper, Str.trim)
    print("composed fn      :", addThenShow("  hi there  "))

    -- Events
    local bus = Orion.Event.new()
    local token = bus:on("greet", function(data) print("   heard:", data) end)
    bus:emit("greet", "hello there")
    bus:off("greet", token)
    print("after off(), emits reach:", bus:emit("greet", "ignored"), "listeners")

    -- Cache (LRU)
    local cache = Orion.Cache.new(2)
    cache:set("a", 1)
    cache:set("b", 2)
    cache:get("a")    -- makes "a" most-recent again
    cache:set("c", 3) -- evicts "b"
    print("cache a/c/b    :", cache:get("a"), cache:get("c"), cache:get("b"))

    -- Dates
    local today  = Orion.Date.new()
    local parsed = Orion.Date.parse("2026-11-01")
    print("today          :", tostring(today))
    print("parsed         :", tostring(parsed))
    print("in 10 days     :", tostring(today:addDays(10)))

    -- Error handling
    local ok, err = Orion.try(function()
        Orion.checkType("port", "not-a-number", "number")
    end)
    print("try() caught   :", ok, "->", err)

    print("\nAll demos completed without errors.")
end

-- Decide whether this chunk is the *main* script (run with `lua orion.lua`)
-- or was pulled in via require()/dofile(). Standard trick: under the stock
-- interpreter the main chunk's short source equals "@" .. arg[0].
local function isMainChunk()
    if not (arg and debug and debug.getinfo) then return false end
    -- Level 2 = the chunk that contains the `if isMainChunk()` call below.
    -- When required, that chunk is orion.lua but arg[0] is the caller's
    -- script; when run directly they are the same file.
    local src = debug.getinfo(2, "S")
    if not src then return false end
    local path = src.source:gsub("^@", "")
    -- Compare basenames so "./orion.lua" matches "orion.lua".
    local function base(p) return p:match("([^/\\]+)$") or p end
    return base(path) == base(arg[0] or "")
end

if isMainChunk() then
    runDemo()
end

return Orion
