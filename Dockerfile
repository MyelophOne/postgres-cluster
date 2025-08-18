FROM citusdata/citus:alpine

RUN apk update \
	&& apk add --no-cache netcat-openbsd dos2unix postgresql-contrib gzip curl \
	&& rm -rf /var/cache/apk/*

COPY config/pg_hba.conf /etc/postgresql/pg_hba.conf
RUN dos2unix /etc/postgresql/pg_hba.conf \
	&& chown postgres:postgres /etc/postgresql/pg_hba.conf \
	&& chmod 600 /etc/postgresql/pg_hba.conf

COPY scripts/backup_runner.sh /usr/local/bin/backup_runner.sh
RUN dos2unix /usr/local/bin/backup_runner.sh \
	&& chmod +x /usr/local/bin/backup_runner.sh

COPY scripts/backup_restore.sh /usr/local/bin/backup_restore.sh
RUN dos2unix /usr/local/bin/backup_restore.sh \
	&& chmod +x /usr/local/bin/backup_restore.sh

COPY scripts/register_worker.sh /usr/local/bin/register_worker.sh
RUN dos2unix /usr/local/bin/register_worker.sh \
	&& chmod +x /usr/local/bin/register_worker.sh
