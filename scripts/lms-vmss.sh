#!/bin/bash
moodleSharedFolder="/var/www/html/moodle"
moodleTargetFolder="/var/www/public_html/moodle"
nginxConfigPath="/etc/nginx/sites-enabled";
nginxConfigOldString="\/var\/www\/html\/moodle;";
nginxConfigNewString="\/var\/www\/public_html\/moodle;";
redisKey="IFI4qL0HnOrHUHE8x4KeYjoYmiGd8qfIWAzCaKOeTgo=";
redisHost="redis-fhmk5d.redis.cache.windows.net";

echo "LMS tuning start..."    > /tmp/lmstuning.txt
echo "Start date and time: $(date)" >> /tmp/lmstuning.txt
echo "$moodleSharedFolder: $moodleSharedFolder"    >> /tmp/lmstuning.txt
echo "$moodleTargetFolder: $moodleTargetFolder"    >> /tmp/lmstuning.txt
echo "$nginxConfigPath: $nginxConfigPath"    >> /tmp/lmstuning.txt
echo "$nginxConfigOldString: $nginxConfigOldString"    >> /tmp/lmstuning.txt
echo "$nginxConfigNewString: $nginxConfigNewString"    >> /tmp/lmstuning.txt


#Create moodleTargetFolder
echo "Step: Create moodleTargetFolder" >> /tmp/lmstuning.txt
if [[ -e $moodleTargetFolder ]]; then
    echo "rename existing folder" >> /tmp/lmstuning.txt
    mv "$moodleTargetFolder" "${moodleTargetFolder}_bk_$(date +'%Y_%m_%d_%I_%M_%p')"
fi

if [[ ! -e $moodleTargetFolder ]]; then
    echo "create $moodleTargetFolder" >> /tmp/lmstuning.txt
    mkdir -p "$moodleTargetFolder"
	echo "$moodleTargetFolder created" >> /tmp/lmstuning.txt
fi

#Copy moodle source code
echo "Step: Copy moodle source code" >> /tmp/lmstuning.txt
if [[ -e $moodleSharedFolder ]]; then
    echo "Copying from  $moodleSharedFolder to $moodleTargetFolder" >> /tmp/lmstuning.txt
    rsync -a "${moodleSharedFolder}/" "${moodleTargetFolder}/"
	echo "Copied completed" >> /tmp/lmstuning.txt
fi

#Update moodle redis config
echo "Step: Update moodle redis config" >> /tmp/lmstuning.txt
if [[ -e $moodleTargetFolder ]]; then
    echo "Updating moodle redis config" >> /tmp/lmstuning.txt
	cd "$moodleTargetFolder"
	pwd >> /tmp/lmstuning.txt
	cp config.php "config_php_$(date +'%Y_%m_%d_%I_%M_%p').bk"
	sed -i "s/\$CFG->session_redis_auth/\/\/$CFG->session_redis_auth/g" config.php
	sed -i "s/\$CFG->session_redis_host /\/\/$CFG->session_redis_host/g" config.php
	sed -i "s/\$CFG->session_redis_port /\/\/$CFG->session_redis_port/g" config.php
	sed -i "s/\$CFG->session_redis_database/\/\/$CFG->session_redis_database/g" config.php
	sed -i "s/\$CFG->session_redis_prefix/\/\/$CFG->session_redis_prefix/g" config.php
	sed -i "s/\$CFG->session_redis_serializer_use_igbinary/\/\/$CFG->session_redis_serializer_use_igbinary/g" config.php
	
    sed  -i "/^require_once.*/i \$CFG->session_redis_auth = '$redisKey';" config.php
	sed  -i "/^require_once.*/i \$CFG->session_redis_host = '$redisHost';" config.php
	sed  -i '/^require_once.*/i \$CFG->session_redis_port = 6379;' config.php
	sed  -i '/^require_once.*/i \$CFG->session_redis_database = 0; ' config.php
	sed  -i '/^require_once.*/i \$CFG->session_redis_prefix = "moodle_prod";' config.php
	sed  -i '/^require_once.*/i \$CFG->localcachedir = "/tmp/localcachedir";' config.php
	echo "Update moodle redis config completed" >> /tmp/lmstuning.txt
fi

#Update Nginx Config
echo "Step: Update Nginx Config" >> /tmp/lmstuning.txt
if [[ -e $nginxConfigPath ]]; then
   echo "Update Nginx Config" >> /tmp/lmstuning.txt
   cd "$nginxConfigPath"
   pwd >> /tmp/lmstuning.txt
   sed -i "s/$nginxConfigOldString/$nginxConfigNewString/g" *
   echo "nginx config updated" >> /tmp/lmstuning.txt
   systemctl restart nginx.service
fi
echo "End date and time: $(date)" >> /tmp/lmstuning.txt


