--[[
  QoL Item - main.lua

  このMODには4種類のアイテムが入っている。Luaを使うのは次の2つ。
  (This mod has four kinds of items; only the first two use Lua.)
    1. 縄梯子（Rope Ladder）           … 「縁から垂らす」
    2. 自作ウォーターサーバー（Liquid Grid Water Dispenser） … 設置・補充・調べる
  （3. 間に合せの包帯・間に合せの消毒、4. 折りたたみレーザータレット は JSON だけで動くので、ここには何もない）
  (Items 3 and 4 are JSON-only, so there is no Lua for them here.)

  それぞれ do ... end で囲み、ローカル変数が混ざらないようにしている。

  Assisted-by: Claude:claude-opus-5-5
]]

gdebug.log_info("QOL: main.")

----------------------------------------------------------------------
-- 1. 縄梯子
----------------------------------------------------------------------
do
--[[
  Rope Ladder - main.lua

  縄梯子を「段差の縁から下の階へ垂らす」処理。長さは最大 mod.cfg.max_levels 階分。

  本体(BN)の仕組みをそのまま使っている部分:
    * 1階分だけのときは家具 f_rl_rope_ladder（furniture.json）
      - LADDER            … このマスから上の階へ登れる／上の階からこのマスへ降りられる
      - REMOVE_FROM_ABOVE … 上の階で縁を調べると「引き上げる」で回収できる
      - deployed_furniture … このマスで調べると「片付ける」で回収できる
    * 「ここに設置する」… 自分と同じ高さの隣のマスに掛ける（下から1階分登るとき）。
      本体の deploy_furn と同じ置き方だが、そのマスが空中なら宙づりで掛ける
      （上の縁に投げて引っ掛けるイメージ。deploy_furn だと家具が下へ落ちて壊れる）。
      (Set it up on an adjacent tile at your level; if that tile is open air,
       it hangs there instead of falling like deploy_furn would.)

  このファイルが足すもの:
    * 「縁から垂らす」… 隣の床のないマス（段差の縁）を選ぶと、その真下に縄梯子を掛ける。
      地面に着くか、max_levels 階分になるまで下へ伸ばす。
    * 2階分以上のとき … 各階に「区間」の家具を置き、本体の階段と同じ GOES_DOWN / GOES_UP で
      つなぐ（> と < で区間を上り下りできる）。
        いちばん上 f_rl_rope_ladder_top    … LADDER + GOES_DOWN（縁からの出入り・回収はここ）
        途中       f_rl_rope_ladder_mid    … GOES_UP + GOES_DOWN
        いちばん下 f_rl_rope_ladder_bottom … GOES_UP
    * 宙づり … 空中の階では、そのマスの地形を「縄梯子のぶら下がった空中」
      （t_rl_hanging_air、足場になる）に変えてから家具を置く。
      本体では空中に家具を置けない（下へ落ちる）ため、足場の地形でつり下げている。
    * 後片付け … 回収・破壊で区間がなくなったら、毎ターンの見回りで
      それより下の区間を外し、足場を元の空中に戻す（回収で手に入る縄梯子は1つ）。

  使用アクションの戻り値は「消費数」。1 を返すとアイテムが取り除かれる。
  （アイテムは TOOL で DESTROY_ON_DECHARGE を持つので、本体が使用後に自動で取り除く）
  (The item is a TOOL with DESTROY_ON_DECHARGE, so returning 1 removes it.)
  失敗時は必ず 0 を返し、アイテムを失わないようにしている。
]]

gdebug.log_info("RL: main.")

local mod = game.mod_runtime[game.current_mod]
local storage = game.mod_storage[game.current_mod]

----------------------------------------------------------------------
-- 設定
----------------------------------------------------------------------

