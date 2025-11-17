--------------------------------------------------------------------
-- 1) GARANTIR QUE O USUÁRIO GSUSER EXISTE
--------------------------------------------------------------------
DECLARE
  v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM   dba_users
  WHERE  username = 'GSUSER';

  IF v_count = 0 THEN
    EXECUTE IMMEDIATE
      'CREATE USER gsuser IDENTIFIED BY gspassword QUOTA UNLIMITED ON USERS';
    EXECUTE IMMEDIATE
      'GRANT CONNECT, RESOURCE TO gsuser';
  END IF;
END;
/
--------------------------------------------------------------------
-- 2) USAR O SCHEMA GSUSER PARA TUDO QUE VIER DEPOIS
--------------------------------------------------------------------
ALTER SESSION SET CURRENT_SCHEMA = GSUSER;
/

--------------------------------------------------------------------
-- 3) DROPS (SE EXISTIR) - IGNORA ERROS SE AINDA NÃO EXISTIR
--------------------------------------------------------------------
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE leitura_iot CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -942 THEN RAISE; END IF;
END;
/
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE dispositivo_iot CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -942 THEN RAISE; END IF;
END;
/
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE manutencao CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -942 THEN RAISE; END IF;
END;
/
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE historico CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -942 THEN RAISE; END IF;
END;
/
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE emprestimo CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -942 THEN RAISE; END IF;
END;
/
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE ativo CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -942 THEN RAISE; END IF;
END;
/
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE categoria CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -942 THEN RAISE; END IF;
END;
/
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE colaborador CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -942 THEN RAISE; END IF;
END;
/
BEGIN
  EXECUTE IMMEDIATE 'DROP SEQUENCE seq_leitura_iot';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -2289 THEN RAISE; END IF;
END;
/
BEGIN
  EXECUTE IMMEDIATE 'DROP SEQUENCE seq_dispositivo_iot';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -2289 THEN RAISE; END IF;
END;
/

--------------------------------------------------------------------
-- 4) TABELAS PRINCIPAIS (AGORA SEM PREFIXO DE SCHEMA)
--------------------------------------------------------------------
CREATE TABLE categoria (
    id_categ   NUMBER(4)   NOT NULL,
    nome_categ VARCHAR2(50) NOT NULL,
    desc_categ VARCHAR2(200)
);
ALTER TABLE categoria ADD CONSTRAINT categoria_pk PRIMARY KEY ( id_categ );

CREATE TABLE ativo (
    id_ativo             NUMBER(3)   NOT NULL,
    marca                VARCHAR2(50) NOT NULL,
    modelo               VARCHAR2(50),
    numero_serie         VARCHAR2(50),
    status               CHAR(3)      NOT NULL,
    data_aquisicao       DATE         NOT NULL,
    data_ult_atualizacao DATE,
    categoria_id_categ   NUMBER(4)    NOT NULL
);
ALTER TABLE ativo ADD CONSTRAINT ativo_pk PRIMARY KEY ( id_ativo );

CREATE TABLE colaborador (
    id_colab      NUMBER(10)   NOT NULL,
    nome_colab    VARCHAR2(100) NOT NULL,
    cpf_colab     CHAR(11),
    email_colab   VARCHAR2(80)  NOT NULL,
    tel_colab     VARCHAR2(16),
    status_colab  CHAR(3)       DEFAULT 'ATV' NOT NULL,
    funcao_colab  VARCHAR2(30),
    area_colab    VARCHAR2(50),
    responsavel   NUMBER(10),
    empresa       VARCHAR2(100),
    ramal_interno CHAR(4)
);
ALTER TABLE colaborador ADD CONSTRAINT colaborador_pk PRIMARY KEY ( id_colab );

CREATE TABLE emprestimo (
    id_emprestimo        NUMBER(5) NOT NULL,
    data_emprestimo      DATE      NOT NULL,
    data_devolucao       DATE,
    status_emprestimo    VARCHAR2(30) NOT NULL,
    ativo_id_ativo       NUMBER(3)    NOT NULL,
    colaborador_id_colab NUMBER(10)   NOT NULL
);
ALTER TABLE emprestimo ADD CONSTRAINT emprestimo_pk PRIMARY KEY ( id_emprestimo );

