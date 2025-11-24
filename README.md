# GS Cloud – Ambiente Docker (Oracle + API Java)

Este projeto define, via **Docker Compose**, um ambiente completo para a Global Solution:

- Banco de dados **Oracle XE 21c** (imagem `gvenzl/oracle-xe:21-slim`)
- API Java 17 (**JavaGS**) rodando em container separado
- Inicialização automática do esquema de banco e dados de exemplo

> Tudo é orquestrado a partir de um **único** `docker-compose.yml` na pasta raiz do projeto.

---

## 1. Estrutura de pastas

```text
gs-stack/ (repositório gs-cloud)
├── docker-compose.yml          # Compose global (Oracle + API Java)
├── oracledb/
│   └── db-init/
│       ├── gs_schema.sql       # DDL + inserts iniciais do banco
│       └── 01_run_gs_schema.sh # Script que chama o gs_schema.sql na inicialização
└── JavaGS/                     # Projeto da API Java (Spring Boot)
    ├── Dockerfile              # Dockerfile da API
    └── ...                     # código fonte (pom.xml, src/, etc.)
```

---

## 2. Pré-requisitos

- Docker instalado
- Docker Compose instalado (v1 ou v2)
- Git instalado (para clonar o repositório)

---

## 3. Clonar o repositório

```bash
git clone https://github.com/bmvck/gs-cloud.git
cd gs-cloud   # ou gs-stack, dependendo do nome local
```

Certifique-se de estar na pasta onde está o `docker-compose.yml`.

---

## 4. Subir o ambiente

Na pasta raiz do projeto:

```bash
docker-compose up -d --build
```

O que esse comando faz:

1. Cria a rede Docker padrão do projeto.
2. Sobe o container **Oracle XE** (`gs-oracle`).
3. Monta o diretório `./oracledb/db-init` em `/docker-entrypoint-initdb.d` dentro do Oracle.
4. Na **primeira inicialização**, o Oracle executa:
   - `01_run_gs_schema.sh` → que chama
   - `gs_schema.sql` → cria o schema, tabelas, constraints, sequences e insere dados de exemplo.
5. Constrói a imagem da **API Java 17** com base no `Dockerfile` de `JavaGS/`.
6. Sobe o container **gs-api-java**, que expõe a API na porta `8080`.

Para acompanhar os logs na primeira subida:

```bash
docker logs -f gs-oracle    # logs do banco
docker logs -f gs-api-java  # logs da API
```

---

## 5. Serviços e portas

### Oracle XE

- **Imagem:** `gvenzl/oracle-xe:21-slim`
- **Container:** `gs-oracle`
- **Porta externa:** `1521` (mapeada para `1521` do container)
- **Banco / PDB:** `GSDB`
- **Usuário de aplicação:** `GSUSER`
- **Senha do usuário de aplicação:** `gspassword`
- **Senha SYS/SYSTEM:** `gspassword` (apenas para desenvolvimento)

Conexão típica (SQL Developer / cliente JDBC):

- **Host:** IP público da VM ou `localhost` (se rodando localmente)
- **Porta:** `1521`
- **Service Name:** `GSDB`
- **Usuário:** `GSUSER`
- **Senha:** `gspassword`

### API Java (JavaGS)

- **Base de código:** pasta `JavaGS/`
- **Imagem base de runtime:** `eclipse-temurin:17-jre-jammy`
- **Container:** `gs-api-java`
- **Porta externa:** `8080` (mapeada para `8080` do container)
- **Depende de:** `oracledb` (a API só sobe depois de o banco estar disponível)

A API fica acessível em:

```text
http://9.169.156.28:8080
```

Swagger configurado no projeto em:

```text
http://9.169.156.28:8080/swagger-ui.html
```

---

## 6. Detalhes do Docker Compose

Trecho principal do `docker-compose.yml`:

```yaml
version: "3.9"

services:
  oracledb:
    image: gvenzl/oracle-xe:21-slim
    container_name: gs-oracle
    restart: always
    environment:
      ORACLE_PASSWORD: gspassword
      ORACLE_DATABASE: GSDB
      APP_USER: GSUSER
      APP_USER_PASSWORD: gspassword
      TZ: America/Sao_Paulo
    ports:
      - "1521:1521"
    volumes:
      - oracle_data:/opt/oracle/oradata
      - ./oracledb/db-init:/docker-entrypoint-initdb.d

  api-java:
    build:
      context: ./JavaGS
      dockerfile: Dockerfile
    container_name: gs-api-java
    restart: always
    depends_on:
      - oracledb
    environment:
      DATABASE_HOST: oracledb
      DATABASE_USER: GSUSER
      DATABASE_PASSWORD: gspassword
      PROFILE: dev
    ports:
      - "8080:8080"

volumes:
  oracle_data:
```

### Inicialização do banco (`db-init`)

A pasta `oracledb/db-init` é montada dentro do container Oracle em:

```text
/docker-entrypoint-initdb.d
```

Qualquer arquivo nessa pasta é executado automaticamente **apenas na primeira inicialização** do banco (quando o volume `oracle_data` ainda está vazio).

- `01_run_gs_schema.sh` chama o `sqlplus` apontando para o PDB `GSDB` com o usuário `GSUSER`.
- `gs_schema.sql` contém:
  - criação de tabelas,
  - constraints,
  - sequences,
  - inserts de dados de exemplo.

Depois que o banco é inicializado uma vez, os dados ficam armazenados no volume `oracle_data` e não são recriados nas próximas subidas (a menos que você faça um `docker-compose down -v`).

---

## 7. Ciclo de desenvolvimento

### Subir o ambiente

```bash
docker-compose up -d
```

### Ver containers ativos

```bash
docker ps
```

### Parar o ambiente (mantendo dados do banco)

```bash
docker-compose down
```

### Parar o ambiente **apagando dados do banco** (recria tudo na próxima subida)

```bash
docker-compose down -v
```

Depois de um `down -v`, na próxima subida (`up -d --build`) o Oracle vai rodar novamente os scripts em `oracledb/db-init` e recriar o schema + dados de exemplo.

---

## 8. Atualizar código da API Java

Quando você alterar o código em `JavaGS/`:

1. Salve as mudanças.
2. Rebuild da imagem da API:

   ```bash
   cd gs-stack   # raiz do projeto
   docker-compose up -d --build api-java
   ```

3. Os demais serviços (como o banco) continuam rodando normalmente.

---

## 9. Possíveis extensões

A partir desse compose, você pode:

- Adicionar um container de **Node-RED** integrado com a API e/ou com o Oracle.
- Incluir outros serviços (ex.: frontend, serviços de IoT, etc.).
- Configurar variáveis de ambiente/schemas diferentes para ambientes de dev/homolog/produção.

---

## 10. Problemas comuns

- **Não consigo acessar a API em `http://IP:8080`**  
  - Verifique se o container `gs-api-java` está `Up`:
    ```bash
    docker ps
    ```
  - Verifique se a porta 8080 está liberada no firewall/NSG (no caso de cloud, como Azure).

- **Erro de conexão no banco na API**  
  - Confirme se o container `gs-oracle` está rodando.
  - Confirme se o host do banco na API está como `oracledb` (nome do serviço no docker-compose).
  - Teste um `SELECT table_name FROM user_tables;` logando como `GSUSER` para garantir que as tabelas foram criadas.

---

Qualquer nova API ou serviço Docker que for adicionado deve ser incluído neste mesmo `docker-compose.yml`, mantendo o projeto **GS Cloud** centralizado e fácil de subir com apenas um comando.
