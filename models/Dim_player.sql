select
    a.playerid as player_id,
    a.gender as gender,
    a.country as country,
    a.latestupdate as latestupdate
from
    (
        select
            *,
            row_number() over (partition by playerid order by a.latestupdate desc) as rn
        from `LeoVegas.Player` a
    ) a
where rn = 1
order by 1

