# Use uma imagem oficial do Dart como base
FROM dart:stable AS build

# Defina o diretório de trabalho dentro do contêiner
WORKDIR /app

# Copie os arquivos do projeto para dentro do contêiner
COPY . .

# Instale as dependências do Dart (se houver)
RUN dart pub get

# Exponha a porta 8080, que será usada pelo seu servidor HTTP
EXPOSE 8080

# Defina o comando para rodar sua aplicação Dart
CMD ["dart", "run", "bin/meu_servico_de_email.dart"]