# WordPress + MySQL no Kubernetes (k3s)

Trabalho de curso: provisionamento de WordPress e MySQL em containers gerenciados pelo Kubernetes, com persistência de dados e instruções para deploy em VM Ubuntu (AWS EC2 ou Killercoda).

## Arquitetura

```
Usuario (Marketing)
        |
        v
   Traefik Ingress (:80)  ou  NodePort (:30080)
        |
        v
   Service wordpress:80
        |
        v
   Pod WordPress  --->  PVC wordpress-pvc (/var/www/html)
        |
        v
   Service mysql:3306
        |
        v
   Pod MySQL  --->  PVC mysql-pvc (/var/lib/mysql)
```

Ambos os pods usam o StorageClass `local-path` (incluso no k3s). Ao deletar um pod, o Deployment recria a replica e remonta o mesmo PVC, preservando dados e configuracoes.

## Pre-requisitos

| Item | Requisito |
|------|-----------|
| SO | Ubuntu 22.04 ou 24.04 |
| VM | EC2 `t3.small` (2 vCPU, 2 GB RAM) ou Killercoda |
| Portas | 22 (SSH), 80 (HTTP), 30080 (NodePort fallback) |
| EC2 | Security Group com entrada TCP 80 e 30080 liberadas |
| Ferramentas | `curl`, acesso `sudo` |

## Estrutura do projeto

```
microcontainer-arch-plus/
├── README.md
├── docs/images/              # Screenshots para o relatorio (capturar apos deploy)
├── k8s/
│   ├── base/                 # Manifests base
│   └── overlays/local/       # Overlay Kustomize para ambiente local/VM
└── scripts/
    ├── install-k3s.sh
    ├── deploy.sh
    └── test-resilience.sh
```

---

## Passo 1 — Preparar a VM Ubuntu

