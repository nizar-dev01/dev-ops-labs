#!/bin/bash
apt-get update &&  apt-get install build-essential git python3 python3-pip python3-venv nginx -y && pip3 install uwsgi
python3 -m venv /home/ubuntu/app && source /home/ubuntu/app/bin/activate
pip3 install django
git clone https://github.com/nizar-dev01/baby-django.git /home/ubuntu/baby-django
cp /home/ubuntu/baby-django /home/ubuntu/baby-django-bk
cp /home/ubuntu/baby-django/server.conf /etc/nginx/sites-available && ln -s /etc/nginx/sites-available/server.conf /etc/nginx/sites-enabled

sed -i 's/# server_names_hash_bucket_size 64;/server_names_hash_bucket_size 128;/g' /etc/nginx/nginx.conf
uwsgi --ini /home/ubuntu/baby-django/app_uwsgi.ini

mkdir /home/ubuntu/app/vassals

cp /home/ubuntu/baby-django/emperor.uwsgi.service /etc/systemd/system

systemctl enable emperor.uwsgi.service
systemctl start emperor.uwsgi.service
service nginx restart
exit 0