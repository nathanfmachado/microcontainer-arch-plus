# Screenshots para o relatorio

Mapeamento dos prints de validacao no Killercoda. Consulte tambem o [README principal](../../README.md).

| Arquivo | Passo | Conteudo |
|---------|-------|----------|
| `01-initial-configs.png` | 1–2 | Clone do projeto, instalacao do k3s via script e verificacao inicial do cluster |
| `02-starting-deploy.png` | 4 | Deploy iniciado via `./scripts/deploy.sh` |
| `03-successfull-deploy-and-monitor.png` | 4 | Deploy finalizado; pods, services e PVCs em estado OK |
| `04-wordpress-login.png` | 5 | Tela de login do WordPress apos configurar usuario na instalacao inicial |
| `05-add-persistence-check-post.png` | 5 | Post de teste publicado no WordPress antes do teste de resiliencia |
| `06-delete-pods-to-check-persistence.png` | 6 | Delecao dos pods WordPress e MySQL; aguardando recriacao |
| `07-persisted-successfully.png` | 6 | Validacao no navegador: post de persistencia continua disponivel apos restart |
