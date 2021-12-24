#! /bin/bash

# Essa funcao gera o certificado, configurar na pasta do haproxy e da um restart no servico do haproxy
gera_certificado() {
	echo "Gereando certificado para o dominio $1"
	gerando=$(certbot certonly --standalone -m $email --preferred-challenges http --http-01-port $porta -d $1)
	result=$(echo $gerando | cat | grep "Congratulations!" | wc -l)
	if [ $result -gt 0 ]; then
		echo -e '\033[1;32mParabens, o certificado para o dominio $1 foi criado com sucesso.\033[m';
		sleep 1
		echo -e '\033[1;32mConfigurando certificado no Haproxy..\033[m';
		sleep 3
		
		cat /etc/letsencrypt/live/$1/privkey.pem > "$path_haproxy_certs/$1.pem"
		check=$?
		cat /etc/letsencrypt/live/$1/fullchain.pem >> "$path_haproxy_certs/$1.pem"
		check=$check+$?
		
		echo "Verificando as configuracoes do Haproxy para porder aplicar as mudancas..."
		check_haproxy=$(haproxy -c -V -f $path_haproxy)
		check_result=$(echo $check_haproxy | grep "Configuration file is valid" | wc -l)
		
		if [ $check_result -ne 0 ]; then
			echo -e '\033[1;32mConfiguracao validada, reiniciando o Haproxy...\033[m';
			sleep 3;
			systemctl reload haproxy.service;	 
			if [ $? -eq 0 ]; then
				echo -e '\033[1;32mHaproxy reiniciado com sucesso.\033[m';
				echo -e '\033[1;32mConfiguracoes realizados com sucesso, acesso o site para testar:\033[m';
				echo "https://$1/"
				
			else
				echo "Falhar ao reiniciar o Haproxy. Verifique detalhes com o comando systemctl status haproxy.service."
			
			fi
		else
			echo "Falha!! \n $check_haproxy"
		fi

	else
		echo "Falha!! \n $gerando"
		exit 0
	fi
}

# Essa funcao verifica se e possivel gerar o certificado com o paramentro --dry-run
valida_certificado() { 
	echo "Realizando teste para o dominio $1...";
	validacao=$(certbot certonly --standalone -m $email --dry-run --preferred-challenges http --http-01-port $porta -d $1);
	result=$(echo $validacao | cat | grep "The dry run was successful" | wc -l);
	
	if [ $result -gt 0 ]; then
		echo -e '\033[1;32mTeste bem sucedido!\033[m';
		gera_certificado "$dominio" 
	
	else
		echo "Falha!! \n $validacao";
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
                        echo "Ja existe um certificado no diretorio $3 para o dominio $1. O recomendado e que o certificado seja renovado. Operacao sera finalizada"
                fi

        else
                echo "Atencao! Nenhuma entra referente ao dominio $1 foi encontrada no arquivo $2. Sem uma entrada valida nao e possivel continuar, entre com outro dominio ou configure uma entrada no arquivo  haproxy e tente novamente."

        fi
}
