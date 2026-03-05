# ELK Stack for Forensics & Lab (Elastic 9.x)

Este projeto fornece um ambiente ELK (Elasticsearch, Kibana, Fleet) pronto para uso em investigações forenses e laboratórios de segurança.

## Diferenciais desta versão:
- **Autodescoberta de Rede:** Detecta o IP do host e configura os certificados SSL automaticamente.
- **Segurança Nativa:** HTTPS habilitado em todos os níveis com senhas aleatórias.
- **Lab Mode:** Desabilita automaticamente o bloqueio de escrita por falta de espaço em disco (Watermarks).
- **Plug-and-Play:** Um único script configura tudo.

## Como usar:

1.  **Iniciar o ambiente:**
    ```bash
    chmod +x bootstrap.sh
    ./bootstrap.sh
    ```

2.  **Limpar e reiniciar do zero (Cuidado: apaga dados):**
    ```bash
    ./bootstrap.sh --clean
    ```

3.  **Acesso:**
    - O script imprimirá a URL e a senha do usuário `elastic`.
    - Acesse via browser: `https://<HOST_IP>:5601`

## Estrutura:
- `.env`: Gerado automaticamente com senhas e IP.
- `certs/`: Certificados gerados pelo setup.
- `kibana.yml`: Configurações pré-definidas para o Kibana.
- `docker-compose.yml`: Definição de todos os serviços e volumes.
