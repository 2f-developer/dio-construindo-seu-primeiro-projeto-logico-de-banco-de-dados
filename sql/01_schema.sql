-- E-commerce: modelo refinado com cliente PF/PJ, várias formas de pagamento e entrega rastreável.
-- MySQL 8.0.16+ (usa CHECK constraints).

DROP DATABASE IF EXISTS ecommerce;
CREATE DATABASE ecommerce CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE ecommerce;

-- Cliente -----------------------------------------------------------------
-- O tipo fica no próprio cliente e faz parte da chave referenciada pelas
-- tabelas de PF e PJ. Como cada uma só aceita o seu tipo, um cliente PF não
-- tem como ganhar uma linha em cliente_pj, e vice-versa.
CREATE TABLE cliente (
  id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tipo         ENUM('PF', 'PJ') NOT NULL,
  email        VARCHAR(120) NOT NULL UNIQUE,
  telefone     VARCHAR(20),
  endereco     VARCHAR(200) NOT NULL,
  criado_em    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_cliente_id_tipo (id, tipo)
);

CREATE TABLE cliente_pf (
  cliente_id       INT UNSIGNED PRIMARY KEY,
  tipo             ENUM('PF', 'PJ') NOT NULL DEFAULT 'PF',
  nome             VARCHAR(120) NOT NULL,
  cpf              CHAR(11) NOT NULL UNIQUE,
  data_nascimento  DATE,
  CONSTRAINT ck_pf_tipo CHECK (tipo = 'PF'),
  CONSTRAINT ck_pf_cpf CHECK (cpf REGEXP '^[0-9]{11}$'),
  CONSTRAINT fk_pf_cliente FOREIGN KEY (cliente_id, tipo) REFERENCES cliente (id, tipo) ON DELETE CASCADE
);

CREATE TABLE cliente_pj (
  cliente_id     INT UNSIGNED PRIMARY KEY,
  tipo           ENUM('PF', 'PJ') NOT NULL DEFAULT 'PJ',
  razao_social   VARCHAR(150) NOT NULL,
  nome_fantasia  VARCHAR(150),
  cnpj           CHAR(14) NOT NULL UNIQUE,
  CONSTRAINT ck_pj_tipo CHECK (tipo = 'PJ'),
  CONSTRAINT ck_pj_cnpj CHECK (cnpj REGEXP '^[0-9]{14}$'),
  CONSTRAINT fk_pj_cliente FOREIGN KEY (cliente_id, tipo) REFERENCES cliente (id, tipo) ON DELETE CASCADE
);

-- Catálogo, estoque e quem vende --------------------------------------------
CREATE TABLE fornecedor (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  razao_social  VARCHAR(150) NOT NULL,
  cnpj          CHAR(14) NOT NULL UNIQUE,
  contato       VARCHAR(120),
  CONSTRAINT ck_fornecedor_cnpj CHECK (cnpj REGEXP '^[0-9]{14}$')
);

CREATE TABLE vendedor_terceiro (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  razao_social  VARCHAR(150) NOT NULL,
  documento     VARCHAR(14) NOT NULL UNIQUE,
  local         VARCHAR(120),
  CONSTRAINT ck_vendedor_documento CHECK (documento REGEXP '^([0-9]{11}|[0-9]{14})$')
);

CREATE TABLE produto (
  id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nome       VARCHAR(120) NOT NULL,
  categoria  VARCHAR(60) NOT NULL,
  descricao  TEXT,
  preco      DECIMAL(10, 2) NOT NULL,
  CONSTRAINT ck_produto_preco CHECK (preco > 0)
);

CREATE TABLE produto_fornecedor (
  produto_id     INT UNSIGNED,
  fornecedor_id  INT UNSIGNED,
  PRIMARY KEY (produto_id, fornecedor_id),
  FOREIGN KEY (produto_id) REFERENCES produto (id) ON DELETE CASCADE,
  FOREIGN KEY (fornecedor_id) REFERENCES fornecedor (id)
);

CREATE TABLE produto_vendedor (
  produto_id   INT UNSIGNED,
  vendedor_id  INT UNSIGNED,
  quantidade   INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (produto_id, vendedor_id),
  FOREIGN KEY (produto_id) REFERENCES produto (id) ON DELETE CASCADE,
  FOREIGN KEY (vendedor_id) REFERENCES vendedor_terceiro (id)
);

CREATE TABLE estoque (
  id     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  local  VARCHAR(120) NOT NULL UNIQUE
);

CREATE TABLE produto_estoque (
  produto_id  INT UNSIGNED,
  estoque_id  INT UNSIGNED,
  quantidade  INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (produto_id, estoque_id),
  FOREIGN KEY (produto_id) REFERENCES produto (id) ON DELETE CASCADE,
  FOREIGN KEY (estoque_id) REFERENCES estoque (id)
);

-- Pedido ------------------------------------------------------------------
CREATE TABLE pedido (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  cliente_id  INT UNSIGNED NOT NULL,
  status      ENUM('aguardando_pagamento', 'pago', 'cancelado') NOT NULL DEFAULT 'aguardando_pagamento',
  frete       DECIMAL(10, 2) NOT NULL DEFAULT 0,
  criado_em   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT ck_pedido_frete CHECK (frete >= 0),
  FOREIGN KEY (cliente_id) REFERENCES cliente (id)
);

