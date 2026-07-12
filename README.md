# NestFrame

App macOS nativo para extrair frames de vídeos com precisão de milissegundos.

## Funcionalidades

- **Arrastar e soltar** qualquer vídeo na janela (MP4, MOV, MKV, AVI, WebM, MTS…)
- **Timeline interativo** com scrubbing por clique e drag
- **Navegação frame-a-frame** com botões `‹` `›`
- **Exportação** em PNG, JPEG, TIFF ou WebP
- **Sidebar de histórico** com thumbnails dos frames extraídos
- **Salvar frame** com nome sugerido automático (`frame_00_01_234s.png`)
- Exibe resolução e FPS do vídeo carregado

## Requisitos

- macOS 13 Ventura ou superior
- Xcode 15+
- Swift 5.9+

## Como abrir no Xcode

```bash
open NestFrame.xcodeproj
```

Pressione `⌘R` para rodar.

> **Nota:** O bundle identifier padrão é `com.nestsuite.framegrab`. Troque em  
> `Build Settings → Product Bundle Identifier` se necessário, e configure seu  
> signing team em `Signing & Capabilities`.

## Estrutura

```
NestFrame/
├── NestFrameApp.swift      # Entry point (@main)
├── ContentView.swift       # Layout principal (HStack: vídeo | sidebar)
├── FrameExtractor.swift    # AVFoundation — carrega vídeo, scrub, extrai frames
├── Models.swift            # ExtractedFrame, ExportFormat
├── TitleBar.swift          # Barra de título customizada
├── VideoDropZone.swift     # Área de drag-and-drop + preview
├── ControlsPanel.swift     # Timeline, frame stepper, picker de formato, botão extrair
├── FramesSidebar.swift     # Lista de frames extraídos com save/remove
└── Assets.xcassets/        # Paleta dark navy/teal (Nest Suite design system)
```

## Design

Segue o design system do **Nest Suite**:
- **BG** `#0F1724` · **Surface** `#16202E`
- **Teal** `#2ECFBE` (accent)
- **Gold** `#F5C842` (reservado para estados de atenção)
- Fonte monospace para timestamps e metadados