mod.cfg = {
  -- 垂らすのにかかる移動力（100 = 1秒）。1階分あたり
  move_cost = 300,

  -- 縁から垂らしたときに届く最大の階数
  -- (Max levels when lowered from a ledge.)
  -- 3階分では落下して壊れる不具合があったため、安定している1階分に戻した。
  -- (Reverted to 1: lowering 3 levels made the ladder fall and break.)
  max_levels = 1,

  -- 地面に届かなくても垂らせる（宙づり）
  -- (Allow dangling when it doesn't reach the ground.)
  allow_hanging = true,

  -- 詳細をデバッグログに出す
  debug = false,
}

----------------------------------------------------------------------
-- 定数・補助関数
----------------------------------------------------------------------

-- 1階分だけのとき
local FURN_ID = "f_rl_rope_ladder"
-- 2階分以上のときの区間
local FURN_TOP = "f_rl_rope_ladder_top"
local FURN_MID = "f_rl_rope_ladder_mid"
local FURN_BOTTOM = "f_rl_rope_ladder_bottom"
-- 宙づりの区間の足場にする地形
local HANG_TER = "t_rl_hanging_air"
-- 宙づりにしてよい空中の地形（屋根の下の空中も含む）
local AIR_TERS = { t_open_air = true, t_open_air_rooved = true }

local function log(fmt, ...)
  if mod.cfg.debug then
    gdebug.log_info("RL: " .. string.format(fmt, ...))
  end
end

local function msg(text, ...)
  if select("#", ...) > 0 then
    text = string.format(text, ...)
  end
  gapi.add_msg(text)
end

local function furn_str_at(map, pos)
  local ok, id = pcall(function()
    return map:get_furn_at(pos):str_id():str()
  end)
  if not ok then
    return nil
  end
  return id
end

local function ter_str_at(map, pos)
  local ok, id = pcall(function()
    return map:get_ter_at(pos):str_id():str()
  end)
  if not ok then
    return nil
  end
  return id
end

local function set_ter(map, pos, ter_str)
  map:set_ter_at(pos, TerId.new(ter_str):int_id())
end

local function set_furn(map, pos, furn_str)
  map:set_furn_at(pos, FurnId.new(furn_str):int_id())
end

local function in_bounds(map, p)
  local size = map:get_map_size()
  return p.x >= 0 and p.y >= 0 and p.x < size and p.y < size
end

local function key_of(a)
  return a.x .. "," .. a.y .. "," .. a.z
end

-- 区間の家具（n 区間のうち i 番目。上から 1, 2, ...）
local function furn_for(i, n)
  if n == 1 then return FURN_ID end
  if i == 1 then return FURN_TOP end
  if i == n then return FURN_BOTTOM end
  return FURN_MID
end

--[[
  見回りが必要な縄梯子の記録（セーブに残る）。キーはいちばん上の区間の絶対座標。
    { segs = { { x, y, z, furn = 置いた家具, ter = 元の地形（宙づりのときだけ） }, ... } }
  1階分で地面に着いているものは本体だけで完結するので記録しない。
]]
local function ladder_list()
  storage.rl_ladders = storage.rl_ladders or {}
  -- 前の版（宙づり1階分だけ）の記録を引き継ぐ
  if storage.rl_hanging then
    for k, a in pairs(storage.rl_hanging) do
      storage.rl_ladders[k] = { segs = { { x = a.x, y = a.y, z = a.z, furn = FURN_ID, ter = a.ter } } }
    end
    storage.rl_hanging = nil
  end
  return storage.rl_ladders
end

-- 1マスを調べる。
-- 戻り値：駄目な理由（nil なら置ける）、宙づりになるか
local function check_tile(map, p)
  local hanging = false
  if map:has_ter_flag_at("NO_FLOOR", p) then
    -- 空中：宙づりにする（ただの空中のときだけ）
    if not mod.cfg.allow_hanging or not AIR_TERS[ter_str_at(map, p) or ""] then
      return locale.gettext("It's too far down for the rope ladder."), false
    end
    hanging = true
  else
    if map:has_ter_flag_at("DEEP_WATER", p) then
      return locale.gettext("You can't hang it into deep water."), false
    end
    -- 壁や機械などの通れない地形（ほぼ全てが WALL か NOITEM を持つ）
    if map:has_ter_flag_at("WALL", p) or map:has_ter_flag_at("NOITEM", p) then
      return locale.gettext("There is no room to hang it there."), false
    end
  end
  local furn = furn_str_at(map, p)
  if furn == nil or (furn ~= "f_null" and furn ~= "") then
    return locale.gettext("There is no room to hang it there."), false
  end
  if gapi.get_creature_at(p) then
    return locale.gettext("There is no room to hang it there."), false
  end
  return nil, hanging
end

--[[
  縁 target の真下に、掛けられる区間を上から順に決める。
  地面（床のあるマス）に着いたらそこで終わり。途中で掛けられないマスがあれば、その上で止める。
  戻り値：区間の一覧 { { p, hanging }, ... }（空なら、1階目から掛けられない理由も返す）
]]
local function plan_segments(map, target)
  local segs = {}
  for i = 1, math.max(1, mod.cfg.max_levels) do
    local p = TripointBubMs.new(target.x, target.y, target.z - i)
    local problem, hanging = check_tile(map, p)
    if problem then
      if i == 1 then return segs, problem end
      break
    end
    segs[#segs + 1] = { p = p, hanging = hanging }
    if not hanging then break end -- 地面に着いた
  end
  return segs, nil
end

-- 区間を取り外す（家具を消し、宙づりの足場を元の地形に戻す）
local function remove_segment(map, p, seg)
  if furn_str_at(map, p) == seg.furn then
    set_furn(map, p, "f_null")
  end
  if seg.ter and ter_str_at(map, p) == HANG_TER then
    set_ter(map, p, seg.ter)
  end
end

----------------------------------------------------------------------
-- 本体
----------------------------------------------------------------------

local function lower(params)
  local u = params.user
  if not u then
    return 0
  end
  if u:is_mounted() then
    msg(locale.gettext("You cannot do that while mounted."))
    return 0
  end

  local target = gapi.choose_adjacent(locale.gettext("Lower the rope ladder where?"), false)
  if not target then
    return 0
  end

  local map = gapi.get_map()
  if not map:has_ter_flag_at("NO_FLOOR", target) then
    msg(locale.gettext("There is no drop there.  To use it on level ground, choose \"Set it up here\" instead."))
    return 0
  end

  local plan, problem = plan_segments(map, target)
  if #plan == 0 then
    msg(problem)
    log("refused: %s", problem)
    return 0
  end

  -- 上から順に置く。宙づりの区間は、先に足場の地形にしておく（空中のままだと家具が下へ落ちる）
  local n = #plan
  local placed = {}
  for i, s in ipairs(plan) do
    local seg = { furn = furn_for(i, n) }
    if s.hanging then
      seg.ter = ter_str_at(map, s.p)
      set_ter(map, s.p, HANG_TER)
    end
    set_furn(map, s.p, seg.furn)
    placed[#placed + 1] = { p = s.p, seg = seg }

    -- 念のため、実際に置けたかを確認する。駄目なら全部元に戻して何も消費しない
    if furn_str_at(map, s.p) ~= seg.furn then
      for _, done in ipairs(placed) do
        remove_segment(map, done.p, done.seg)
      end
      msg(locale.gettext("There is no room to hang it there."))
      log("set_furn_at did not take effect")
      return 0
    end
  end

  -- 見回りが要るもの（2階分以上か、宙づり）を記録する
  local bottom_hanging = plan[n].hanging
  if n > 1 or bottom_hanging then
    local segs = {}
    for _, done in ipairs(placed) do
      local a = map:bub_to_abs(done.p)
      segs[#segs + 1] = { x = a.x, y = a.y, z = a.z, furn = done.seg.furn, ter = done.seg.ter }
    end
    ladder_list()[key_of(segs[1])] = { segs = segs }
  end

  u:mod_moves(-mod.cfg.move_cost * n)
  if bottom_hanging then
    msg(locale.gettext("You tie the rope ladder to the edge and let it down.  It doesn't reach the ground and dangles in the air."))
  else
    msg(locale.gettext("You tie the rope ladder to the edge and let it down."))
  end
  if n > 1 then
    msg(string.format(locale.gettext("It hangs %d levels down.  Use < and > to climb along it."), n))
  end
  log("lowered %d levels at %d,%d (hanging=%s)", n, target.x, target.y, tostring(bottom_hanging))
  return 1
end

--[[
  「ここに設置する」：自分と同じ高さの隣のマスに縄梯子を掛ける（下から1階分登るとき）。
  (Set it up on an adjacent tile at your own level, to climb one level up.)
  地面があればそのまま置く。空中なら足場の地形にしてから置き、宙づりとして見回りに記録する。
  (On open air, swap in the hanging terrain first so it doesn't fall, and record it.)
]]
local function set_up(params)
  local u = params.user
  if not u then
    return 0
  end
  if u:is_mounted() then
    msg(locale.gettext("You cannot do that while mounted."))
    return 0
  end

  local target = gapi.choose_adjacent(locale.gettext("Set up the rope ladder where?"), false)
  if not target then
    return 0
  end

  -- 自分のマスには置けない（本体の deploy_furn と同じ）
  -- (Not on your own tile, same as deploy_furn.)
  local here = u:get_pos_ms()
  if target.x == here.x and target.y == here.y and target.z == here.z then
    msg(locale.gettext("There is no room to hang it there."))
    return 0
  end

  local map = gapi.get_map()
  -- 掛けられるか・宙づりになるかは「縁から垂らす」と同じ判定を使う
  -- (Reuse the same checks as lowering from a ledge.)
  local problem, hanging = check_tile(map, target)
  if problem then
    msg(problem)
    log("set up refused: %s", problem)
    return 0
  end

  local seg = { furn = FURN_ID }
  if hanging then
    seg.ter = ter_str_at(map, target)
    set_ter(map, target, HANG_TER)
  end
  set_furn(map, target, FURN_ID)

  -- 実際に置けたか確認する。駄目なら元に戻して何も消費しない
  -- (Make sure it took; otherwise undo and keep the item.)
  if furn_str_at(map, target) ~= FURN_ID then
    remove_segment(map, target, seg)
    msg(locale.gettext("There is no room to hang it there."))
    log("set up: set_furn_at did not take effect")
    return 0
  end

  if hanging then
    -- 宙づりは回収・破壊後に足場を戻すため記録する
    -- (Record dangling ladders so the patrol can restore the air later.)
    local a = map:bub_to_abs(target)
    local segs = { { x = a.x, y = a.y, z = a.z, furn = FURN_ID, ter = seg.ter } }
    ladder_list()[key_of(segs[1])] = { segs = segs }
    msg(locale.gettext("You throw the rope ladder up and hook it onto the edge above.  It dangles in the air."))
  else
    msg(locale.gettext("You set up the rope ladder."))
  end

  u:mod_moves(-mod.cfg.move_cost)
  log("set up at %d,%d,%d (hanging=%s)", target.x, target.y, target.z, tostring(hanging))
  return 1
end

mod.set_up_rope_ladder = function(params)
  local ok, res = pcall(set_up, params)
  if not ok then
    gdebug.log_info("RL: set_up_rope_ladder failed: " .. tostring(res))
    return 0
  end
  return res or 0
end

mod.lower_rope_ladder = function(params)
  local ok, res = pcall(lower, params)
  if not ok then
    gdebug.log_info("RL: lower_rope_ladder failed: " .. tostring(res))
    return 0
  end
  return res or 0
end

--[[
  毎ターンの見回り。区間が回収・破壊されていたら、それより下を外す。
    * いちばん上がなくなった（引き上げた・片付けた）→ 全部外す
    * 途中がなくなった（壊された）→ そこから下を外し、残った最後の区間を「いちばん下」にする
  宙づりの足場を元の空中に戻すので、その場にいた人は下へ落ちる。
]]
mod.check_hanging_ladders = function()
  local ok, err = pcall(function()
    local list = ladder_list()
    if next(list) == nil then return end
    local map = gapi.get_map()
    for k, rec in pairs(list) do
      local segs = rec.segs or {}
      local ps = {}
      local loaded = #segs > 0
      for i, sg in ipairs(segs) do
        ps[i] = map:abs_to_bub(TripointAbsMs.new(sg.x, sg.y, sg.z))
        if not in_bounds(map, ps[i]) then loaded = false end
      end
      -- 読み込まれていない場所は、近づいたときに調べる
      if loaded then
        local cut = nil
        for i, sg in ipairs(segs) do
          if furn_str_at(map, ps[i]) ~= sg.furn then
            cut = i
            break
          end
        end
        if cut then
          for i = cut, #segs do
            remove_segment(map, ps[i], segs[i])
          end
          local keep = cut - 1
          if keep == 0 then
            list[k] = nil
          else
            local kept = {}
            for i = 1, keep do kept[i] = segs[i] end
            -- 残った区間の家具を、新しい長さに合わせて付け替える
            for i = 1, keep do
              local want = furn_for(i, keep)
              if kept[i].furn ~= want then
                set_furn(map, ps[i], want)
                kept[i].furn = want
              end
            end
            -- 1階分で地面に着いているなら、もう見回りはいらない
            if keep == 1 and not kept[1].ter then
              list[k] = nil
            else
              rec.segs = kept
            end
          end
          log("ladder %s cut at %d", k, cut)
        end
      end
    end
  end)
  if not ok then
    gdebug.log_info("RL: check_hanging_ladders failed: " .. tostring(err))
  end
end
end

----------------------------------------------------------------------
-- 2. 自作ウォーターサーバー
----------------------------------------------------------------------
do
--[[
  Liquid Grid Water Dispenser - main.lua

  液体グリッド（配管）の水を、本体の「自動飲料」（AUTO_DRINK 区域）で飲めるようにする。

  本体の自動飲料は、長い作業中にのどが渇くと、区域内のマスに「置かれたアイテム」だけを探して飲む。
  液体グリッドの水はアイテムではないので対象にならない。
  そこで、液体グリッドのある建物の中に家具「自作ウォーターサーバー」を置き、そのマスに見えない容器
  （lgwd_reservoir）を入れておいて、空になったらグリッドのきれいな水で補充する。
  液体グリッドはマップの区画（オーバーマップの1マス）ごとなので、置いた区画のグリッドから汲む。
  流し台やタンクの隣に置いたときは、その設備の区画のグリッドから汲む（区画の境目でも届くように）。
  家具は CONTAINER + SEALED なので、中の容器は見えず、拾えない。本体の自動飲料は封の有無を
  見ないので、中の水を飲む。

    * アイテムを使う →「設置する」: 隣のマスを選ぶと家具を置き、位置を覚える
    * 1分ごと: 覚えている位置の中の容器が空なら、グリッドから水を汲んで入れる
    * 家具を調べる: 水の量を見る／片付けてアイテムに戻す
    * 家具が壊された・解体された: 中の容器を消して、位置を忘れる
]]

gdebug.log_info("LGWD: main.")

local mod = game.mod_runtime[game.current_mod]
local storage = game.mod_storage[game.current_mod]
local T = locale.gettext

----------------------------------------------------------------------
-- 調整値
----------------------------------------------------------------------

local CFG = {
  -- 液体グリッドの蛇口とタンク。この上には置けない。隣に置くと、この設備の区画から汲む
  fixtures = {
    f_sink = true,
    f_bathtub = true,
    f_shower = true,
    f_standing_tank_plumbed = true,
  },
  -- true にすると、以前のように流し台・タンクなどの隣にしか置けない
  need_fixture = false,
  -- 補充する液体（きれいな水だけ）
  liquid = "water_clean",
  -- 1回に補充する量（水は1単位250ml。4 = 1L＝満タン）
  refill_charges = 4,
}

local ITEM = "lgwd_water_dispenser"
local FURN = "f_lgwd_water_dispenser"
local RESERVOIR = "lgwd_reservoir"

----------------------------------------------------------------------
-- 補助
----------------------------------------------------------------------

local function say(text)
  gapi.add_msg(text)
end

local function state()
  storage.dispensers = storage.dispensers or {}
  storage.bottles = nil -- 旧版（ボトルを床に置く方式）の記録は使わない
  return storage
end

local function key_of(a)
  return a.x .. "," .. a.y .. "," .. a.z
end

local function furn_str_at(map, p)
  local ok, s = pcall(function() return map:get_furn_at(p):str_id():str() end)
  if ok then return s end
  return nil
end

local function in_bounds(map, p)
  local size = map:get_map_size()
  return p.x >= 0 and p.y >= 0 and p.x < size and p.y < size
end

-- p の隣（同じ高さ）にある蛇口・タンクの位置
local function find_fixture(map, p)
  for dx = -1, 1 do
    for dy = -1, 1 do
      if dx ~= 0 or dy ~= 0 then
        local q = TripointBubMs.new(p.x + dx, p.y + dy, p.z)
        if in_bounds(map, q) and CFG.fixtures[furn_str_at(map, q) or ""] then
          return q
        end
      end
    end
  end
  return nil
end

local function omt_of(map, p)
  local a = map:bub_to_abs(p)
  return TripointAbsOmt.new(math.floor(a.x / 24), math.floor(a.y / 24), a.z)
end

-- 水を汲む区画：隣に設備があればその区画、なければ置いた場所の区画
-- （need_fixture のときは設備の隣でなければ nil）
local function source_omt(map, p)
  local fixture = find_fixture(map, p)
  if fixture then
    return omt_of(map, fixture)
  end
  if CFG.need_fixture then
    return nil
  end
  return omt_of(map, p)
end

-- 区画のグリッドにあるきれいな水の量（単位）
local function grid_charges(omt)
  local ok, n = pcall(function()
    return overmapbuffer.fluid_grid_liquid_charges_at(omt, ItypeId.new(CFG.liquid))
  end)
  if ok and n then return n end
  return 0
end

local function reservoirs_at(map, p)
  local list = {}
  local stack = map:get_items_at(p)
  local n = #stack
  for i = 1, n do
    local it = stack[i]
    if it and it:get_type():str() == RESERVOIR then
      list[#list + 1] = it
    end
  end
  return list
end

local function remove_reservoirs(map, p)
  for _, it in ipairs(reservoirs_at(map, p)) do
    map:remove_item_at(p, it)
  end
end

-- 中の容器（なければ作る）
local function reservoir(map, p)
  local list = reservoirs_at(map, p)
  if #list > 0 then return list[1] end
  map:create_item_at(p, ItypeId.new(RESERVOIR), 1)
  list = reservoirs_at(map, p)
  return list[1]
end

-- 空なら隣の設備のグリッドから水を入れる。入れた量（単位）を返す
local function fill(map, p)
  local r = reservoir(map, p)
  if not r or not r:is_container_empty() then
    return 0
  end
  local omt = source_omt(map, p)
  if not omt then
    return 0
  end
  local ok, drained = pcall(function()
    return overmapbuffer.drain_fluid_grid_liquid_charges(omt, ItypeId.new(CFG.liquid), CFG.refill_charges)
  end)
  if not ok or not drained or drained <= 0 then
    return 0
  end
  r:add_item_with_id(ItypeId.new(CFG.liquid), drained)
  return drained
end

-- 中の水の量（単位）
local function water_in(map, p)
  local list = reservoirs_at(map, p)
  if #list == 0 or list[1]:is_container_empty() then
    return 0
  end
  local ok, n = pcall(function()
    return list[1]:remaining_capacity_for_id(ItypeId.new(CFG.liquid), false)
  end)
  if ok and n then
    return math.max(0, CFG.refill_charges - n)
  end
  return -1 -- 量はわからないが入っている
end

----------------------------------------------------------------------
-- 「流し台の隣に置く」
----------------------------------------------------------------------

mod.set_up_dispenser = function(params)
  local ok, res = pcall(function()
    local u = params.user
    local it = params.item
    if not u or not it then return 0 end
    if u:is_mounted() then
      say(T("You cannot do that while mounted."))
      return 0
    end
    local target = gapi.choose_adjacent(T("Set up the water dispenser where?"), false)
    if not target then return 0 end

    local map = gapi.get_map()
    local f = furn_str_at(map, target)
    if CFG.fixtures[f or ""] then
      say(T("You can't put it on top of that.  Put it next to it instead."))
      return 0
    end
    if (f ~= nil and f ~= "f_null" and f ~= "")
        or map:has_ter_flag_at("WALL", target) or map:has_ter_flag_at("NOITEM", target)
        or map:has_ter_flag_at("DEEP_WATER", target) or map:has_ter_flag_at("NO_FLOOR", target)
        or map:has_ter_flag_at("SWIMMABLE", target) then
      say(T("You can't put it there."))
      return 0
    end
    if gapi.get_creature_at(target) then
      say(T("Something is in the way."))
      return 0
    end
    if map:has_items_at(target) then
      say(T("Clear the items off that spot first."))
      return 0
    end
    local omt = source_omt(map, target)
    if not omt then
      say(T("There is no sink, plumbed tank or other plumbing fixture next to that spot."))
      return 0
    end

    local detached = u:remove_item(it)
    if not detached then
      say(T("Put it away first (it must not be wielded or worn)."))
      return 0
    end
    detached = nil -- アイテムは家具になる

    map:set_furn_at(target, FurnId.new(FURN):int_id())
    local a = map:bub_to_abs(target)
    state().dispensers[key_of(a)] = { x = a.x, y = a.y, z = a.z }
    u:mod_moves(-300)
    fill(map, target)

    say(T("You set up the water dispenser.  Mark it as an Auto Drink zone to drink from it automatically."))
    if grid_charges(omt) <= 0 and water_in(map, target) == 0 then
      say(T("There is no clean water in the fluid grid right now.  The dispenser will be filled once there is some."))
    end
    return 0
  end)
  if not ok then
    gdebug.log_info("LGWD: set_up_dispenser failed: " .. tostring(res))
    return 0
  end
  return res or 0
end

----------------------------------------------------------------------
-- 家具を調べる
----------------------------------------------------------------------

local function take_down(u, map, p)
  remove_reservoirs(map, p)
  map:set_furn_at(p, FurnId.new("f_null"):int_id())
  map:create_item_at(p, ItypeId.new(ITEM), 1)
  state().dispensers[key_of(map:bub_to_abs(p))] = nil
  u:mod_moves(-300)
  say(T("You take down the water dispenser."))
end

mod.examine_dispenser = function(params)
  local ok, err = pcall(function()
    local u = params.user
    local p = params.pos
    if not u or not p then return end
    local map = gapi.get_map()
    -- 置いたあとに記録が消えていても（読み込み直しなど）、調べたら覚え直す
    local a = map:bub_to_abs(p)
    state().dispensers[key_of(a)] = { x = a.x, y = a.y, z = a.z }
    fill(map, p)

    local w = water_in(map, p)
    local status
    if w > 0 then
      status = string.format(T("It holds %d ml of clean water."), w * 250)
    elseif w < 0 then
      status = T("It has some clean water in it.")
    else
      status = T("It is empty.")
    end
    local omt = source_omt(map, p)
    if not omt then
      status = status .. "\n" .. T("There is no sink or plumbed tank next to it, so it won't be refilled.")
    elseif grid_charges(omt) <= 0 then
      status = status .. "\n" .. T("There is no clean water in the fluid grid.")
    end

    local ui = UiList.new()
    ui:title(T("Homemade water dispenser"))
    ui:text(status)
    ui:add(1, T("Take it down"))
    ui:add(2, T("Leave it"))
    if ui:query() == 1 then
      take_down(u, map, p)
    end
  end)
  if not ok then
    gdebug.log_info("LGWD: examine_dispenser failed: " .. tostring(err))
  end
end

----------------------------------------------------------------------
-- 1分ごとの補充と片付け
----------------------------------------------------------------------

mod.refill = function()
  local ok, err = pcall(function()
    local s = state()
    if next(s.dispensers) == nil then return end
    local map = gapi.get_map()
    for k, a in pairs(s.dispensers) do
      local p = map:abs_to_bub(TripointAbsMs.new(a.x, a.y, a.z))
      if in_bounds(map, p) then
        if furn_str_at(map, p) == FURN then
          fill(map, p)
        else
          -- 壊された・解体された：中の容器（と水）を消して忘れる
          remove_reservoirs(map, p)
          s.dispensers[k] = nil
        end
      end
    end
  end)
  if not ok then
    gdebug.log_info("LGWD: refill failed: " .. tostring(err))
  end
end
end

