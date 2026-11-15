-- Dados de exemplo para explorar o modelo.
USE ecommerce;

INSERT INTO cliente (id, tipo, email, telefone, endereco) VALUES
  (1, 'PF', 'ana.souza@email.com', '11987654321', 'Rua das Flores, 120 - São Paulo/SP'),
  (2, 'PF', 'bruno.lima@email.com', '21998765432', 'Av. Atlântica, 455 - Rio de Janeiro/RJ'),
  (3, 'PJ', 'compras@padariaestrela.com.br', '3132104567', 'Rua do Comércio, 78 - Belo Horizonte/MG'),
  (4, 'PJ', 'financeiro@techsul.com.br', '5130401234', 'Av. Ipiranga, 2000 - Porto Alegre/RS');

INSERT INTO cliente_pf (cliente_id, nome, cpf, data_nascimento) VALUES
  (1, 'Ana Souza', '12345678909', '1992-04-17'),
  (2, 'Bruno Lima', '98765432100', '1988-11-02');

INSERT INTO cliente_pj (cliente_id, razao_social, nome_fantasia, cnpj) VALUES
  (3, 'Padaria Estrela Ltda', 'Padaria Estrela', '12345678000195'),
  (4, 'TechSul Comércio de Informática S.A.', 'TechSul', '98765432000110');

INSERT INTO fornecedor (id, razao_social, cnpj, contato) VALUES
  (1, 'Distribuidora Norte Ltda', '11222333000144', 'vendas@distnorte.com.br'),
  (2, 'Eletrônicos Brasil S.A.', '55666777000188', 'comercial@eletrobr.com.br');

INSERT INTO vendedor_terceiro (id, razao_social, documento, local) VALUES
  (1, 'Loja do Zé Eletrônicos', '33444555000166', 'Campinas/SP'),
  (2, 'Carla Mendes Artesanato', '11122233396', 'Recife/PE'),
  -- Este vendedor do marketplace também é fornecedor da loja (mesmo CNPJ).
  (3, 'Eletrônicos Brasil S.A.', '55666777000188', 'Manaus/AM');

INSERT INTO produto (id, nome, categoria, descricao, preco) VALUES
  (1, 'Fone Bluetooth', 'Eletrônicos', 'Fone sem fio com cancelamento de ruído', 249.90),
  (2, 'Teclado Mecânico', 'Eletrônicos', 'Switch marrom, ABNT2', 389.00),
  (3, 'Caneca Artesanal', 'Casa', 'Cerâmica pintada à mão, 350 ml', 59.90),
  (4, 'Cabo USB-C 2 m', 'Acessórios', 'Carga rápida 60 W', 39.90);

INSERT INTO produto_fornecedor VALUES (1, 2), (2, 2), (4, 1), (4, 2);
INSERT INTO produto_vendedor VALUES (1, 1, 15), (3, 2, 40), (2, 3, 25);

INSERT INTO estoque (id, local) VALUES (1, 'CD Cajamar/SP'), (2, 'CD Recife/PE');
INSERT INTO produto_estoque VALUES (1, 1, 120), (2, 1, 45), (3, 2, 80), (4, 1, 500), (4, 2, 210);

-- Formas de pagamento: a Ana tem duas, a Padaria Estrela também.
INSERT INTO forma_pagamento (id, cliente_id, tipo, apelido, final_cartao, validade) VALUES
  (1, 1, 'cartao_credito', 'Nubank', '4821', '08/2029'),
  (2, 1, 'pix', 'Pix', NULL, NULL),
  (3, 2, 'cartao_debito', 'Itaú', '1937', '02/2028'),
  (4, 3, 'boleto', 'Boleto da empresa', NULL, NULL),
  (5, 3, 'cartao_credito', 'Cartão corporativo', '7710', '12/2027'),
  (6, 4, 'pix', 'Pix TechSul', NULL, NULL);

INSERT INTO pedido (id, cliente_id, status, frete, criado_em) VALUES
  (1, 1, 'pago', 19.90, '2026-10-02 10:15:00'),
  (2, 3, 'pago', 0.00, '2026-10-05 16:40:00'),
  (3, 2, 'aguardando_pagamento', 12.50, '2026-10-20 09:05:00'),
  (4, 4, 'cancelado', 25.00, '2026-10-21 14:30:00'),
  (5, 1, 'pago', 0.00, '2026-10-28 20:10:00'),
  (6, 4, 'pago', 35.00, '2026-11-02 11:00:00');

INSERT INTO item_pedido VALUES
  (1, 1, 1, 249.90),
  (1, 4, 2, 39.90),
  (2, 3, 12, 54.90),
  (3, 2, 1, 389.00),
  (4, 1, 3, 249.90),
  (5, 3, 2, 59.90),
  (6, 2, 10, 369.00),
  (6, 4, 10, 39.90);

-- O pedido 1 foi pago em duas partes: cartão e Pix.
INSERT INTO pagamento (pedido_id, forma_pagamento_id, valor, status) VALUES
  (1, 1, 200.00, 'aprovado'),
  (1, 2, 149.60, 'aprovado'),
  (2, 4, 658.80, 'aprovado'),
  (3, 3, 401.50, 'pendente'),
  (5, 2, 119.80, 'aprovado'),
  (6, 6, 4124.00, 'aprovado');

INSERT INTO entrega (pedido_id, status, codigo_rastreio, transportadora, enviado_em, entregue_em) VALUES
  (1, 'entregue', 'BR123456789SP', 'Correios', '2026-10-03 08:00:00', '2026-10-06 15:20:00'),
  (2, 'em_transito', 'JD000981234BR', 'Jadlog', '2026-10-06 11:00:00', NULL),
  (3, 'preparando', NULL, NULL, NULL, NULL),
  (5, 'entregue', 'BR555444333SP', 'Correios', '2026-10-29 09:00:00', '2026-11-01 10:30:00'),
  (6, 'saiu_para_entrega', 'LG771200345BR', 'Loggi', '2026-11-03 07:40:00', NULL);
