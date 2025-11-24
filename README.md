

# Logging
- sshdはsyslog()にログを出力している
  - このイメージではsystemd(journald)/syslogdを入れていない
  - そのため sshd -e オプションで stderr に出力している
    - -D は foregroudでの実行




/etc/runit/{1..3} またはランレベル /etc/runit/runsvdir/*

/etc/runit/ctrlaltdel
/etc/runit/2
/etc/runit/3



https://smarden.org/runit/

https://tracker.debian.org/pkg/runit

https://sources.debian.org/src/runit/2.2.0-6/runit-2.2.0/src/runit-init.cA