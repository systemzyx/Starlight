local function shutDown(msg)
  for _, plr in pairs(game.Players:GetPlayers()) do 
    if plr then 
     plr:Kick(msg)
   end
  end
end
shutDown("Shutdown")