CREATE TABLE item_pedido (
  pedido_id       INT UNSIGNED,
  produto_id      INT UNSIGNED,
  quantidade      INT UNSIGNED NOT NULL,
  -- Preço copiado no momento da compra: mudar o catálogo não muda pedidos antigos.
  preco_unitario  DECIMAL(10, 2) NOT NULL,
  PRIMARY KEY (pedido_id, produto_id),
  CONSTRAINT ck_item_quantidade CHECK (quantidade > 0),
  CONSTRAINT ck_item_preco CHECK (preco_unitario > 0),
  FOREIGN KEY (pedido_id) REFERENCES pedido (id) ON DELETE CASCADE,
  FOREIGN KEY (produto_id) REFERENCES produto (id)
);

-- Pagamento ---------------------------------------------------------------
-- Formas de pagamento ficam cadastradas no cliente (pode haver várias) e um
-- pedido pode ser pago com mais de uma delas, cada uma com a sua parte.
CREATE TABLE forma_pagamento (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  cliente_id    INT UNSIGNED NOT NULL,
  tipo          ENUM('cartao_credito', 'cartao_debito', 'pix', 'boleto') NOT NULL,
  apelido       VARCHAR(40) NOT NULL,
  -- Só o final do cartão: o número completo nunca é guardado aqui.
  final_cartao  CHAR(4),
  validade      CHAR(7),
  ativa         BOOLEAN NOT NULL DEFAULT TRUE,
  -- Os IS NOT NULL são necessários: com NULL o REGEXP vira desconhecido e o CHECK deixaria passar.
  CONSTRAINT ck_forma_cartao CHECK (
    (tipo IN ('cartao_credito', 'cartao_debito')
      AND final_cartao IS NOT NULL AND final_cartao REGEXP '^[0-9]{4}$'
      AND validade IS NOT NULL AND validade REGEXP '^(0[1-9]|1[0-2])/[0-9]{4}$')
    OR (tipo IN ('pix', 'boleto') AND final_cartao IS NULL AND validade IS NULL)
  ),
  UNIQUE KEY uk_forma_cliente (id, cliente_id),
  FOREIGN KEY (cliente_id) REFERENCES cliente (id) ON DELETE CASCADE
);

CREATE TABLE pagamento (
  id                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pedido_id           INT UNSIGNED NOT NULL,
  forma_pagamento_id  INT UNSIGNED NOT NULL,
  valor               DECIMAL(10, 2) NOT NULL,
  status              ENUM('pendente', 'aprovado', 'recusado') NOT NULL DEFAULT 'pendente',
  CONSTRAINT ck_pagamento_valor CHECK (valor > 0),
  FOREIGN KEY (pedido_id) REFERENCES pedido (id) ON DELETE CASCADE,
  FOREIGN KEY (forma_pagamento_id) REFERENCES forma_pagamento (id)
);

-- Entrega -----------------------------------------------------------------
CREATE TABLE entrega (
  pedido_id        INT UNSIGNED PRIMARY KEY,
  status           ENUM('preparando', 'enviado', 'em_transito', 'saiu_para_entrega', 'entregue', 'devolvido') NOT NULL DEFAULT 'preparando',
  codigo_rastreio  VARCHAR(30) UNIQUE,
  transportadora   VARCHAR(80),
  enviado_em       DATETIME,
  entregue_em      DATETIME,
  -- Sem código de rastreio, o pedido não pode estar a caminho.
  CONSTRAINT ck_entrega_rastreio CHECK (status = 'preparando' OR codigo_rastreio IS NOT NULL),
  CONSTRAINT ck_entrega_datas CHECK (entregue_em IS NULL OR (enviado_em IS NOT NULL AND entregue_em >= enviado_em)),
  FOREIGN KEY (pedido_id) REFERENCES pedido (id) ON DELETE CASCADE
);

-- Regras que dependem de outras tabelas --------------------------------------
DELIMITER $$

-- A forma usada no pagamento precisa ser do próprio dono do pedido.
CREATE TRIGGER trg_pagamento_forma_do_cliente
BEFORE INSERT ON pagamento
FOR EACH ROW
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pedido p
    JOIN forma_pagamento f ON f.cliente_id = p.cliente_id
    WHERE p.id = NEW.pedido_id AND f.id = NEW.forma_pagamento_id AND f.ativa
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A forma de pagamento não pertence ao cliente do pedido ou está inativa.';
  END IF;
END$$

DELIMITER ;

-- Total do pedido calculado, para não ficar duplicado (e desatualizado) numa coluna.
CREATE VIEW vw_pedido_total AS
SELECT p.id AS pedido_id,
       p.cliente_id,
       COALESCE(SUM(i.quantidade * i.preco_unitario), 0) + p.frete AS total
FROM pedido p
LEFT JOIN item_pedido i ON i.pedido_id = p.id
GROUP BY p.id, p.cliente_id, p.frete;