CREATE TABLE historico (
    id_historico         NUMBER(5) NOT NULL,
    data_movimentacao    DATE      DEFAULT SYSDATE NOT NULL,
    tipo_movimentacao    VARCHAR2(50) NOT NULL,
    descricao_moviment   VARCHAR2(200),
    ativo_id_ativo       NUMBER(3)  NOT NULL,
    colaborador_id_colab NUMBER(10) NOT NULL
);
ALTER TABLE historico ADD CONSTRAINT historico_pk PRIMARY KEY ( id_historico );

CREATE TABLE manutencao (
    id_manutencao   NUMBER(5) NOT NULL,
    tipo_manutencao VARCHAR2(30) NOT NULL,
    data_inicio     DATE NOT NULL,
    data_fim        DATE,
    custo           NUMBER(8, 2),
    descricao       VARCHAR2(200),
    ativo_id_ativo  NUMBER(3) NOT NULL
);
ALTER TABLE manutencao ADD CONSTRAINT manutencao_pk PRIMARY KEY ( id_manutencao );

ALTER TABLE ativo
  ADD CONSTRAINT ativo_categoria_fk FOREIGN KEY ( categoria_id_categ )
  REFERENCES categoria ( id_categ );

ALTER TABLE emprestimo
  ADD CONSTRAINT emprestimo_ativo_fk FOREIGN KEY ( ativo_id_ativo )
  REFERENCES ativo ( id_ativo );

ALTER TABLE emprestimo
  ADD CONSTRAINT emprestimo_colaborador_fk FOREIGN KEY ( colaborador_id_colab )
  REFERENCES colaborador ( id_colab );

ALTER TABLE historico
  ADD CONSTRAINT historico_ativo_fk FOREIGN KEY ( ativo_id_ativo )
  REFERENCES ativo ( id_ativo );

ALTER TABLE historico
  ADD CONSTRAINT historico_colaborador_fk FOREIGN KEY ( colaborador_id_colab )
  REFERENCES colaborador ( id_colab );

ALTER TABLE manutencao
  ADD CONSTRAINT manutencao_ativo_fk FOREIGN KEY ( ativo_id_ativo )
  REFERENCES ativo ( id_ativo );

--------------------------------------------------------------------
-- 5) TABELAS IOT
--------------------------------------------------------------------
CREATE TABLE dispositivo_iot (
    id_disp          NUMBER(5)      NOT NULL,
    identificador_hw VARCHAR2(50)   NOT NULL,
    descricao        VARCHAR2(100),
    data_cadastro    DATE           DEFAULT SYSDATE NOT NULL,
    status_disp      VARCHAR2(20)   DEFAULT 'ONLINE',
    ativo_id_ativo   NUMBER(3)      NOT NULL
);
ALTER TABLE dispositivo_iot
  ADD CONSTRAINT dispositivo_iot_pk PRIMARY KEY ( id_disp );
ALTER TABLE dispositivo_iot
  ADD CONSTRAINT dispositivo_iot_identificador_uk UNIQUE ( identificador_hw );
ALTER TABLE dispositivo_iot
  ADD CONSTRAINT dispositivo_iot_ativo_fk FOREIGN KEY ( ativo_id_ativo )
  REFERENCES ativo ( id_ativo );

CREATE TABLE leitura_iot (
    id_leitura      NUMBER(10)   NOT NULL,
    dispositivo_id  NUMBER(5)    NOT NULL,
    data_leitura    DATE         DEFAULT SYSDATE NOT NULL,
    acc_x           NUMBER(10,4),
    acc_y           NUMBER(10,4),
    acc_z           NUMBER(10,4),
    gyro_x          NUMBER(10,4),
    gyro_y          NUMBER(10,4),
    gyro_z          NUMBER(10,4),
    movimentado     NUMBER(1),
    choque          NUMBER(1),
    estado_ativo    VARCHAR2(30),
    observacao      VARCHAR2(200)
);
ALTER TABLE leitura_iot
  ADD CONSTRAINT leitura_iot_pk PRIMARY KEY ( id_leitura );
ALTER TABLE leitura_iot
  ADD CONSTRAINT leitura_iot_dispositivo_fk FOREIGN KEY ( dispositivo_id )
  REFERENCES dispositivo_iot ( id_disp );

