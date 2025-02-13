with
    stg_dim_player as (
        -- create a staging table to calculate player's country based on date range
        select
            playerid,
            country,
            latestupdate as start_date,
            lead(latestupdate) over (
                partition by playerid order by latestupdate
            ) as end_date
        from
            (
                select playerid, country, latestupdate
                from `LeoVegas.Player`
                group by playerid, country, latestupdate
            ) a
    ),
    stg_transaction_detail_with_country_rate_euro as (
        select  /* +BROADCAST_JOIN(b, c) */
            a.date,
            a.playerid,
            b.country,
            a.gameid,
            parse_numeric(replace(a.realamount, ',', '.')) as realamount,
            parse_numeric(replace(a.bonusamount, ',', '.')) as bonusamount,
            a.txtype,
            a.txcurrency,
            a.betid,
            c.baserateeuro
        from
            (
                select
                    parse_date('%Y-%m-%d', `date`) as `date`,
                    betid,
                    playerid,
                    gameid,
                    realamount,
                    bonusamount,
                    txtype,
                    txcurrency
                from `LeoVegas.GameTransaction`
            ) a
        left join
            stg_dim_player b
            on a.playerid = b.playerid
            and a.date >= b.start_date
            and a.date < ifnull(b.end_date, '9999-12-31')
        left join
            `LeoVegas.CurrencyExchange` c
            on a.`date` = c.date
            and a.txcurrency = c.currency

    )

select
    a.date,
    a.playerid as player_id,
    a.country,
    a.gameid as game_id,
    cash_turnover,
    bonus_turnover,
    cash_winnings,
    bonus_winnings,
    cash_turnover + bonus_turnover as turnover,
    cash_winnings + bonus_winnings as winnings,
    cash_turnover - cash_winnings as cash_result,
    bonus_turnover - bonus_winnings as bonus_result,
    cash_turnover + bonus_turnover - (cash_winnings + bonus_winnings) as gross_result
from
    (
        select
            a.date,
            a.playerid,
            a.country,
            a.gameid,
            sum(
                if(a.txtype = 'WAGER', a.realamount * baserateeuro, 0)
            ) as cash_turnover,
            sum(
                if(a.txtype = 'WAGER', a.bonusamount * baserateeuro, 0)
            ) as bonus_turnover,
            sum(
                if(a.txtype = 'RESULT', a.realamount * baserateeuro, 0)
            ) as cash_winnings,
            sum(
                if(a.txtype = 'RESULT', a.bonusamount * baserateeuro, 0)
            ) as bonus_winnings

        from stg_transaction_detail_with_country_rate_euro a
        group by a.date, a.playerid, a.country, a.gameid
    ) a