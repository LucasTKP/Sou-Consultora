-- Formatos dos dados da consultora — Sou Consultora
-- WhatsApp guardado só com dígitos (DDD + 8 ou 9 dígitos).
-- Chave Pix e tipo existem juntos (ambos preenchidos ou ambos vazios).

alter table public.consultoras
  add constraint consultoras_whatsapp_digitos check (whatsapp ~ '^[0-9]{10,11}$'),
  add constraint consultoras_pix_completo check ((chave_pix is null) = (tipo_chave_pix is null));