--------------------------------------------------------------------
-- 6) SEQUENCES
--------------------------------------------------------------------
CREATE SEQUENCE seq_dispositivo_iot
  START WITH 1 INCREMENT BY 1 NOCACHE;

CREATE SEQUENCE seq_leitura_iot
  START WITH 1 INCREMENT BY 1 NOCACHE;

--------------------------------------------------------------------
-- 7) TRIGGER
--------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_leitura_iot_atualiza_ativo
AFTER INSERT ON leitura_iot
FOR EACH ROW
DECLARE
  v_ativo_id ativo.id_ativo%TYPE;
BEGIN
  SELECT ativo_id_ativo
    INTO v_ativo_id
    FROM dispositivo_iot
   WHERE id_disp = :NEW.dispositivo_id;

  IF :NEW.estado_ativo IS NOT NULL THEN
    UPDATE ativo
       SET status               = :NEW.estado_ativo,
           data_ult_atualizacao = SYSDATE
     WHERE id_ativo = v_ativo_id;
  END IF;
END;
/
--------------------------------------------------------------------
-- 8) DADOS DE TESTE
--------------------------------------------------------------------
-- Categorias
INSERT INTO categoria (id_categ, nome_categ, desc_categ)
VALUES (10, 'Notebook',  'Equipamentos de informática portáteis');
INSERT INTO categoria (id_categ, nome_categ, desc_categ)
VALUES (20, 'Desktop',   'Estações de trabalho fixas');
INSERT INTO categoria (id_categ, nome_categ, desc_categ)
VALUES (30, 'Periférico','Monitores, teclados, mouses');
INSERT INTO categoria (id_categ, nome_categ, desc_categ)
VALUES (40, 'Ferramenta','Ferramentas elétricas e manuais');

-- Ativos
INSERT INTO ativo (id_ativo, marca, modelo, numero_serie, status,
                   data_aquisicao, categoria_id_categ)
VALUES (1, 'Dell',   'Latitude 5410', 'LAT5410-001', 'ATV',
        TO_DATE('2023-01-15','YYYY-MM-DD'), 10);
INSERT INTO ativo (id_ativo, marca, modelo, numero_serie, status,
                   data_aquisicao, categoria_id_categ)
VALUES (2, 'Lenovo', 'ThinkPad E14',  'E14-002', 'ATV',
        TO_DATE('2023-03-10','YYYY-MM-DD'), 10);
INSERT INTO ativo (id_ativo, marca, modelo, numero_serie, status,
                   data_aquisicao, categoria_id_categ)
VALUES (3, 'HP',     'ProDesk 400',   'PD400-003', 'ATV',
        TO_DATE('2022-11-05','YYYY-MM-DD'), 20);
INSERT INTO ativo (id_ativo, marca, modelo, numero_serie, status,
                   data_aquisicao, categoria_id_categ)
VALUES (4, 'Bosch',  'Furadeira GSB', 'BOSCH-004', 'ATV',
        TO_DATE('2022-06-20','YYYY-MM-DD'), 40);

-- Colaboradores
INSERT INTO colaborador (
  id_colab, nome_colab, cpf_colab, email_colab, tel_colab,
  status_colab, funcao_colab, area_colab, responsavel, empresa, ramal_interno
) VALUES (
  1001, 'Ana Souza',   '12345678901', 'ana.souza@empresa.com', '11999990001',
  'ATV', 'Analista de TI', 'Tecnologia', NULL, 'Empresa X', '1001'
);
INSERT INTO colaborador (
  id_colab, nome_colab, cpf_colab, email_colab, tel_colab,
  status_colab, funcao_colab, area_colab, responsavel, empresa, ramal_interno
) VALUES (
  1002, 'Bruno Lima',  '23456789012', 'bruno.lima@empresa.com', '11999990002',
  'ATV', 'Coordenador TI', 'Tecnologia', 1001, 'Empresa X', '1002'
);
INSERT INTO colaborador (
  id_colab, nome_colab, cpf_colab, email_colab, tel_colab,
  status_colab, funcao_colab, area_colab, responsavel, empresa, ramal_interno
) VALUES (
  1003, 'Carlos Silva','34567890123', 'carlos.silva@empresa.com','11999990003',
  'ATV', 'Analista Infra', 'Infra', 1002, 'Empresa X', '1003'
);

