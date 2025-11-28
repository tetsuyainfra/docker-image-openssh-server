# docker-image-openssh-server
[![Docker](https://github.com/tetsuyainfra/docker-image-openssh-server/actions/workflows/docker.yml/badge.svg?branch=main)](https://github.com/tetsuyainfra/docker-image-openssh-server/actions/workflows/docker.yml)
[![Docker Image Version](https://img.shields.io/docker/v/tetsuyainfra/openssh-server)](https://hub.docker.com/r/tetsuyainfra/openssh-server)

# HOW TO USE
SEE [Makefile run](Makefile#46), [Makefile run2](Makefile#57)
or [test.sh](test.sh#25)

# HOW TO TEST
```make test```

# 動作について
- 02-useradd : /etc/init_useradd をチェックして2度目の実行を予防している
- 03-sshd_config : /etc/init_sshd_configをチェックして2度目の実行を予防している
- 変数 INIT_CONFIGで設定ファイルへのパスを与えると、DEBUG以外の変数を読み込まずにサービスが起動する
  - INIT_CONFIGを設定しなければ、INIT_GROUPS, INIT_USERS, INIT_CREATE_DIRS, INIT_SSHD_CONFIGの変数を読み込みサービスが起動される 

# MEMO
service
- s6-overlayを使う
  - ログの出力先をsyslogdにしてもいいかもしれない
  - fail2banが欲しいかも？
Logging
- sshdはsyslog()にログを出力している
  - このイメージではsystemd(journald)/syslogdを入れていない
  - そのため sshd -e オプションで stderr に出力している(s6-overlayの機能でstdioにフォワード)
    - -D は foregroudでの実行

# TODO
- [ ] portainerなんかでpull-rebuildさせた時、/etc/\[shadow|group\]が無くなるのでinit_useraddなどのタイムスタンプファイルを/直下に置くことにする
- [ ] github actionsに対応させる
  - [x] branch=main以外はbuildだけにする
  - [ ] 不要なTAGを削除するワークフローを作る
  - [ ] 不要なcacheを削除するワークフローを作る
- [ ] たまにmake runでビルドに失敗する理由を見つける
- [ ] RUN  --mount=type=cache,target=/var/cache/apt,sharing=locked してbuildキャッシュさせる
  - [ ] /etc/apt/apt.conf.d/docker-clean を無効化(削除) する
  - [ ] キャッシュ強制 echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
- [ ] variable "extra_tags" { default = [] }, tags = ["latest", ...var.extra_tags] をする
- [ ] もう少しドキュメントを充実させる
