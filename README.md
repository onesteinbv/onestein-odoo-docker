# Onestein odoo-docker
The Onestein Docker image of Odoo 12.0 for Ubuntu 18.04 (Bionic Beaver).

#### Install Docker and ensure that it starts after the reboot:
apt install docker.io

systemctl start docker

systemctl enable docker

#### Start a PostgreSQL server:
docker run -d -e POSTGRES_USER=odoo -e POSTGRES_PASSWORD=odoo -e POSTGRES_DB=postgres --name db postgres:11

#### Create Odoo image
docker build -t onestein-odoo .

#### Run Odoo instance:
docker run -p 8069:8069 --name onestein-odoo --link db:db -t onestein-odoo

#### Stop and restart an Odoo instance:
docker stop onestein-odoo

docker start -a onestein-odoo