-- Empréstimos
INSERT INTO emprestimo (
  id_emprestimo, data_emprestimo, data_devolucao,
  status_emprestimo, ativo_id_ativo, colaborador_id_colab
) VALUES (
  5001, TO_DATE('2024-11-01','YYYY-MM-DD'), NULL,
  'EM_USO', 1, 1001
);
INSERT INTO emprestimo (
  id_emprestimo, data_emprestimo, data_devolucao,
  status_emprestimo, ativo_id_ativo, colaborador_id_colab
) VALUES (
  5002,
  TO_DATE('2024-10-15','YYYY-MM-DD'),
  TO_DATE('2024-10-20','YYYY-MM-DD'),
  'DEVOLVIDO', 3, 1003
);

-- Histórico
INSERT INTO historico (
  id_historico, data_movimentacao, tipo_movimentacao,
  descricao_moviment, ativo_id_ativo, colaborador_id_colab
) VALUES (
  6001, SYSDATE - 20, 'EMPRESTIMO',
  'Ativo 1 emprestado para Ana Souza', 1, 1001
);
INSERT INTO historico (
  id_historico, data_movimentacao, tipo_movimentacao,
  descricao_moviment, ativo_id_ativo, colaborador_id_colab
) VALUES (
  6002, SYSDATE - 15, 'DEVOLUCAO',
  'Ativo 3 devolvido por Carlos Silva', 3, 1003
);

-- Manutenção
INSERT INTO manutencao (
  id_manutencao, tipo_manutencao, data_inicio, data_fim,
  custo, descricao, ativo_id_ativo
) VALUES (
  7001, 'Preventiva',
  TO_DATE('2024-09-01','YYYY-MM-DD'),
  TO_DATE('2024-09-02','YYYY-MM-DD'),
  250.00,
  'Limpeza interna e troca de pasta térmica - Dell Latitude', 1
);
INSERT INTO manutencao (
  id_manutencao, tipo_manutencao, data_inicio, data_fim,
  custo, descricao, ativo_id_ativo
) VALUES (
  7002, 'Corretiva',
  TO_DATE('2024-08-10','YYYY-MM-DD'),
  TO_DATE('2024-08-15','YYYY-MM-DD'),
  480.00,
  'Troca de fonte de alimentação - HP ProDesk', 3
);

-- Dispositivos IoT
INSERT INTO dispositivo_iot (
  id_disp, identificador_hw, descricao, data_cadastro,
  status_disp, ativo_id_ativo
) VALUES (
  seq_dispositivo_iot.NEXTVAL, 'ESP32-ABC-001',
  'Sensor de movimentação notebook 1', SYSDATE, 'ONLINE', 1
);
INSERT INTO dispositivo_iot (
  id_disp, identificador_hw, descricao, data_cadastro,
  status_disp, ativo_id_ativo
) VALUES (
  seq_dispositivo_iot.NEXTVAL, 'ESP32-DEF-002',
  'Sensor de movimentação desktop 3', SYSDATE, 'ONLINE', 3
);

-- Leituras IoT
INSERT INTO leitura_iot (
  id_leitura, dispositivo_id, data_leitura,
  acc_x, acc_y, acc_z, gyro_x, gyro_y, gyro_z,
  movimentado, choque, estado_ativo, observacao
) VALUES (
  seq_leitura_iot.NEXTVAL, 1, SYSDATE,
  0.0010, -0.0030, 1.0000, 0.0000, 0.0000, 0.0000,
  1, 0, 'EMP', 'Notebook em uso na mesa do colaborador'
);
INSERT INTO leitura_iot (
  id_leitura, dispositivo_id, data_leitura,
  acc_x, acc_y, acc_z, gyro_x, gyro_y, gyro_z,
  movimentado, choque, estado_ativo, observacao
) VALUES (
  seq_leitura_iot.NEXTVAL, 2, SYSDATE,
  0.0100, 0.0050, 1.0050, 0.1000, 0.1000, 0.1000,
  0, 0, 'ATV', 'Desktop estável no rack após verificação'
);

COMMIT;
