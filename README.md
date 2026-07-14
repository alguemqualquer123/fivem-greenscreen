# 🎬 FiveM Greenscreener

![License](https://img.shields.io/github/license/alguemqualquer123/fivem-greenscreener?style=flat-square)
![Version](https://img.shields.io/badge/version-2.0.0-green?style=flat-square)
![FiveM](https://img.shields.io/badge/FiveM-Resource-blue?style=flat-square)
![Lua](https://img.shields.io/badge/Lua-5.1-yellow?style=flat-square)
![TypeScript](https://img.shields.io/badge/TypeScript-5.3-blue?style=flat-square)

> 🖼️ Sistema automatizado de captura de screenshots para FiveM com remoção de green screen via API local.

---

## 📋 Sobre o Projeto

O **FiveM Greenscreener** é um resource completo para FiveM que automatiza a captura de screenshots de props, roupas, veículos e objetos com fundo verde. Inclui uma API local em TypeScript que remove o green screen em tempo real e salva as imagens com transparência.

### 🎯 Por que existe?

Criado para servidores FiveM que precisam gerar imagens limpas de props e itens para uso em lojas, inventários, wikis ou qualquer sistema que exija imagens com fundo transparente.

---

## ✨ Principais Funcionalidades

| Funcionalidade | Descrição |
|----------------|-----------|
| 🎮 **Modo de Posicionamento** | Interface interativa com freecam para posicionar props antes da captura |
| 🖥️ **API Local TypeScript** | Servidor HTTP que processa imagens em fila com 4 workers paralelos |
| 🧹 **Remoção de Green Screen** | Algoritmo de distância euclidiana com limpeza de bordas |
| 📦 **Fila em Memória** | Processamento assíncrono e paralelo para máxima velocidade |
| 🎨 **Multi-Tipo** | Suporta props, roupas (CLOTHING), veículos e objetos genéricos |

---

## 🎬 Demonstração

```
/green <nome_do_prop>    → Modo de posicionamento interativo
/propsscreenshot         → Batch automático de todos os props
/clothingscreenshot      → Batch de todas as roupas
```

---

## 📦 Pré-requisitos

| Requisito | Versão | Obs |
|-----------|--------|-----|
| [FiveM](https://fivem.net/) | Server | FXServer rodando |
| [Node.js](https://nodejs.org/) | v18+ | Para a API local |
| [screenshot-basic](https://github.com/citizenfx/screenshot-basic) | Latest | Resource FiveM |

---

## ⚙️ Instalação

### 1. Clone o repositório

```bash
cd resources
git clone https://github.com/alguemqualquer123/fivem-greenscreen.git
cd fivem-greenscreener
```

### 2. Instale a API local

```bash
cd api
npm install
npx tsc
```

### 3. Inicie a API

```bash
node dist/server.js
```

### 4. Adicione ao `server.cfg`

```cfg
ensure screenshot-basic
ensure fivem-greenscreener
```

---

## 🚀 Como Utilizar

### Comandos Disponíveis

| Comando | Descrição |
|---------|-----------|
| `/green <prop>` | Modo de posicionamento interativo com freecam |
| `/propsscreenshot` | Batch automático de todos os props do `config.lua` |
| `/clothingscreenshot` | Batch de todas as variações de roupas |
| `/object <modelo>` | Screenshot de um objeto específico |
| `/vehicle <modelo>` | Screenshot de um veículo |

### Modo de Posicionamento

```
/green bag_hellokitty
```

| Controle | Ação |
|----------|------|
| `WASD` | Mover câmera |
| `Q / E` | Câmera subir / descer |
| `Mouse` | Olhar ao redor |
| `Scroll` | Zoom (FOV) |
| `Setas` | Mover objeto |
| `Shift + Setas` | Rotacionar objeto |
| `Ctrl + Setas ↑↓` | Objeto subir/descer |
| `Enter` | Confirmar e iniciar batch |
| `Backspace` | Cancelar |

### API Endpoints

```
POST /queue         → Enfileira uma imagem (instantâneo)
POST /queue-batch   → Enfileira várias imagens
GET  /status        → Status da fila
GET  /health        → Health check
POST /clear         → Limpar fila
```

Exemplo com curl:

```bash
curl -X POST http://127.0.0.1:3210/queue \
  -H "Content-Type: application/json" \
  -d '{"filename":"objects/test.png","image":"data:image/png;base64,..."}'
```

---

## 🛠️ Tecnologias Utilizadas

| Tecnologia | Uso |
|------------|-----|
| **Lua** | Client/Server FiveM (natives, controles, lógica) |
| **TypeScript** | API local para processamento de imagens |
| **Node.js** | Runtime da API |
| **Express** | Servidor HTTP da API |
| **Sharp** | Processamento e manipulação de imagens |
| **screenshot-basic** | Captura de screenshots no FiveM |
| **NUI (HTML/CSS/JS)** | Interface de posicionamento e upload |

---

## 📁 Estrutura do Projeto

```
fivem-greenscreener/
├── api/                    # API local TypeScript
│   ├── src/
│   │   └── server.ts       # Servidor Express + processamento
│   ├── dist/               # Build compilado
│   ├── package.json
│   └── tsconfig.json
├── html/                   # Interface NUI
│   ├── index.html
│   ├── script.js
│   └── style.css
├── images/                 # Screenshots salvos
├── stream/                 # Assets do FiveM
├── client.lua              # Lógica client
├── server.lua              # Lógica server
├── config.lua              # Configurações
├── fxmanifest.lua          # Manifest do resource
└── package.json
```

---

## ⚙️ Configuração

Edite `config.lua` para personalizar:

```lua
Config.debug = true                    -- Logs detalhados
Config.includeTextures = false         -- Incluir texturas (mais lento)
Config.overwriteExistingImages = true  -- Sobrescrever imagens existentes
Config.vehicleSpawnTimeout = 5000      -- Timeout para spawn de veículos

-- Posição da tela verde
Config.greenScreenPosition = { x = -1289.02, y = -3409.83, z = 20.91 }
Config.greenScreenRotation = { x = 0, y = 0, z = 330 }

-- Lista de props para batch
Config.propsList = {
    "nome_do_prop_1",
    "nome_do_prop_2",
    -- ...
}
```

---

## 🤝 Contribuindo

Contribuições são bem-vindas! Siga estes passos:

1. **Fork** o repositório
2. Crie uma **branch** para sua feature (`git checkout -b feature/nova-feature`)
3. **Commit** suas mudanças (`git commit -m 'Adiciona nova feature'`)
4. **Push** para a branch (`git push origin feature/nova-feature`)
5. Abra um **Pull Request**

---

## 📄 Licença

Este projeto está licenciado sob a **MIT License** - veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

## 🔗 Links Úteis

- 📦 [Repositório](https://github.com/alguemqualquer123/fivem-greenscreen)
- 🐛 [Reportar Bug](https://github.com/alguemqualquer123/fivem-greenscreen/issues)
- 💡 [Solicitar Feature](https://github.com/alguemqualquer123/fivem-greenscreen/issues)

---

## 🙏 Agradecimentos

- [FiveM](https://fivem.net/) - Plataforma
- [citizenfx](https://github.com/citizenfx) - screenshot-basic
- [sharp](https://sharp.pixelplumbing.com/) - Processamento de imagens
