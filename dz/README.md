#### Стенд для занятия с ZFS.

Цель:
- Определить алгоритм с наилучшим сжатием.
- Определить настройки pool’a
- Найти сообщение от преподавателей

Развернем vagrantfile, в каталоге `/vagrant` расположениы файлы для занятия с zfs.

Проверим модуль zfs:

```
[root@zfs ~]# lsmod | grep zfs
zfs                  3986613  0 
zunicode              331170  1 zfs
zlua                  147429  1 zfs
zcommon                89551  1 zfs
znvpair                94388  2 zfs,zcommon
zavl                   15167  1 zfs
icp                   301854  1 zfs
spl                   104299  5 icp,zfs,zavl,zcommon,znvpair
```

Создадим пул из 4х дисков (pool zfs):

```
[root@zfs ~]# lsblk
NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
sda      8:0    0  40G  0 disk 
`-sda1   8:1    0  40G  0 part /
sdb      8:16   0   5G  0 disk 
sdc      8:32   0   5G  0 disk 
sdd      8:48   0   5G  0 disk 
sde      8:64   0   5G  0 disk 
[root@zfs ~]# zpool create pool_zfs mirror sdb sdc mirror sdd sde
```

Проверим статус пула:

```
[root@zfs ~]# zpool status
  pool: pool_zfs
 state: ONLINE
  scan: none requested
config:

	NAME        STATE     READ WRITE CKSUM
	pool_zfs    ONLINE       0     0     0
	  mirror-0  ONLINE       0     0     0
	    sdb     ONLINE       0     0     0
	    sdc     ONLINE       0     0     0
	  mirror-1  ONLINE       0     0     0
	    sdd     ONLINE       0     0     0
	    sde     ONLINE       0     0     0

errors: No known data errors
[root@zfs ~]# zpool list
NAME       SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
pool_zfs     9G  94.5K  9.00G        -         -     0%     0%  1.00x    ONLINE  -
```

### 1. Определить алгоритм с наилучшим сжатием (gzip, gzip-N, zle, lzjb, lz4).

Создадим 5 файловыx систем c указанными алгоритмами сжатия:

```
[root@zfs ~]# zfs create -o compression=gzip pool_zfs/fs1
[root@zfs ~]# zfs create -o compression=gzip-9 pool_zfs/fs2
[root@zfs ~]# zfs create -o compression=zle pool_zfs/fs3
[root@zfs ~]# zfs create -o compression=lzjb pool_zfs/fs4
[root@zfs ~]# zfs create -o compression=lz4 pool_zfs/fs5
```

Проверим:

```
[root@zfs ~]# zfs list
NAME           USED  AVAIL     REFER  MOUNTPOINT
pool_zfs       234K  8.72G     28.5K  /pool_zfs
pool_zfs/fs1    24K  8.72G       24K  /pool_zfs/fs1
pool_zfs/fs2    24K  8.72G       24K  /pool_zfs/fs2
pool_zfs/fs3    24K  8.72G       24K  /pool_zfs/fs3
pool_zfs/fs4    24K  8.72G       24K  /pool_zfs/fs4
pool_zfs/fs5    24K  8.72G       24K  /pool_zfs/fs5
```

Скачаем файл (linux-5.8.9) и скопируем в каждую файловую систему:

```
[root@zfs ~]# curl -L -o /tmp/linux-5.8.9.tar.xz https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.8.9.tar.xz
[root@zfs ~]# tar -xvf /tmp/linux-5.8.9.tar.xz -C /tmp
[root@zfs ~]# echo "/pool_zfs/fs1/ /pool_zfs/fs2/ /pool_zfs/fs3/ /pool_zfs/fs4/ /pool_zfs/fs5/" | xargs -n 1 cp -r /tmp/linux-5.8.9
```

Проверим:

```
[root@zfs ~]# zfs list -o name,used,available,referenced,compression,compressratio
NAME           USED  AVAIL     REFER  COMPRESS  RATIO
pool_zfs      2.18G  6.54G     28.5K       off  2.31x
pool_zfs/fs1   249M  6.54G      249M      gzip  4.29x
pool_zfs/fs2   247M  6.54G      247M    gzip-9  4.32x
pool_zfs/fs3   936M  6.54G      936M       zle  1.08x
pool_zfs/fs4   429M  6.54G      429M      lzjb  2.41x
pool_zfs/fs5   374M  6.54G      374M       lz4  2.79x

```

Лучшие результаты по сжатию, алгоритмы gzip и gzip-9.


### 2.Определить настройки pool’a.

Скачаем файл:
```
[root@zfs ~]# curl -L -o /tmp/zfs_task1.tar.gz  https://drive.google.com/u/0/uc?id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg&export=download
[root@zfs ~]# tar -xvf /tmp/zfs_task1.tar.gz -C /tmp
```

Импортируем пул:

```
[root@zfs ~]# zpool import -d /tmp/zpoolexport/
   pool: otus
     id: 6554193320433390805
  state: ONLINE
 action: The pool can be imported using its name or numeric identifier.
 config:

	otus                        ONLINE
	  mirror-0                  ONLINE
	    /tmp/zpoolexport/filea  ONLINE
	    /tmp/zpoolexport/fileb  ONLINE

