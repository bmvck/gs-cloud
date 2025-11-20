-- DROPS SE EXISTIR -------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'DROP TABLE leitura_iot CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN NULL; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE dispositivo_iot CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN NULL; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE manutencao CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN NULL; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE historico CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN NULL; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE emprestimo CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN NULL; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE ativo CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN NULL; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE categoria CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN NULL; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE colaborador CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN NULL; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_leitura_iot';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -2289 THEN NULL; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_dispositivo_iot';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -2289 THEN NULL; END IF; END;
/

-- TABELAS PRINCIPAIS -----------------------------------------------
CREATE TABLE categoria (
  id_categ     NUMBER(4)    NOT NULL,
  nome_categ   VARCHAR2(50) NOT NULL,
  desc_categ   VARCHAR2(200)
);
ALTER TABLE categoria ADD CONSTRAINT categoria_pk PRIMARY KEY (id_categ);

CREATE TABLE ativo (
  id_ativo             NUMBER(3)    NOT NULL,
  marca                VARCHAR2(50) NOT NULL,
  modelo               VARCHAR2(50),
  numero_serie         VARCHAR2(50),
  status               CHAR(3)      NOT NULL,
  data_aquisicao       DATE         NOT NULL,
  data_ult_atualizacao DATE,
  categoria_id_categ   NUMBER(4)    NOT NULL
);
ALTER TABLE ativo ADD CONSTRAINT ativo_pk PRIMARY KEY (id_ativo);

CREATE TABLE colaborador (
  id_colab      NUMBER(10)    NOT NULL,
  nome_colab    VARCHAR2(100) NOT NULL,
  cpf_colab     CHAR(11),
  email_colab   VARCHAR2(80)  NOT NULL,
  tel_colab     VARCHAR2(16),
  status_colab  CHAR(3)       DEFAULT 'ATV' NOT NULL,
  funcao_colab  VARCHAR2(30),
  area_colab    VARCHAR2(50),
  responsavel   NUMBER(10),
  empresa       VARCHAR2(100),
  ramal_interno CHAR(4),
  senha         VARCHAR2(255),
  role          VARCHAR2(20)  DEFAULT 'USER'
);
ALTER TABLE colaborador ADD CONSTRAINT colaborador_pk PRIMARY KEY (id_colab);
ALTER TABLE colaborador ADD CONSTRAINT colaborador_email_uk UNIQUE (email_colab);

CREATE TABLE emprestimo (
  id_emprestimo        NUMBER(5)    NOT NULL,
  data_emprestimo      DATE         NOT NULL,
  data_devolucao       DATE,
  status_emprestimo    VARCHAR2(30) NOT NULL,
  ativo_id_ativo       NUMBER(3)    NOT NULL,
  colaborador_id_colab NUMBER(10)   NOT NULL
);
ALTER TABLE emprestimo ADD CONSTRAINT emprestimo_pk PRIMARY KEY (id_emprestimo);

CREATE TABLE historico (
  id_historico         NUMBER(5)    NOT NULL,
  data_movimentacao    DATE         DEFAULT SYSDATE NOT NULL,
  tipo_movimentacao    VARCHAR2(50) NOT NULL,
  descricao_moviment   VARCHAR2(200),
  ativo_id_ativo       NUMBER(3)    NOT NULL,
  colaborador_id_colab NUMBER(10)   NOT NULL
);
ALTER TABLE historico ADD CONSTRAINT historico_pk PRIMARY KEY (id_historico);

CREATE TABLE manutencao (
  id_manutencao   NUMBER(5)    NOT NULL,
  tipo_manutencao VARCHAR2(30) NOT NULL,
  data_inicio     DATE         NOT NULL,
  data_fim        DATE,
  custo           NUMBER(8,2),
  descricao       VARCHAR2(200),
  ativo_id_ativo  NUMBER(3)    NOT NULL
);
ALTER TABLE manutencao ADD CONSTRAINT manutencao_pk PRIMARY KEY (id_manutencao);

ALTER TABLE ativo       ADD CONSTRAINT ativo_categoria_fk   FOREIGN KEY (categoria_id_categ)   REFERENCES categoria (id_categ);
ALTER TABLE emprestimo  ADD CONSTRAINT emprestimo_ativo_fk  FOREIGN KEY (ativo_id_ativo)       REFERENCES ativo (id_ativo);
ALTER TABLE emprestimo  ADD CONSTRAINT emprestimo_colab_fk  FOREIGN KEY (colaborador_id_colab) REFERENCES colaborador (id_colab);
ALTER TABLE historico   ADD CONSTRAINT historico_ativo_fk   FOREIGN KEY (ativo_id_ativo)       REFERENCES ativo (id_ativo);
ALTER TABLE historico   ADD CONSTRAINT historico_colab_fk   FOREIGN KEY (colaborador_id_colab) REFERENCES colaborador (id_colab);
ALTER TABLE manutencao  ADD CONSTRAINT manutencao_ativo_fk  FOREIGN KEY (ativo_id_ativo)       REFERENCES ativo (id_ativo);

