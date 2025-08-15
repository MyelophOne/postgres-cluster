FROM citusdata/citus:alpine

RUN apk update \
	&& apk add --no-cache netcat-openbsd dos2unix postgresql-contrib \
	&& rm -rf /var/cache/apk/*

COPY init-extensions.sql /docker-entrypoint-initdb.d/init-extensions.sql

COPY init-pgpass.sh /docker-entrypoint-initdb.d/init-pgpass.sh
RUN dos2unix /docker-entrypoint-initdb.d/init-pgpass.sh \
	&& chmod +x /docker-entrypoint-initdb.d/init-pgpass.sh

COPY standby-init.sh /docker-entrypoint-initdb.d/standby-init.sh
RUN dos2unix /docker-entrypoint-initdb.d/standby-init.sh \
	&& chmod +x /docker-entrypoint-initdb.d/standby-init.sh

COPY pg_hba_master.sh /docker-entrypoint-initdb.d/pg_hba_master.sh
RUN dos2unix /docker-entrypoint-initdb.d/pg_hba_master.sh \
	&& chmod +x /docker-entrypoint-initdb.d/pg_hba_master.sh
