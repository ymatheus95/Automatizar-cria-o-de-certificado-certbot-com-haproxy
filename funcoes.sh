#! /bin/bash

echo_texto() {
	# Primeiro paramentro refece a cor desejada e o segundo ao texto.
	case $1 in
	"verde") echo -e "\033[1;32m$2\033[0m" ;;
	"vermelho") echo -e "\033[1;31m$2\033[0m" ;;
	"amarelo") echo -e "\033[1;33m$2\033[0m" ;;
	"azul") echo -e "\033[1;34m$2\033[0m" ;;
esac

}


# Essa funcao gera o certificado, configurar na pasta do haproxy e da um restart no servico do haproxy
gera_certificado() {
	echo_texto "azul" "Gereando certificado para o dominio $1..."
	gerando=$(certbot certonly --standalone -m $email --preferred-challenges http --http-01-port $porta -d $1)
	result=$(echo $gerando | cat | grep "Congratulations!" | wc -l)
	if [ $result -gt 0 ]; then
		echo_texto "verde" "Parabens, o certificado para o dominio $1 foi criado com sucesso."
		sleep 1
		echo_texto "azul" "Configurando certificado no Haproxy...";
		sleep 3
		
		cat /etc/letsencrypt/live/$1/privkey.pem > "$path_haproxy_certs/$1.pem"
		check=$?
		cat /etc/letsencrypt/live/$1/fullchain.pem >> "$path_haproxy_certs/$1.pem"
		check=$check+$?
		
		echo_texto "amarelo" "Verificando as configuracoes do Haproxy para porder aplicar as mudancas..."
		check_haproxy=$(haproxy -c -V -f $path_haproxy)
		check_result=$(echo $check_haproxy | grep "Configuration file is valid" | wc -l)
		
		if [ $check_result -ne 0 ]; then
			echo_texto "verde" "Configuracao validada, reiniciando o Haproxy...";
			systemctl reload haproxy.service;
			sleep 3;
			if [ $? -eq 0 ]; then
				echo_texto "verde" "Configuracoes realizados com sucesso, acesso o site para testar: https://$1/"
				
			else
				echo_texto "vermelho" "Falhar ao reiniciar o Haproxy. Verifique detalhes com o comando systemctl status haproxy.service."
			
			fi
		else
			echo_texto "vermelho" "Falha!! \n $check_haproxy"
		fi

	else
		echo_texto "vermelho" "Falha!! \n $gerando"
		exit 0
	fi
}

# Essa funcao verifica se e possivel gerar o certificado com o paramentro --dry-run
valida_certificado() { 
	echo_texto "amarelo" "Realizando teste para o dominio $1...";
	validacao=$(certbot certonly --standalone -m $email --dry-run --preferred-challenges http --http-01-port $porta -d $1);
	result=$(echo $validacao | cat | grep "The dry run was successful" | wc -l);
	
	if [ $result -gt 0 ]; then
		echo_texto "verde" "Teste bem sucedido!";
		gera_certificado "$dominio" 
	
	else
		echo_texto "vermelho" "Falha!! \n $validacao";
	fi

}


valida_dominio() {


        dominio_existe=$(cat $2 | grep "$1" | wc -l)
        if [ $dominio_existe -gt  0 ]; then # Se maior que 0, significa que existe entradas no arquivo do haproxy
         # Verifica se ja existe um certificado na pasta certs no diretorio do haproxy
                arquivo_existe=$(ls -ltr | grep -E "(^|\s)$3($|\s)" | wc -l) #
                if [ $arquivo_existe -eq 0 ]; then
                        valida_certificado "$1"
                else
                        echo_texto "vermelho" "Ja existe um certificado no diretorio $3 para o dominio $1. O recomendado e que o certificado seja renovado. Operacao sera finalizada"
                fi

        else
                echo_texto "vermelho" "Atencao! Nenhuma configuracao para o dominio $1 foi encontrada no arquivo $2. Para continuar realize primeiro a configuracao no haproxy."

        fi
}

