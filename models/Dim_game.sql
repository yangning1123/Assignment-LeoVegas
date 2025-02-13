select
    a.id as game_id,
    a.`Game Name` as game_name,
    b.`Game Category` as game_category,
    c.`Game Provider Name` as provider_name
from `LeoVegas.Game` a
left join `LeoVegas.GameCategory` b on a.id = b.`Game ID`
left join `LeoVegas.GameProvider` c on a.gameproviderid = c.id
order by a.id
