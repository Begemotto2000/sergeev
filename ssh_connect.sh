#!/bin/bash
expect -c "
set timeout 10
spawn ssh -o StrictHostKeyChecking=no root@46.8.255.137
expect \"password:\"
send \"k8hSaZ2XL37x\r\"
expect \"#\"
send \"uname -a\r\"
expect \"#\"
send \"lsb_release -d\r\"
expect \"#\"
send \"node --version\r\"
expect \"#\"
send \"psql --version\r\"
expect \"#\"
send \"exit\r\"
expect eof
"
