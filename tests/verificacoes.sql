-- Verificações das regras do modelo. Qualquer falha interrompe com erro.
USE ecommerce;

DELIMITER $$

CREATE PROCEDURE espera_erro(IN descricao VARCHAR(200), IN comando TEXT)
BEGIN
  DECLARE falhou BOOLEAN DEFAULT FALSE;
  BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET falhou = TRUE;
    SET @comando = comando;
    PREPARE stmt FROM @comando;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END;
  IF NOT falhou THEN
    SET @msg = CONCAT('FALHOU (deveria ser recusado): ', descricao);
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @msg;
  END IF;
  SELECT CONCAT('ok  ', descricao) AS resultado;
END$$

CREATE PROCEDURE espera_igual(IN descricao VARCHAR(200), IN obtido VARCHAR(100), IN esperado VARCHAR(100))
BEGIN
  IF NOT (obtido <=> esperado) THEN
    SET @msg = CONCAT('FALHOU: ', descricao, ' (obtido ', COALESCE(obtido, 'NULL'), ', esperado ', COALESCE(esperado, 'NULL'), ')');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @msg;
  END IF;
  SELECT CONCAT('ok  ', descricao) AS resultado;
END$$

DELIMITER ;

-- PF ou PJ, nunca os dois
CALL espera_erro('cliente PF não ganha cadastro de PJ',
  "INSERT INTO cliente_pj (cliente_id, razao_social, cnpj) VALUES (1, 'Ana ME', '11111111000191')");
CALL espera_erro('cliente PJ não ganha cadastro de PF',
  "INSERT INTO cliente_pf (cliente_id, nome, cpf) VALUES (3, 'Dono', '11111111111')");
CALL espera_erro('não dá para forçar o tipo na tabela de PF',
  "INSERT INTO cliente_pf (cliente_id, tipo, nome, cpf) VALUES (3, 'PJ', 'Dono', '11111111111')");
INSERT INTO cliente (id, tipo, email, endereco) VALUES (90, 'PF', 'teste@x.com', 'Rua X');
CALL espera_erro('CPF precisa ter 11 dígitos',
  "INSERT INTO cliente_pf (cliente_id, nome, cpf) VALUES (90, 'X', '1234567890')");
CALL espera_erro('CPF com letras é recusado',
  "INSERT INTO cliente_pf (cliente_id, nome, cpf) VALUES (90, 'X', '1234567890A')");
INSERT INTO cliente (id, tipo, email, endereco) VALUES (91, 'PJ', 'teste-pj@x.com', 'Rua Y');
CALL espera_erro('CNPJ repetido é recusado',
  "INSERT INTO cliente_pj (cliente_id, razao_social, cnpj) VALUES (91, 'Y', '12345678000195')");

-- Formas de pagamento
CALL espera_igual('a Ana tem duas formas de pagamento',
  (SELECT COUNT(*) FROM forma_pagamento WHERE cliente_id = 1), '2');
CALL espera_igual('o pedido 1 foi pago com duas formas',
  (SELECT COUNT(DISTINCT forma_pagamento_id) FROM pagamento WHERE pedido_id = 1), '2');
CALL espera_igual('o pagamento do pedido 1 fecha com o total',
  (SELECT SUM(valor) FROM pagamento WHERE pedido_id = 1), (SELECT total FROM vw_pedido_total WHERE pedido_id = 1));
CALL espera_erro('cartão sem final é recusado',
  "INSERT INTO forma_pagamento (cliente_id, tipo, apelido) VALUES (2, 'cartao_credito', 'Sem dados')");
CALL espera_erro('Pix não guarda dados de cartão',
  "INSERT INTO forma_pagamento (cliente_id, tipo, apelido, final_cartao) VALUES (2, 'pix', 'Pix', '1234')");
CALL espera_erro('não se paga pedido com a forma de outro cliente',
  "INSERT INTO pagamento (pedido_id, forma_pagamento_id, valor) VALUES (3, 1, 10)");
UPDATE forma_pagamento SET ativa = FALSE WHERE id = 3;
CALL espera_erro('forma de pagamento inativa não é aceita',
  "INSERT INTO pagamento (pedido_id, forma_pagamento_id, valor) VALUES (3, 3, 10)");
UPDATE forma_pagamento SET ativa = TRUE WHERE id = 3;

-- Entrega
CALL espera_igual('a entrega guarda status e código de rastreio',
  (SELECT CONCAT(status, ' ', codigo_rastreio) FROM entrega WHERE pedido_id = 1), 'entregue BR123456789SP');
CALL espera_erro('entrega a caminho precisa de código de rastreio',
  "UPDATE entrega SET status = 'enviado' WHERE pedido_id = 3");
CALL espera_erro('código de rastreio não se repete',
  "UPDATE entrega SET codigo_rastreio = 'BR123456789SP' WHERE pedido_id = 2");
CALL espera_erro('não se entrega antes de enviar',
  "UPDATE entrega SET entregue_em = '2026-10-01' WHERE pedido_id = 1");
CALL espera_erro('um pedido tem uma entrega só',
  "INSERT INTO entrega (pedido_id) VALUES (1)");

-- Integridade geral
CALL espera_erro('pedido de cliente inexistente é recusado',
  "INSERT INTO pedido (cliente_id) VALUES (999)");
CALL espera_erro('item com quantidade zero é recusado',
  "INSERT INTO item_pedido VALUES (3, 4, 0, 39.90)");

-- Respostas das consultas
CALL espera_igual('a Ana fez dois pedidos válidos',
  (SELECT COUNT(*) FROM pedido WHERE cliente_id = 1 AND status <> 'cancelado'), '2');
CALL espera_igual('exatamente um vendedor também é fornecedor',
  (SELECT COUNT(*) FROM vendedor_terceiro v JOIN fornecedor f ON f.cnpj = v.documento), '1');
CALL espera_igual('total do pedido 6 = itens + frete',
  (SELECT total FROM vw_pedido_total WHERE pedido_id = 6), '4124.00');
CALL espera_igual('pedido pago bate com o valor aprovado',
  (SELECT SUM(valor) FROM pagamento WHERE pedido_id = 6 AND status = 'aprovado'), (SELECT total FROM vw_pedido_total WHERE pedido_id = 6));

DROP PROCEDURE espera_erro;
DROP PROCEDURE espera_igual;
SELECT 'todas as verificações passaram' AS resultado;