-- TABELAS IOT ------------------------------------------------------
CREATE TABLE dispositivo_iot (
  id_disp          NUMBER(5)      NOT NULL,
  identificador_hw VARCHAR2(50)   NOT NULL,
  descricao        VARCHAR2(100),
  data_cadastro    DATE           DEFAULT SYSDATE NOT NULL,
  status_disp      VARCHAR2(20)   DEFAULT 'ONLINE',
  ativo_id_ativo   NUMBER(3)      NOT NULL
);
ALTER TABLE dispositivo_iot ADD CONSTRAINT dispositivo_iot_pk PRIMARY KEY (id_disp);
ALTER TABLE dispositivo_iot ADD CONSTRAINT dispositivo_iot_identificador_uk UNIQUE (identificador_hw);
ALTER TABLE dispositivo_iot ADD CONSTRAINT dispositivo_iot_ativo_fk FOREIGN KEY (ativo_id_ativo) REFERENCES ativo (id_ativo);

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
ALTER TABLE leitura_iot ADD CONSTRAINT leitura_iot_pk PRIMARY KEY (id_leitura);
ALTER TABLE leitura_iot ADD CONSTRAINT leitura_iot_disp_fk FOREIGN KEY (dispositivo_id) REFERENCES dispositivo_iot (id_disp);

-- SEQUENCES --------------------------------------------------------
CREATE SEQUENCE seq_dispositivo_iot START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_leitura_iot     START WITH 1 INCREMENT BY 1 NOCACHE;

-- TRIGGER ----------------------------------------------------------
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
-- DADOS DE TESTE ---------------------------------------------------

INSERT INTO categoria VALUES (10, 'Notebook',  'Equipamentos de informática portáteis');
INSERT INTO categoria VALUES (20, 'Desktop',   'Estações de trabalho fixas');
INSERT INTO categoria VALUES (30, 'Periférico','Monitores, teclados, mouses');
INSERT INTO categoria VALUES (40, 'Ferramenta','Ferramentas elétricas e manuais');

INSERT INTO ativo VALUES (1, 'Dell',   'Latitude 5410', 'LAT5410-001', 'ATV', TO_DATE('2023-01-15','YYYY-MM-DD'), NULL, 10);
INSERT INTO ativo VALUES (2, 'Lenovo', 'ThinkPad E14',  'E14-002',     'ATV', TO_DATE('2023-03-10','YYYY-MM-DD'), NULL, 10);
INSERT INTO ativo VALUES (3, 'HP',     'ProDesk 400',   'PD400-003',   'ATV', TO_DATE('2022-11-05','YYYY-MM-DD'), NULL, 20);
INSERT INTO ativo VALUES (4, 'Bosch',  'Furadeira GSB', 'BOSCH-004',   'ATV', TO_DATE('2022-06-20','YYYY-MM-DD'), NULL, 40);

-- Senhas padrão: admin123 (serão criptografadas pelo BCrypt na aplicação)
-- Hash BCrypt de "admin123": $2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy
INSERT INTO colaborador VALUES (1001, 'Ana Souza',   '12345678901', 'ana.souza@empresa.com',   '11999990001', 'ATV', 'Analista de TI', 'Tecnologia', NULL,  'Empresa X', '1001', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'USER');
INSERT INTO colaborador VALUES (1002, 'Bruno Lima',  '23456789012', 'bruno.lima@empresa.com',  '11999990002', 'ATV', 'Coordenador TI', 'Tecnologia', 1001, 'Empresa X', '1002', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'ADMIN');
INSERT INTO colaborador VALUES (1003, 'Carlos Silva','34567890123','carlos.silva@empresa.com','11999990003','ATV','Analista Infra',  'Infra',       1002, 'Empresa X', '1003', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'USER');

INSERT INTO emprestimo VALUES (5001, TO_DATE('2024-11-01','YYYY-MM-DD'), NULL,                          'EM_USO',    1, 1001);
INSERT INTO emprestimo VALUES (5002, TO_DATE('2024-10-15','YYYY-MM-DD'), TO_DATE('2024-10-20','YYYY-MM-DD'), 'DEVOLVIDO', 3, 1003);

INSERT INTO historico VALUES (6001, SYSDATE - 20, 'EMPRESTIMO', 'Ativo 1 emprestado para Ana Souza', 1, 1001);
INSERT INTO historico VALUES (6002, SYSDATE - 15, 'DEVOLUCAO',  'Ativo 3 devolvido por Carlos Silva', 3, 1003);

INSERT INTO manutencao VALUES (7001, 'Preventiva', TO_DATE('2024-09-01','YYYY-MM-DD'), TO_DATE('2024-09-02','YYYY-MM-DD'), 250.00, 'Limpeza e troca de pasta térmica - Dell Latitude', 1);
INSERT INTO manutencao VALUES (7002, 'Corretiva',  TO_DATE('2024-08-10','YYYY-MM-DD'), TO_DATE('2024-08-15','YYYY-MM-DD'), 480.00, 'Troca de fonte - HP ProDesk', 3);

INSERT INTO dispositivo_iot VALUES (seq_dispositivo_iot.NEXTVAL, 'ESP32-ABC-001', 'Sensor notebook 1', SYSDATE, 'ONLINE', 1);
INSERT INTO dispositivo_iot VALUES (seq_dispositivo_iot.NEXTVAL, 'ESP32-DEF-002', 'Sensor desktop 3',  SYSDATE, 'ONLINE', 3);

INSERT INTO leitura_iot VALUES (seq_leitura_iot.NEXTVAL, 1, SYSDATE, 0.0010,-0.0030,1.0000,0,0,0,1,0,'EMP','Notebook em uso na mesa');
INSERT INTO leitura_iot VALUES (seq_leitura_iot.NEXTVAL, 2, SYSDATE, 0.0100,0.0050,1.0050,0.1,0.1,0.1,0,0,'ATV','Desktop estável no rack');

COMMIT;
