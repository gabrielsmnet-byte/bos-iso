# Como gerar a ISO do BOS

A ISO e um Linux (Debian) que liga direto no BOS, em tela cheia, sem login.
Ela precisa ser montada por um Linux com internet (baixa uns 1,5 GB). O caminho mais facil no Windows e o GitHub, que monta tudo de graca nos servidores deles.

## CAMINHO A (recomendado): GitHub monta a ISO por voce, sem Linux
1. Crie uma conta gratis em https://github.com/signup (se ja tiver, entre).
2. Clique em **+** (canto superior direito) > **New repository**. Nome: `bos-iso`. Marque **Public** (assim nao ha limite de minutos). Clique **Create repository**.
3. Na pagina do repositorio clique em **uploading an existing file**. Extraia este zip no seu PC e **arraste para a pagina o conteudo da pasta `webos-iso`**: os arquivos `bos`, `construir-iso.sh`, `webos.html`, `LEIA-ME.md` **e a pasta `.github`** (se o Windows nao mostrar a pasta `.github`, ative "Itens ocultos" no Explorer, aba Exibir). Clique **Commit changes**.
   - Se a pasta `.github` nao subir: clique **Add file > Create new file**, no nome digite `.github/workflows/gerar-iso.yml` (as barras criam as pastas) e cole o conteudo do arquivo `gerar-iso.yml` desta pasta. Clique **Commit changes**.
4. Clique na aba **Actions**. Se aparecer um botao verde "I understand my workflows, go ahead and enable them", clique nele.
5. No menu da esquerda clique **Gerar ISO do BOS** > botao **Run workflow** > **Run workflow**.
6. Espere de 20 a 40 minutos (a bolinha amarela vira um check verde). Se ficar vermelho, clique nele, abra a etapa que falhou e me mande o texto das ultimas linhas.
7. Clique no trabalho concluido, role ate **Artifacts** e baixe **BOS-iso**. Extraia o .zip: dentro esta `WebOS.iso`.

## CAMINHO B: Ubuntu no Windows (WSL)
1. PowerShell como administrador: `wsl --install -d Ubuntu`. Reinicie o PC, abra o app Ubuntu e crie usuario/senha.
2. Copie a pasta: `cp -r /mnt/c/Users/SEU_USUARIO/Downloads/webos-iso ~/` e entre: `cd ~/webos-iso`
3. `sudo bash construir-iso.sh` (leva 20-40 min e usa uns 10 GB).
4. Traga para o Windows: `cp ~/webos-iso/WebOS.iso /mnt/c/Users/SEU_USUARIO/Downloads/`
Para desfazer depois: `wsl --unregister Ubuntu`. Se o WSL der erro de "mount", use o Caminho A.

## Como usar a ISO
- **Maquina virtual (VirtualBox):** Nova > Tipo Linux, Debian 64-bit, 2 GB de RAM (4 GB e melhor), disco 8 GB. Em Armazenamento, escolha a `WebOS.iso` no leitor optico. Em Sistema, ligue "Habilitar EFI" apenas se quiser testar UEFI. Inicie.
- **Pendrive:** baixe o Rufus (rufus.ie), escolha a ISO e, quando perguntar, o modo **Gravar em modo imagem DD**. Depois inicie o PC pelo pendrive (F12, F9 ou Esc na hora de ligar).
- O sistema abre direto no BOS. Para sair: botao de energia ou menu BOS > Desligar (desliga o computador de verdade).

## Instalar no computador (alem de rodar pelo pendrive)
No menu de boot da ISO escolha **Install** (instalador em modo texto do Debian). Ele copia o BOS para o disco, cria o usuario `user` (voce define a senha) e depois o BOS abre sozinho a cada boot. Atencao: o instalador pode apagar o disco escolhido, entao use uma maquina virtual ou um disco de teste na primeira vez. Se a montagem da ISO com o instalador falhar, o GitHub refaz automaticamente sem ele (so modo live pelo pendrive).

## Guardar arquivos no pendrive (persistencia)
- **Linux:** com o pendrive gravado (modo DD) e ligado, rode `sudo bash criar-persistencia.sh /dev/sdX` (confira o `sdX` com `lsblk`). Ele cria uma particao com o rotulo `persistence` no espaco livre.
- **Windows (Rufus):** em modo **ISO** (nao DD) o Rufus mostra "Tamanho da particao persistente" para ISOs Debian Live. Se nao mostrar, use o script acima num Linux.
- Sem persistencia o sistema e "live": tudo some ao desligar.

## O que o sistema Linux faz de verdade (e so aparece na ISO)
- **Rede e Wi-Fi:** app "Rede e Wi-Fi" lista redes, conecta com senha, liga/desliga o Wi-Fi.
- **VPN WireGuard nativa:** em "Rede e Wi-Fi" > VPN WireGuard cole o `.conf` do seu provedor (Mullvad, ProtonVPN, Cloudflare WARP via wgcf ou seu servidor). Nao vem uma VPN pronta: voce precisa da configuracao do provedor.
- **Discos e USB:** lista, monta, desmonta e ejeta pendrives e discos.
- **Energia e Brilho:** brilho da tela, volume do sistema e suspender.
- **Assistente de Inicio:** abre na primeira vez (idioma, teclado, fuso horario, tema).
- **Torrent:** o app usa o aria2 (BitTorrent completo) que ja vem na ISO.
- **Programas do Windows:** o Wine esta incluso (compatibilidade parcial).

## Lista de testes para voce fazer (eu nao consigo rodar a ISO aqui)
1. Boot na maquina virtual (VirtualBox: 4 GB de RAM, 8 GB de disco, 3D desligado). Teste BIOS e depois "Habilitar EFI".
2. Boot por pendrive em um PC real (se nao iniciar com UEFI, desative o Secure Boot na BIOS).
3. Teclado ABNT2, som, internet por cabo e por Wi-Fi.
4. Abrir Rede, Discos, Energia, Torrent e o jogo Operacao Bunker (FPS).
5. Instalar no disco (somente VM) e reiniciar.
Mande o texto de qualquer erro (ou a foto da tela) que eu corrijo.

## Se a aba Actions não mostrar o fluxo
O arquivo `gerar-iso.yml` deste pacote está em linha única (formato JSON, aceito pelo GitHub) para não perder espaços ao colar. Crie o repositório com um nome normal (ex.: `bos`), envie `bos`, `construir-iso.sh`, `webos.html` e `LEIA-ME.md` soltos na raiz e crie `.github/workflows/gerar.yml` colando o conteúdo de `gerar-iso.yml`.
