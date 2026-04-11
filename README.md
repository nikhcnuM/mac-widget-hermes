# Mac Widget Boilerplate

Boilerplate minimo para crear widgets personales de macOS con SwiftUI + WidgetKit.

La plantilla incluye una app de macOS y una extension de widget que comparten datos mediante App Group. La app te sirve como editor y preview local; el widget consume ese estado y lo pinta en el escritorio o centro de notificaciones.

## Que incluye

- App macOS con editor de contenido.
- WidgetKit extension con timeline basico.
- Capa compartida para modelo, store y vista del widget.
- Proyecto generado con XcodeGen para que el repo sea facil de clonar y mantener.
- Script para renombrar la plantilla y reutilizarla en nuevos widgets.

## Estructura

```text
.
├── Makefile
├── README.md
├── project.yml
├── scripts/
│   └── rename-template.sh
└── WidgetTemplate/
    ├── App/
    ├── Shared/
    └── Widget/
```

## Requisitos

- macOS
- Xcode.app completa
- XcodeGen

Instalacion recomendada:

```bash
brew install xcodegen
```

Nota: en este entorno solo habia Command Line Tools, no Xcode.app completa. Por eso la plantilla queda preparada, pero no se pudo compilar aqui.

## Primer uso

1. Clona este repo donde quieras reutilizarlo.
2. Renombra la plantilla si quieres cambiar nombre, bundle IDs y App Group:

```bash
./scripts/rename-template.sh DeskStats dev.cledesmc group.dev.cledesmc.deskstats
```

El nombre debe ir en PascalCase y sin espacios.

3. Genera y abre el proyecto:

```bash
make open
```

4. En Xcode revisa `Signing & Capabilities` de la app y del widget:
- Asigna tu team.
- Verifica los bundle identifiers.
- Crea o selecciona el App Group configurado.

5. Ejecuta la app, guarda contenido y luego anade el widget al escritorio o al centro de notificaciones.

## Como personalizar un nuevo widget

### 1. Cambia el modelo compartido

Edita `WidgetTemplate/Shared/WidgetContent.swift` si tu widget necesita otros campos.

### 2. Cambia el render del widget

Edita `WidgetTemplate/Shared/WidgetCardView.swift`. Esa vista se usa tanto en la app como en la extension, asi que el preview y el widget real quedan sincronizados.

### 3. Cambia la logica del timeline

Edita `WidgetTemplate/Widget/TemplateWidget.swift` para ajustar frecuencia de refresco, placeholders o familias soportadas.

### 4. Cambia el editor de la app

Edita `WidgetTemplate/App/ContentView.swift` para exponer los controles que te interesen.

## Fuente de verdad

`project.yml` es la fuente de verdad del proyecto. El `.xcodeproj` generado esta ignorado a proposito.

Flujo habitual:

```bash
make generate
make open
```

Si tocas `project.yml`, vuelve a generar el proyecto.

## Sitios que normalmente cambias al clonar

- `project.yml`: nombre del proyecto, targets, bundle IDs y App Group.
- `WidgetTemplate/Shared/WidgetContent.swift`: datos que representa el widget.
- `WidgetTemplate/Shared/WidgetCardView.swift`: look and feel.
- `WidgetTemplate/Widget/TemplateWidget.swift`: proveedor y familias.
- `WidgetTemplate/App/ContentView.swift`: panel editor.

## Siguiente evolucion natural

Cuando quieras convertir esta base en un widget mas real, los siguientes pasos suelen ser los utiles:

1. Reemplazar `WidgetContentStore` por lectura desde JSON, SQLite, red local o API.
2. Añadir App Intents si quieres configuracion por instancia del widget.
3. Crear mas de una familia o mas de un widget dentro del mismo bundle.
