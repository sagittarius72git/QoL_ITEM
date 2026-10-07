--[[
  QoL Item - preload.lua
  使用アクション・調べるアクション・定期処理の登録だけを置く。実装は main.lua 側。

  Assisted-by: Claude:claude-opus-5-5
]]

gdebug.log_info("QOL: preload.")

local mod = game.mod_runtime[game.current_mod]

-- 縄梯子：「縁から垂らす」。戻り値は消費数（0 なら何も起きない）
game.iuse_functions["RL_LOWER_ROPE_LADDER"] = {
  use = function(params)
    if mod.lower_rope_ladder then
      return mod.lower_rope_ladder(params)
    end
    return 0
  end,
}

-- 縄梯子：「ここに設置する」。空中なら宙づりで掛ける
-- (Rope ladder: "Set it up here"; dangles if the tile is open air.)
game.iuse_functions["RL_SET_UP_ROPE_LADDER"] = {
  use = function(params)
    if mod.set_up_rope_ladder then
      return mod.set_up_rope_ladder(params)
    end
    return 0
  end,
}

-- 縄梯子：宙づりの縄梯子が回収・破壊されたら、足場を空中に戻す（毎ターン。記録がなければすぐ戻る）
gapi.add_on_every_x_hook(TimeDuration.from_turns(1), function()
  if mod.check_hanging_ladders then
    mod.check_hanging_ladders()
  end
end)

-- 自作ウォーターサーバー：「ウォーターサーバーを設置する」
game.iuse_functions["LGWD_SET_UP_DISPENSER"] = {
  use = function(params)
    if mod.set_up_dispenser then
      return mod.set_up_dispenser(params)
    end
    return 0
  end,
}

-- 自作ウォーターサーバー：家具を調べる
game.examine_functions["LGWD_DISPENSER_EXAMINE"] = function(params)
  if mod.examine_dispenser then
    mod.examine_dispenser(params)
  end
end

-- 自作ウォーターサーバー：1分ごとに、空のサーバーへ液体グリッドから補充する
gapi.add_on_every_x_hook(TimeDuration.from_minutes(1), function()
  if mod.refill then
    mod.refill()
  end
end)