Conecte-se via SSH na instancia EC2 ou abra o terminal no Killercoda.

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl
```

![k3s nodes](docs/images/01-k3s-nodes.png)

---

## Passo 2 — Instalar o k3s

Na raiz do projeto:

```bash
chmod +x scripts/*.sh
./scripts/install-k3s.sh
export KUBECONFIG=$HOME/.kube/config
```

Verifique o cluster:

```bash
kubectl get nodes
kubectl get storageclass
```

Resultado esperado: no com status `Ready` e StorageClass `local-path` disponivel.

![storage class](docs/images/02-storageclass.png)

---

## Passo 3 — Ajustar credenciais (recomendado)

Edite [`k8s/base/mysql/secret.yaml`](k8s/base/mysql/secret.yaml) e altere as senhas antes do primeiro deploy:

- `MYSQL_ROOT_PASSWORD`
- `MYSQL_PASSWORD`

> **Importante:** troque os valores padrao em ambiente real. O WordPress usa as mesmas credenciais via variaveis de ambiente.

---

## Passo 4 — Deploy da stack WordPress + MySQL

```bash
cd microcontainer-arch-plus
./scripts/deploy.sh
```

O script:

1. Detecta o IP publico e configura o host do Ingress como `<IP>.nip.io` (ou usa `wordpress.local`)
2. Aplica os manifests com `kubectl apply -k` (Kustomize)
3. Aguarda os Deployments `mysql` e `wordpress` ficarem prontos

Acompanhe os recursos:

```bash
kubectl -n wordpress get pods,svc,pvc,ingress -w
```

Resultado esperado:

| Recurso | Status |
|---------|--------|
| `pod/mysql-*` | `Running` |
| `pod/wordpress-*` | `Running` |
| `pvc/mysql-pvc` | `Bound` |
| `pvc/wordpress-pvc` | `Bound` |
| `ingress/wordpress-ingress` | host configurado |

![pods running](docs/images/03-pods-running.png)

### Host customizado

```bash
export INGRESS_HOST=meu-ip.nip.io
./scripts/deploy.sh
```

### Acesso via /etc/hosts (sem nip.io)

```bash
echo "<IP_DA_VM> wordpress.local" | sudo tee -a /etc/hosts
export INGRESS_HOST=wordpress.local
./scripts/deploy.sh
```

---

## Passo 5 — Acessar o WordPress (simulacao Marketing)

### Opcao A — Ingress (recomendado)

Abra no navegador:

```
http://<IP_PUBLICO>.nip.io
```

### Opcao B — NodePort (fallback Killercoda/EC2)

```
http://<IP_DA_VM>:30080
```

![wordpress install](docs/images/04-wordpress-install.png)

### Configuracao pelo time de Marketing

1. Selecione idioma **Portugues (Brasil)**
2. Preencha titulo do site (ex.: "Empresa XYZ")
3. Crie usuario administrador e senha
4. Instale um tema e publique uma pagina de teste (ex.: "Bem-vindo ao site da empresa")
5. Acesse `wp-admin` e confirme que o conteudo foi salvo

![wp-admin](docs/images/05-wp-admin.png)

Nenhum conhecimento de Kubernetes e necessario nesta etapa.

---

## Passo 6 — Teste de resiliencia

Simula a perda dos pods WordPress e MySQL para validar persistencia.

```bash
# Use o mesmo host definido no deploy
export INGRESS_HOST=<seu-host>.nip.io
# ou para NodePort:
export TEST_URL=http://<IP_DA_VM>:30080

./scripts/test-resilience.sh
```

Ou manualmente:

```bash
kubectl -n wordpress get pvc

kubectl -n wordpress delete pod -l app=wordpress
kubectl -n wordpress delete pod -l app=mysql

kubectl -n wordpress get pods -w

curl -I http://<IP>.nip.io
# ou
curl -I http://<IP>:30080
```

**Criterio de sucesso:**

- Pods recriados automaticamente
- Site continua acessivel
- Login no `wp-admin` funciona
- Paginas e posts criados pelo Marketing permanecem

![resilience test](docs/images/06-resilience-test.png)

---

## Troubleshooting

| Sintoma | Causa provavel | Acao |
|---------|----------------|------|
| PVC `Pending` | StorageClass ausente | `kubectl get sc`; reinstale k3s |
| WordPress `CrashLoopBackOff` | MySQL nao pronto | `kubectl -n wordpress logs deployment/wordpress -c wait-for-mysql` |
| HTTP 404 no Ingress | Host incorreto | Verifique `INGRESS_HOST` e DNS/`/etc/hosts` |
| Site vazio apos delete | PVC nao montado | `kubectl -n wordpress describe pod -l app=wordpress` |
| NodePort nao responde | Firewall/SG | Libere porta 30080 no Security Group |
| MySQL lento a subir | VM com pouca RAM | Aguarde ate 3 min; use instancia t3.small ou maior |

Comandos uteis:

```bash
kubectl -n wordpress describe pod -l app=wordpress
kubectl -n wordpress logs deployment/mysql
kubectl -n wordpress logs deployment/wordpress
kubectl -n wordpress get events --sort-by=.lastTimestamp
```

---

## Mapa dos arquivos Kubernetes

| Arquivo | Recurso K8s | Finalidade | Ordem |
|---------|-------------|------------|-------|
| `k8s/base/namespace.yaml` | Namespace | Isola recursos em `wordpress` | 1 |
| `k8s/base/mysql/secret.yaml` | Secret | Credenciais MySQL/WordPress | 2 |
| `k8s/base/mysql/pvc.yaml` | PVC | Persistencia do banco | 3 |
| `k8s/base/mysql/deployment.yaml` | Deployment | Pod MySQL 8.0 (strategy Recreate) | 4 |
| `k8s/base/mysql/service.yaml` | Service | MySQL interno ClusterIP :3306 | 5 |
| `k8s/base/wordpress/pvc.yaml` | PVC | Persistencia do WordPress | 6 |
| `k8s/base/wordpress/deployment.yaml` | Deployment | Pod WordPress + initContainer | 7 |
| `k8s/base/wordpress/service.yaml` | Service | WordPress ClusterIP :80 | 8 |
| `k8s/base/wordpress/service-nodeport.yaml` | Service | Fallback NodePort :30080 | 9 |
| `k8s/base/ingress.yaml` | Ingress | Exposicao HTTP via Traefik | 10 |
| `k8s/base/kustomization.yaml` | Kustomize | Empacota recursos base | — |
| `k8s/overlays/local/kustomization.yaml` | Kustomize | Overlay para VM local | — |
| `k8s/overlays/local/ingress-patch.yaml` | Patch | Ajusta host do Ingress | — |

### Aplicacao manual (sem scripts)

```bash
kubectl apply -k k8s/overlays/local
kubectl -n wordpress rollout status deployment/mysql
kubectl -n wordpress rollout status deployment/wordpress
```

---

## Checklist de avaliacao

- [x] WordPress configuravel pelo time de Marketing (assistente de instalacao web)
- [x] MySQL dedicado exclusivo ao WordPress (Service interno + Secret)
- [x] Ambos em containers no Kubernetes
- [x] Persistencia via PVC (`local-path`) para WordPress e MySQL
- [x] Resiliencia: pods recriados apos delete sem perda de dados
- [x] Ingress, Services, Deployments, Secrets, PVCs, Namespace
- [x] Instrucoes passo a passo Ubuntu → k3s → deploy → uso → teste
- [x] Referencias a imagens ilustrativas em `docs/images/`
- [x] Empacotamento Kustomize (base + overlay)
- [x] Mapa de arquivos e ordem de aplicacao

---

## Conteudo do zip de entrega

Ao zipar para entrega, inclua:

```
microcontainer-arch-plus/
├── README.md
├── docs/images/*.png
├── k8s/
└── scripts/
```

Nao inclua `.git` nem arquivos temporarios.

---

## Licenca

Material academico — uso educacional.
