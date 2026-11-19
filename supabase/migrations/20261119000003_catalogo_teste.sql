-- Carga de TESTE do catálogo: 20 produtos da Natura (fotos em catalogo/natura/<codigo>.jpg).
-- Será substituída pela carga completa por script quando houver autorização das marcas.
insert into public.catalogo_produtos (marca, codigo, nome, categoria, foto_caminho) values
  ('Natura', '174918', 'Balm labial cor ameixa', 'Maquiagem', 'natura/174918.jpg'),
  ('Natura', '285648', 'Balm multifuncional kriska amarena amore vinho 3 g', 'Maquiagem', 'natura/285648.jpg'),
  ('Natura', '285650', 'Balm multifuncional kriska cookie creme marrom 3 g', 'Maquiagem', 'natura/285650.jpg'),
  ('Natura', '285649', 'Balm multifuncional kriska donut delícia nude rosado 3 g', 'Maquiagem', 'natura/285649.jpg'),
  ('Natura', '134575', 'Natura Ekos Sabonete em Barra Puro Vegetal Cremoso Sortido 4 Unidades de 100 g', 'Corpo e banho', 'natura/134575.jpg'),
  ('Natura', '129797', 'Natura Ekos Sabonete em Barra Puro Vegetal Esfoliante Sortido Açaí Andiroba Maracujá e Castanha 4 Unidades de 100 g', 'Corpo e banho', 'natura/129797.jpg'),
  ('Natura', '97261', 'Natura Ekos Sabonete Líquido Esfoliante para o Corpo Açaí 185 ml', 'Corpo e banho', 'natura/97261.jpg'),
  ('Natura', '70405', 'Natura Ekos Sabonete Líquido Esfoliante para o Corpo Maracujá 185 ml', 'Corpo e banho', 'natura/70405.jpg'),
  ('Natura', '95841', 'Natura Tododia Body Splash Desodorante Colônia Cereja e Avelã 200 ml', 'Perfumaria', 'natura/95841.jpg'),
  ('Natura', '159712', 'Natura Tododia Body Splash Desodorante Colônia Chá de Camomila e Lavanda Feminino 200 ml', 'Perfumaria', 'natura/159712.jpg'),
  ('Natura', '152286', 'Natura Tododia Body Splash Desodorante Colônia Flor de Gengibre e Tangerina Feminino 200 ml', 'Perfumaria', 'natura/152286.jpg'),
  ('Natura', '196313', 'Natura Tododia Body Splash Desodorante Colônia Jambo Rosa e Flor de Caju 200 ml', 'Perfumaria', 'natura/196313.jpg'),
  ('Natura', '124955', 'Papai e bebê água de colônia', 'Infantil', 'natura/124955.jpg'),
  ('Natura', '55104', 'Pincel PRO base líquida', 'Maquiagem', 'natura/55104.jpg'),
  ('Natura', '55100', 'Pincel PRO blush', 'Maquiagem', 'natura/55100.jpg'),
  ('Natura', '264739', 'Presente Ilía com lata', 'Presentes', 'natura/264739.jpg'),
  ('Natura', '179453', 'Chro Serum Fac Mini Multicla 1', 'Cuidados com a pele', 'natura/179453.jpg'),
  ('Natura', '102412', 'Colônia Naturé Pula Corda', 'Infantil', 'natura/102412.jpg'),
  ('Natura', '271289', 'Combo Ecobag e Chaveiro Cpv', 'Presentes', 'natura/271289.jpg'),
  ('Natura', '270022', 'Combo Reg Ref Hidra Cacau', 'Corpo e banho', 'natura/270022.jpg')
on conflict (marca, codigo) do nothing;
