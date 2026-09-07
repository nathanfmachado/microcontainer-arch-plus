# Screenshots para o relatorio

Capture estas imagens apos o deploy em EC2 ou Killercoda e salve nesta pasta:

| Arquivo | Conteudo |
|---------|----------|
| `01-k3s-nodes.png` | Saida de `kubectl get nodes` com status Ready |
| `02-storageclass.png` | Saida de `kubectl get storageclass` mostrando local-path |
| `03-pods-running.png` | `kubectl -n wordpress get pods,svc,pvc,ingress` com tudo Running/Bound |
| `04-wordpress-install.png` | Assistente de instalacao do WordPress no navegador |
| `05-wp-admin.png` | Painel wp-admin com pagina/post publicado |
| `06-resilience-test.png` | Teste apos deletar pods (pods recriados + site acessivel) |