[root@zfs ~]# zpool import -d /tmp/zpoolexport/ otus
```

Проверим доступные пулы:

```
[root@zfs ~]# zpool list
NAME       SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
otus       480M  2.18M   478M        -         -     0%     0%  1.00x    ONLINE  -
pool_zfs     9G  2.18G  6.82G        -         -     0%    24%  1.00x    ONLINE  -
```

<details>
  <summary>Список свойств пула otus:</summary>

```
[root@zfs ~]# zfs get all otus
NAME  PROPERTY              VALUE                  SOURCE
otus  type                  filesystem             -
otus  creation              Fri May 15  4:00 2020  -
otus  used                  2.04M                  -
otus  available             350M                   -
otus  referenced            24K                    -
otus  compressratio         1.00x                  -
otus  mounted               yes                    -
otus  quota                 none                   default
otus  reservation           none                   default
otus  recordsize            128K                   local
otus  mountpoint            /otus                  default
otus  sharenfs              off                    default
otus  checksum              sha256                 local
otus  compression           zle                    local
otus  atime                 on                     default
otus  devices               on                     default
otus  exec                  on                     default
otus  setuid                on                     default
otus  readonly              off                    default
otus  zoned                 off                    default
otus  snapdir               hidden                 default
otus  aclinherit            restricted             default
otus  createtxg             1                      -
otus  canmount              on                     default
otus  xattr                 on                     default
otus  copies                1                      default
otus  version               5                      -
otus  utf8only              off                    -
otus  normalization         none                   -
otus  casesensitivity       sensitive              -
otus  vscan                 off                    default
otus  nbmand                off                    default
otus  sharesmb              off                    default
otus  refquota              none                   default
otus  refreservation        none                   default
otus  guid                  14592242904030363272   -
otus  primarycache          all                    default
otus  secondarycache        all                    default
otus  usedbysnapshots       0B                     -
otus  usedbydataset         24K                    -
otus  usedbychildren        2.01M                  -
otus  usedbyrefreservation  0B                     -
otus  logbias               latency                default
otus  objsetid              54                     -
otus  dedup                 off                    default
otus  mlslabel              none                   default
otus  sync                  standard               default
otus  dnodesize             legacy                 default
otus  refcompressratio      1.00x                  -
otus  written               24K                    -
otus  logicalused           1020K                  -
otus  logicalreferenced     12K                    -
otus  volmode               default                default
otus  filesystem_limit      none                   default
otus  snapshot_limit        none                   default
otus  filesystem_count      none                   default
otus  snapshot_count        none                   default
otus  snapdev               hidden                 default
otus  acltype               off                    default
otus  context               none                   default
otus  fscontext             none                   default
otus  defcontext            none                   default
otus  rootcontext           none                   default
otus  relatime              off                    default
otus  redundant_metadata    all                    default
otus  overlay               off                    default
otus  encryption            off                    default
otus  keylocation           none                   default
otus  keyformat             none                   default
otus  pbkdf2iters           0                      default
otus  special_small_blocks  0                      default
```

</details>

Выведем те которые требуются по заданию:

```
[root@zfs ~]# zfs get available,type,recordsize,compression,checksum otus
NAME  PROPERTY     VALUE       SOURCE
otus  available    350M        -
otus  type         filesystem  -
otus  recordsize   128K        local
otus  compression  zle         local
otus  checksum     sha256      local
```

### 3. Найти сообщение от преподавателей.

Скачаем файл:
```
[root@zfs ~]# curl -L -o /tmp/otus_task2.file  https://drive.google.com/u/0/uc?id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG&export=download
```

Восстановим снапшот из файла (otus_task2.file):

```
[root@zfs ~]# zfs receive otus/storage@task2 < /tmp/otus_task2.file
[root@zfs ~]# zfs list 
NAME             USED  AVAIL     REFER  MOUNTPOINT
otus            4.93M   347M       24K  /otus
otus/hometask2  1.88M   347M     1.88M  /otus/hometask2
otus/storage    2.83M   347M     2.83M  /otus/storage
pool_zfs        2.18G  6.54G     28.5K  /pool_zfs
pool_zfs/fs1     249M  6.54G      249M  /pool_zfs/fs1
pool_zfs/fs2     247M  6.54G      247M  /pool_zfs/fs2
pool_zfs/fs3     936M  6.54G      936M  /pool_zfs/fs3
pool_zfs/fs4     429M  6.54G      429M  /pool_zfs/fs4
pool_zfs/fs5     374M  6.54G      374M  /pool_zfs/fs5

```

Зашифрованное сообщение в файле secret_message:

```
[root@zfs ~]# find /otus/storage -name "secret_message" -print
/otus/storage/task1/file_mess/secret_message
[root@zfs ~]# cat /otus/storage/task1/file_mess/secret_message 
https://github.com/sindresorhus/awesome
```

