#!/bin/bash
echo ">> GS INIT: Executando gs_schema.sql como GSUSER em GSDB..."

sqlplus -s GSUSER/gspassword@localhost/GSDB @/docker-entrypoint-initdb.d/gs_schema.sql

echo ">> GS INIT: Concluído gs_schema.sql"
