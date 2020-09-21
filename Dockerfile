FROM python:3.8-slim AS build-image

RUN apt update
RUN apt install -y --no-install-recommends \
    build-essential \
    curl \
    default-libmysqlclient-dev \
    libpq-dev \
    unixodbc-dev \
    unzip

ADD . /srcdir
RUN python3 -m venv /virtualenv
ENV PATH="/virtualenv/bin:$PATH"
RUN pip install --upgrade pip
RUN pip install \
    /srcdir \
    cx-Oracle \
    ibm-db-sa \
    mysqlclient \
    psycopg2 \
    pyodbc

RUN curl \
    https://download.oracle.com/otn_software/linux/instantclient/185000/instantclient-basiclite-linux.x64-18.5.0.0.0dbru.zip?xd_co_f=91cb36af-209f-4d60-a84c-98c87fe76acd \
    -o instantclient.zip
RUN unzip instantclient.zip
RUN mkdir -p /opt/oracle/instantclient
RUN mv instantclient_18_5/* /opt/oracle/instantclient


FROM python:3.8-slim

RUN apt update
RUN apt install -y --no-install-recommends \
    libaio1 \
    libmariadb-dev-compat \
    libodbc1 \
    libpq5 \
    libxml2
COPY --from=build-image /virtualenv /virtualenv
COPY --from=build-image /opt /opt

ENV PATH="/virtualenv/bin:$PATH"
ENV VIRTUAL_ENV="/virtualenv"
ENV LD_LIBRARY_PATH="/opt/oracle/instantclient"

EXPOSE 9560/tcp
# IPv6 support is not enabled by default, only bind IPv4
ENTRYPOINT ["query-exporter", "/config.yaml", "-H", "0.0.0.0"]
