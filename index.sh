#! /bin/bash
#############################################################################
# Autor: Matheus Santos
# Data Criacao: 19/12/2021
# Ultima atualizacao: 20/12/2021
#############################################################################


email="linux@seu.dominio.com"
porta="porta"
path_haproxy="/etc/haproxy/haproxy.cfg"
path_haproxy_certs="/etc/haproxy/certs"

source funcoes.sh

if  test $1;  then
	if test -f "$1"; then
		path_haproxy="$1"
		path_haproxy_certs="" # Tem que corrigir!
	else
		echo "Atencao! Diretorio ou arquivo nao encontrado $1. O primeiro parementro desse script se refere ao diretorio absoluto onde esta o arquivo do haproxy, use apenas quando necessario."
		exit 0
	fi
## Adicionar condicao para verificar se o arquivo existe
fi

dominio=""
echo "--------------------------------------------------"
echo "|Digite o dominio que deseja gerar  o certificado:|"
echo "--------------------------------------------------"

# Essa funcao verifica se ha alguma ocorrencia seja backend ou seja acl com o dominio fornecido pelo usuario, caso nao tenha nenhum registro no arquivo do haproxy o script sera interrompido

read dominio;

valida_dominio "$dominio" "$path_haproxy" "$path_haproxy_certs"
