USE ecommerce;

-- 1. Quantos pedidos cada cliente fez, e quanto gastou? (junções, GROUP BY, derivado, ORDER BY)
SELECT c.id,
       COALESCE(pf.nome, pj.nome_fantasia) AS cliente,
       c.tipo,
       COUNT(p.id) AS pedidos,
       COALESCE(SUM(t.total), 0) AS valor_total
FROM cliente c
LEFT JOIN cliente_pf pf ON pf.cliente_id = c.id
LEFT JOIN cliente_pj pj ON pj.cliente_id = c.id
LEFT JOIN pedido p ON p.cliente_id = c.id AND p.status <> 'cancelado'
LEFT JOIN vw_pedido_total t ON t.pedido_id = p.id
GROUP BY c.id, cliente, c.tipo
ORDER BY pedidos DESC, valor_total DESC;

-- 2. Algum vendedor terceiro também é fornecedor? (junção pelo documento)
SELECT v.razao_social AS vendedor, f.razao_social AS fornecedor, f.cnpj
FROM vendedor_terceiro v
JOIN fornecedor f ON f.cnpj = v.documento;

-- 3. Relação de produtos, fornecedores e estoques. (várias junções)
SELECT pr.nome AS produto, f.razao_social AS fornecedor, e.local AS estoque, pe.quantidade
FROM produto pr
JOIN produto_fornecedor pf ON pf.produto_id = pr.id
JOIN fornecedor f ON f.id = pf.fornecedor_id
LEFT JOIN produto_estoque pe ON pe.produto_id = pr.id
LEFT JOIN estoque e ON e.id = pe.estoque_id
ORDER BY pr.nome, f.razao_social, e.local;

-- 4. Nomes dos fornecedores e dos produtos que cada um fornece. (junção + GROUP_CONCAT)
SELECT f.razao_social AS fornecedor, GROUP_CONCAT(pr.nome ORDER BY pr.nome SEPARATOR ', ') AS produtos
FROM fornecedor f
JOIN produto_fornecedor pf ON pf.fornecedor_id = f.id
JOIN produto pr ON pr.id = pf.produto_id
GROUP BY f.id, f.razao_social;

-- 5. Quais produtos custam mais de R$ 100, do mais caro ao mais barato? (WHERE, ORDER BY)
SELECT nome, categoria, preco
FROM produto
WHERE preco > 100
ORDER BY preco DESC;

-- 6. Quantas unidades de cada produto há no total, somando todos os estoques? (GROUP BY, HAVING)
SELECT pr.nome, SUM(pe.quantidade) AS unidades, COUNT(*) AS locais
FROM produto pr
JOIN produto_estoque pe ON pe.produto_id = pr.id
GROUP BY pr.id, pr.nome
HAVING SUM(pe.quantidade) >= 100
ORDER BY unidades DESC;

-- 7. Quanto cada pedido vale, com subtotal, frete e o preço médio por item? (derivados)
SELECT p.id AS pedido,
       SUM(i.quantidade) AS itens,
       SUM(i.quantidade * i.preco_unitario) AS subtotal,
       p.frete,
       SUM(i.quantidade * i.preco_unitario) + p.frete AS total,
       ROUND(SUM(i.quantidade * i.preco_unitario) / SUM(i.quantidade), 2) AS preco_medio_item
FROM pedido p
JOIN item_pedido i ON i.pedido_id = p.id
GROUP BY p.id, p.frete
ORDER BY total DESC;

-- 8. Quais clientes PJ compraram mais de R$ 1.000 em pedidos pagos? (junções, HAVING)
SELECT pj.razao_social, SUM(t.total) AS comprado
FROM cliente_pj pj
JOIN pedido p ON p.cliente_id = pj.cliente_id AND p.status = 'pago'
JOIN vw_pedido_total t ON t.pedido_id = p.id
GROUP BY pj.cliente_id, pj.razao_social
HAVING SUM(t.total) > 1000;

-- 9. Como cada cliente costuma pagar? (junção, agregação condicional)
SELECT c.id,
       COALESCE(pf.nome, pj.nome_fantasia) AS cliente,
       SUM(fp.tipo LIKE 'cartao%') AS cartoes,
       SUM(fp.tipo = 'pix') AS pix,
       SUM(fp.tipo = 'boleto') AS boletos
FROM cliente c
LEFT JOIN cliente_pf pf ON pf.cliente_id = c.id
LEFT JOIN cliente_pj pj ON pj.cliente_id = c.id
JOIN forma_pagamento fp ON fp.cliente_id = c.id AND fp.ativa
GROUP BY c.id, cliente
ORDER BY c.id;

-- 10. Quanto tempo as entregas concluídas levaram? (WHERE, derivado com datas)
SELECT p.id AS pedido, e.transportadora, e.codigo_rastreio,
       TIMESTAMPDIFF(HOUR, e.enviado_em, e.entregue_em) AS horas_em_transito
FROM entrega e
JOIN pedido p ON p.id = e.pedido_id
WHERE e.status = 'entregue'
ORDER BY horas_em_transito;
