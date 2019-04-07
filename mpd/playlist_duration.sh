mpc playlist -f '%time%' | tr ':' ' ' | awk '
    BEGIN {i = 0}
    {i += $1*60 + $2}
    END{
        if (int(i/3600) > 0)
            print int(i/3600) "h " int((i%3600)/60) "m " int(i%60) "s"
        else if (int(i) > 0)
            print int((i%3600)/60) "m " int(i%60) "s"
        else
            print "(empty)"
    }
'