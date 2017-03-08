# pgmon


Example

```
$ ./pgmon.sh kyle kyle  mymachine.com

  psql -t -h mymachine.com -p 5432 -U kyle postgres < /tmp/MONITOR/tmp/mymachine.com:postgres_collect.pipe &

  RUN_TIME=-1
  COLLECT_LIST=
  FAST_SAMPLE=wts
  TARGET=kr4.c3o7fyskibto.us-east-1-beta.rds.amazonaws.com:postgres
  DEBUG=0

  Connected, starting collect at Wed Mar 8 12:05:12 PST 2017
  starting stats collecting
  SET

  AAS| blks_hit | blks_read | tup_returned | tup_fetched | tup_inserted | tup_updated | tup_deleted

   1 |    38281 |         1 |       628629 |       23600 |         1068 |        2316 |           0
  16 |   146522 |         0 |      1497604 |       48647 |         2352 |        4599 |        2462
   2 |   114046 |         0 |      1894329 |       46341 |         3822 |        3852 |        3066
   2 |   146728 |         0 |      2239014 |       61420 |         3822 |        5668 |        3150
  16 |    70446 |         0 |       945021 |       49284 |         2016 |         686 |         757
  13 |   264149 |         0 |      1146816 |       53816 |         1638 |        2176 |        1852
  15 |    54324 |         0 |       226542 |       19078 |          840 |         396 |          31
  13 |  1170087 |         0 |      2301442 |      186967 |         2058 |        4276 |        1340
   3 |  1036439 |         0 |      3411396 |       57392 |         4158 |        5041 |        3605
   1 |   135927 |         0 |      1931473 |       90238 |         4788 |        5077 |        3654
   5 |    92975 |         0 |      1427641 |       49175 |         2772 |        2812 |        1764
  16 |    73695 |         0 |      1001290 |       35585 |         1806 |        1721 |        1915
  14 |    65117 |         0 |       242383 |       22150 |          420 |         530 |         511
   4 |   111906 |         0 |      1593090 |       49570 |         2982 |        4718 |        3086
```
