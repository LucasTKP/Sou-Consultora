// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/model/origem_foto.dart';
import 'package:sou_consultora/ui/widgets/dialog/folha_foto_app.dart';
import 'package:sou_consultora/ui/modules/perfil/widgets/foto_perfil/foto_perfil_cubit.dart';
import 'package:sou_consultora/ui/modules/perfil/widgets/foto_perfil/foto_perfil_state.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';

/// Foto grande da consultora (ou iniciais) com acesso à folha "Foto do perfil".
///
/// [comBotaoAlterar] mostra o botão "Alterar foto" (Editar perfil);
/// sem ele, o selo da câmera abre a folha (Meu perfil).
class FotoPerfil extends StatelessWidget {
  const FotoPerfil({super.key, this.comBotaoAlterar = false});

  final bool comBotaoAlterar;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FotoPerfilCubit(),
      child: _FotoPerfilVista(comBotaoAlterar: comBotaoAlterar),
    );
  }
}

class _FotoPerfilVista extends StatelessWidget {
  const _FotoPerfilVista({required this.comBotaoAlterar});

  final bool comBotaoAlterar;

  Future<void> _abrirFolha(BuildContext context, bool temFoto) async {
    final cubit = context.read<FotoPerfilCubit>();
    final acao = await FolhaFotoApp.mostrar(
      context,
      titulo: 'Foto do Perfil',
      temFoto: temFoto,
    );
    switch (acao) {
      case null:
        return;
      case AcaoFoto.camera:
        await cubit.trocar(OrigemFoto.camera);
      case AcaoFoto.galeria:
        await cubit.trocar(OrigemFoto.galeria);
      case AcaoFoto.remover:
        await cubit.remover();
    }
  }

  void _mostrarErro(BuildContext context, FotoPerfilState estado) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(estado.erro!),
          behavior: SnackBarBehavior.floating,
        ),
      );
    context.read<FotoPerfilCubit>().limparErro();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FotoPerfilCubit, FotoPerfilState>(
      listenWhen: (_, depois) => depois.erro != null,
      listener: _mostrarErro,
      builder: (context, estado) {
        void abrir() => _abrirFolha(context, estado.temFoto);
        return Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _Quadro(estado: estado),
                if (!comBotaoAlterar)
                  Positioned(
                    right: -8,
                    bottom: -8,
                    child: _SeloCamera(
                      onTap: estado.processando ? null : abrir,
                    ),
                  ),
              ],
            ),
            if (comBotaoAlterar) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: estado.processando ? null : abrir,
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text('Alterar foto'),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Quadro extends StatelessWidget {
  const _Quadro({required this.estado});

  final FotoPerfilState estado;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 136,
      height: 136,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: CoresApp.primariaSuave,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFF0D3DD), width: 2),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _iniciais(),
          if (estado.urlFoto != null)
            Image.network(
              estado.urlFoto!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _iniciais(),
            ),
          if (estado.processando)
            const ColoredBox(
              color: Color(0x88FFFFFF),
              child: Center(
                child: CircularProgressIndicator(color: CoresApp.primaria),
              ),
            ),
        ],
      ),
    );
  }

  Widget _iniciais() {
    return Center(
      child: Text(
        estado.iniciais,
        style: const TextStyle(
          fontSize: 52,
          fontWeight: FontWeight.w800,
          color: CoresApp.primariaEscura,
        ),
      ),
    );
  }
}

class _SeloCamera extends StatelessWidget {
  const _SeloCamera({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Alterar foto',
      child: Material(
        color: CoresApp.primaria,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: CoresApp.superficie, width: 3),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: Icon(
              Icons.photo_camera_outlined,
              color: CoresApp.sobrePrimaria,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
