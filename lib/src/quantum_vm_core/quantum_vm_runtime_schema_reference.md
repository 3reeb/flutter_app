# Quantum Runtime JSON/YAML Schemas (Exhaustive E2E Specification)

> **Specification Level**: Complete Runtime-Only Reference  
> **Target Scope**: All files in `lib/src/quantum_vm_core`, `lib/src/quantum_vm_core/qee`, and related runtime registries (`lib/src/runtime`).  
> **Constraint**: EXHAUSTIVE AND ACCURATE. ZERO SIMPLIFICATION. This document reflects the true runtime objects, primitives, QEE nodes, caching policies, exact binary codecs, layout matrices, routing models, and strict parser definitions.

---

## 1. Core Architecture & Syntax Parser

The Quantum VM uses a highly specialized schema and AST representation to render and resolve UI components dynamically. 

### 1.1 `base:subType` Notation
The runtime identifies nodes using a colon-separated type string.
- **Syntax**: `"type": "base:subType"` (e.g., `"box:col"`, `"media:image"`).
- **Shorthand Resolution**: If the colon is omitted (e.g., `"row"`), the schema compiler infers the base type automatically (resolved as `"box:row"`). If `type` is omitted entirely, the engine infers `box`.
- **`__subType` Override**: The exact subtype can be explicitly overridden in the `props` map using the `__subType` key (e.g., `"props": { "__subType": "col" }`).

### 1.2 Template Interpolation
The UI AST evaluates dynamic content using double-bracket interpolation at render time.
- `{{routeParams.id}}`: Extracts variables from the URL path pattern.
- `{{queryParams.q}}`: Extracts query string parameters.
- `{{pageProps.x}}`: Extracts data passed statically or server-side to the page config.
- `{{state.path}}`: Observes reactive variables in the `QLDataStore`.
- `{{error.message}}`: Accesses the current error string within an `_error.yaml` boundary.

### 1.3 Pipeline Syntax (QLPipes)
Interpolated strings support pipeline transformations using the `|` character.
- `{{state.name | uppercase}}`: Transforms to uppercase.
- `{{state.name | lowercase}}`: Transforms to lowercase.
- `{{state.user | default:'Guest'}}`: Provides a fallback value if null.
- `{{state.count | multiply:10}}`: Executes basic arithmetic pipelines.
- `{{state.data | json}}`: Dumps the raw object as a JSON string for debugging or formatting.

---

## 2. Runtime Primitive Field Types

These are the concrete field type constants the schema compiler recognizes (from `QLFieldType`). Unknown field types generally fall back to `string`.

```json
{
  "string": 1,
  "number": 2,
  "boolean": 3,
  "date": 4,
  "json": 5,
  "object": 6,
  "relation": 7,
  "relationship": 8,
  "block": 9,
  "enumeration": 10,
  "array": 11,
  "tree": 12,
  "secure": 13,
  "lookup": 14,
  "textarea": 15,
  "media": 16,
  "bigInt": 17,
  "smallInt": 18,
  "decimal": 19,
  "char": 20,
  "flags": 21
}
```

### 2.1 Flag Bits (`QLFieldFlags`)

```json
{
  "none": 0,
  "isVirtual": "1 << 0",
  "isComputed": "1 << 1",
  "isRequired": "1 << 2",
  "hasMany": "1 << 3",
  "isUnique": "1 << 4",
  "isIndexed": "1 << 5",
  "isHidden": "1 << 6",
  "isReadOnly": "1 << 7"
}
```

### 2.2 Textual Type Labels Accepted by the Schema Compiler
`string`, `text`, `textarea`, `number`, `float`, `int`, `int32`, `double`, `bigint`, `biginteger`, `int64`, `long`, `smallint`, `short`, `int16`, `decimal`, `numeric`, `money`, `currency`, `char`, `character`, `flags`, `bitflags`, `bitmask`, `mask`, `media`, `asset`, `file`, `bool`, `boolean`, `date`, `json`, `object`, `group`, `map`, `relation`, `relationship`, `block`, `enum`, `enumeration`, `array`, `list`, `tree`, `secure`, `password`, `lookup`.

---

## 3. Schema Compiler Objects

### 3.1 `QLBlockPayload`
```json
{
  "blockType": "string",
  "data": {}
}
```

### 3.2 `QLSchemaFieldSpec`
```json
{
  "name": "string",
  "path": "string",
  "type": "int",
  "flags": "int",
  "relationTarget": "string | null",
  "options": [
    "string"
  ],
  "min": "number | null",
  "max": "number | null",
  "meta": {},
  "children": [],
  "itemSpec": null,
  "allowedBlocks": [
    "string"
  ],
  "mediaType": "string | null",
  "allowedMimeTypes": [
    "string"
  ],
  "minSizeBytes": "int | null",
  "maxSizeBytes": "int | null",
  "thumbnailIcon": "string | null",
  "thumbnailPath": "string | null",
  "mediaPolicy": {},
  "qualityPolicy": {},
  "streamingPolicy": {},
  "cachePolicy": {},
  "compute": "function(record) -> dynamic | null",
  "pattern": "string | null",
  "matchField": "string | null",
  "transform": "string | null",
  "dependencies": [
    "string"
  ],
  "errorMessages": {
    "key": "string"
  },
  "index": -1
}
```

### 3.3 `QLSchemaBlueprint`
```json
{
  "name": "string",
  "rootFields": [
    "QLSchemaFieldSpec"
  ],
  "fields": [
    "QLSchemaFieldSpec"
  ],
  "byPath": {
    "path": "QLSchemaFieldSpec"
  },
  "fieldCount": "int"
}
```

### 3.4 Raw Schema Blueprint Language
The schema compiler accepts a raw map where any key can become a field, or a top-level object of the form `{ "type": "object", "fields": {...} }`.

**Field Definition Shape**:
```json
{
  "type": "string",
  "fields": {},
  "items": {},
  "schema": "string",
  "options": [
    "string"
  ],
  "min": 0,
  "max": 0,
  "blocks": [],
  "allowedBlocks": [],
  "media": {},
  "mediaType": "string",
  "mimeTypes": [
    "string"
  ],
  "allowedMimeTypes": [
    "string"
  ],
  "minSizeBytes": 0,
  "minBytes": 0,
  "maxSizeBytes": 0,
  "maxBytes": 0,
  "thumbnailIcon": "string",
  "thumbnailPath": "string",
  "quality": {},
  "streaming": {},
  "cache": {},
  "compute": "function(record) -> dynamic",
  "pattern": "string",
  "matchField": "string",
  "matches": "string",
  "transform": "string",
  "dependencies": [
    "string"
  ],
  "errors": {
    "name": "string"
  }
}
```

---

## 4. AST Node Schema (`QLBlueprint` & Directives)

Every UI element is compiled into a `QLBlueprint`.

### 4.1 Complete Root Fields
| Field | Type | Description |
| :--- | :--- | :--- |
| `type` | `String` | Node type string (`base:subType`). |
| `props` | `Map<String, dynamic>` | Key-value properties for the widget. |
| `style` | `String` | Space-separated design system style tokens (e.g., `p-4 flex`). |
| `children` | `List<Map>` | Array of nested AST node objects. |
| `slots` | `Map<String, Map>` | Map of named slot identifiers to AST node objects. |
| `name` | `String` | Shorthand identifier. Auto-moved into `props` at compile time. |
| `slot` | `String` | Associates the node with a parent's slot. Auto-moved to `props`. |
| `__subType` | `String` | Explicitly overrides the subtype internally. Auto-moved to `props`. |

### 4.2 Compiler Directives
Directives execute logic during AST compilation or rendering.

- **`$define`**: `Map<String, dynamic>` — Defines a local macro or inline component accessible within this subtree.
- **`$let`**: `Map<String, dynamic>` | `List` — Injects compile-time variables or static constants into the local evaluation environment.
- **`$classes`**: `Map<String, String>` — Evaluates conditional class names (e.g., `{"active": "{{state.isActive}}"}`) and merges truthy values into `style`.
- **`$scope`**: `String` | `List<String>` — Prepends a specific state path to all bindings within the subtree, isolating reactive lookups.
- **`$switch`**: Evaluates a condition.
  - `Expression` (String): The condition to evaluate (e.g., `{{state.status}}`).
  - `cases` (Map<String, Map>): Map of string matches to AST nodes.
  - `default` (Map): Fallback AST node.
- **`$repeat`**: Repeats the node over an iterable.
  - `Expression` (String): The list/array path to iterate.
  - `as` (String): The local variable name for the item (defaults to `"item"`).
  - `indexAs` (String): The local variable name for the index (defaults to `"index"`).
- **`$if`**: `Expression` (String) — Skips node rendering if the truthy evaluation yields `false`, `0`, `""`, or `null`.
- **`$call`**: `String` — Invokes a named macro, inserting its returned AST structure in place.
- **`$apply`**: Applies properties to the output of a `$call`.
  - `props` (Map): Properties to pass to the macro.
  - `style` (String): Styles to append.
  - `mode` (String): Determines conflict resolution (`"merge"`, `"replace"`). Defaults to `"merge"`.

---

## 5. Runtime Configs & Routing Models (App, Router, Theme, Page)

### 5.1 `APP.yaml` / `QLAppYamlConfig`
```json
{
  "app": {
    "name": "string",
    "title": "string",
    "locale": "string",
    "version": "string"
  },
  "name": "string",
  "title": "string",
  "locale": "string",
  "version": "string",
  "theme": {},
  "router": {
    "initialRoute": "string",
    "pagesDir": "string",
    "notFound": "string",
    "globalGuards": [
      {}
    ]
  },
  "vm": {
    "workerThreads": "int",
    "simdArenaCapacity": "int"
  },
  "telemetry": {
    "enabled": "bool",
    "frameMonitor": "bool"
  },
  "domains": [
    {}
  ],
  "state": {},
  "macros": {},
  "schemas": {},
  "pipes": {},
  "actions": {},
  "sdui": {},
  "raw": {}
}
```

### 5.2 Bootstrap Configurations: `QAppConfig` and `QAppRouterConfig`
These models exist in the Dart application layer (bootstrap and router configs), distinct from the raw YAML representation.

**`QAppConfig`**:
- `appId` (String)
- `environment` (String)
- `features` (Map)
- `runtime` (Map)

**`QAppRouterConfig`**:
- `initialRoute` (String)
- `pagesDir` (String)
- `deepLinkEnabled` (bool)
- `transitionDurationMs` (int)

### 5.3 `theme` / `QLYamlThemeConfig`
```json
{
  "colors": {},
  "typography": {},
  "spacing": {},
  "breakpoints": {},
  "shadows": {},
  "radii": {},
  "mode": "light | dark | system",
  "raw": {}
}
```

### 5.4 Page YAML / `QLPageYamlConfig`
```json
{
  "type": "screen | page | component | widget | layout | modal | drawer | overlay | fragment | preset",
  "meta": {
    "title": "string",
    "description": "string",
    "keywords": "string",
    "ogImage": "string",
    "custom": {}
  },
  "route": {
    "urlPattern": "string",
    "captureGroups": [
      "string"
    ],
    "transition": "string",
    "transitionMs": "int"
  },
  "urlPattern": "string",
  "serverProps": {},
  "staticProps": {},
  "initialProps": {},
  "staticPaths": [
    "string"
  ],
  "state": {},
  "schemas": {},
  "pipelines": {},
  "guards": [
    {}
  ],
  "macros": {},
  "defaultProps": {},
  "ui": {},
  "view": {},
  "template": {},
  "layoutSlot": "string",
  "transition": "string",
  "transitionDurationMs": 380,
  "raw": {}
}
```
**Parser Fallbacks:**
- Unrecognized YAML semantic types fall back to `page`.
- UI payload is compiled by checking `ui ?? view ?? template` inside `QLPageYamlConfig`.

### 5.5 Route Model / `QLRouteInfo` and `QLRoute`
```json
{
  "QLRouteInfo": {
    "path": "string",
    "params": {
      "key": "string"
    },
    "queryParams": {
      "key": "string"
    },
    "props": {},
    "extra": {},
    "state": {}
  },
  "QLRoute": {
    "path": "string",
    "builder": "function(context, info) -> Widget",
    "layoutBuilder": "function(context, info, child) -> Widget",
    "children": [
      "QLRoute"
    ],
    "middlewares": [
      "QLMiddleware"
    ],
    "transition": "fade | scale | slideRight | slideLeft | slideUp | slideDown | flip3D | none",
    "transitionDuration": "Duration",
    "getServerSideProps": "function(info) -> map",
    "getStaticProps": "function(info) -> map",
    "getInitialProps": "function(info) -> map",
    "getStaticPaths": "function() -> list<string>",
    "seo": "function(info, props) -> QLSeoConfig",
    "getSchema": "function(info) -> map",
    "loadingBuilder": "WidgetBuilder"
  }
}
```

---

## 6. QEE File Router & Special YAML Files (`qee/`)

### 6.1 QuantumFileRouter Level
The file router treats the following files strictly as "route-adjacent" special files during the traversal phase:
- `_layout`
- `_middleware`
- `_meta`
- `_error`
- `_loading`

*(Note: `_not_found` is NOT treated as a route-adjacent special file at the file-router layer. It is handled at the QEE node compilation level).*

### 6.2 QEE Node Layer (`QNodeKind` and Models)

**`QNodeKind` enum:**
- `app (0x01)`, `page (0x02)`, `module (0x03)`, `layout (0x04)`, `meta (0x05)`, `middleware (0x06)`, `error (0x07)`, `loading (0x08)`, `notFound (0x09)`.

**`QNodeFlags` bits:**
`isCatchAll (1<<0)`, `hasParams (1<<1)`, `hasStaticState (1<<2)`, `isOverridable (1<<3)`, `isComposing (1<<4)`, `hasBody (1<<5)`, `isPublic (1<<6)`, `isPrivate (1<<7)`, `isShared (1<<8)`, `hasParentRef (1<<9)`, `isSealed (1<<10)`.

#### Node Models (`qee_node_types.dart`)
- **`QPageNode`**: `routePath`, `appId`, `assetPath`, `paramNames`, `layoutRef` (QNodeRef), `metaRef` (QNodeRef), `middlewareRef` (QNodeRef), `errorRef` (QNodeRef), `loadingRef` (QNodeRef), `notFoundRef` (QNodeRef), `body` (QPageBody lazy blob).
- **`QLayoutNode`**: `layoutId`, `appId`, `assetPath`, `directoryPath`, `parentLayoutRef` (for compositional wrapping), `body`.
- **`QMiddlewareNode`**: `middlewareId`, `appId`, `assetPath`, `directoryPath`, `nextRef` (QNodeRef for chaining), `steps` (List of `QMiddlewareStep` objects: `type`, `params`, `isAsync`, `description`).
- **`QMetaNode`**: `metaId`, `appId`, `assetPath`, `directoryPath`, `title`, `titleTemplate`, `description`, `openGraph`, `twitterCard`, `extra`, `raw`.
- **`QErrorNode`**: `errorId`, `appId`, `assetPath`, `directoryPath`, `props`, `body`.
- **`QLoadingNode`**: `loadingId`, `appId`, `assetPath`, `directoryPath`, `isFullPage`, `minDisplayMs`, `body`.
- **`QNotFoundNode`**: `notFoundId`, `appId`, `assetPath`, `directoryPath`, `isCatchAll`, `body`.

---

## 7. Quantum Component, Macro, Layout & Template Definitions

### 7.1 Quantum Component Definition Schema (`quantum_vm_components.dart`)
```json
{
  "name": "string",
  "description": "string",
  "props": {},
  "state": {},
  "links": {},
  "variants": {},
  "animations": {},
  "ui": {},
  "slots": {},
  "metadata": {},
  "capabilities": ["string"]
}
```

#### Computed State (`_QLComponentComputedSpec`)
```json
{
  "deps": ["string"],
  "op": "string",
  "args": [],
  "fallback": {},
  "immediate": true
}
```

#### Lifecycle & Reactive Hooks (`_QLComponentHookBundle`)
```json
{
  "mount": [{}],
  "unmount": [{}],
  "effect": [{
    "deps": ["string"],
    "actions": [{}],
    "debounceMs": 0,
    "immediate": false
  }],
  "bridge": [{}],
  "guard": [{}],
  "memo": [{}],
  "controller": [{}],
  "scope": {}
}
```

#### Deep-Merged Sections
Component definitions automatically deep-merge nested configurations to inherit behaviors: `runtime`, `omni`, `media`, `stream`, `cache`, `batch`, `presentation`, `resource`, `pagination`, `network`, `select`, `policy`, `permissions`.

### 7.2 Macro Definition
```json
{
  "name": "string",
  "pattern": {},
  "when": {},
  "replace": {},
  "args": [
    "string"
  ],
  "slots": [
    "string"
  ],
  "description": "string"
}
```

### 7.3 JSON Template Definition
```json
{
  "type": "template",
  "name": "string",
  "id": "string",
  "props": {},
  "defaultProps": {},
  "slots": [
    "header",
    "body"
  ],
  "ui": {},
  "template": {},
  "view": {},
  "layout": {},
  "description": "string",
  "summary": "string",
  "params": {},
  "parameters": {},
  "tags": [
    "string"
  ],
  "engine": "QJsonTemplateEngine_D",
  "metadata": {},
  "meta": {}
}
```

### 7.4 Matrix Layout Definition
```json
{
  "type": "layout",
  "name": "string",
  "id": "string",
  "gap": 0,
  "defaultProps": {},
  "props": {},
  "matrix": "string",
  "grid": "string",
  "ascii": "string",
  "sm": "string",
  "md": "string",
  "lg": "string",
  "xl": "string",
  "variants": {
    "variantName": "string | { breakpoint: string }"
  },
  "slots": {
    "slotName": {
      "scrollable": false,
      "floating": false,
      "preserveOverlap": false,
      "draggable": false,
      "resizable": false,
      "reorderable": false,
      "align": "stretch",
      "zIndex": 0,
      "padding": 0,
      "margin": 0,
      "useHero": false,
      "heroTag": null,
      "resizeHandle": "none"
    }
  },
  "description": "string",
  "summary": "string",
  "tags": [
    "string"
  ],
  "metadata": {}
}
```

---

## 8. Runtime Matrix Layout Instances (`layout_core.dart`)

### `workspace`
- **Gap**: `12`
- **Default props**: `{"variant": "'app'", "enableSemantics": "true", "enableInteractivity": "true", "enableRTL": "true"}`
- **Matrix**:
  ```text
  auto minmax(0, 1fr) auto
  chrome chrome chrome | auto
  header header header | auto
  sidebar main inspector | minmax(0, 1fr)
  panel panel panel | auto
  footer footer footer | auto
  ```
- **Small breakpoint**: `auto \n chrome | auto \n header | auto \n main | minmax(0, 1fr) \n sidebar | auto \n inspector | auto \n panel | auto \n footer | auto`
- **Variants**: `dashboard`, `code`, `studio`, `canvas`, `fullscreen`, `board`. Slots: none.

### `page`
- **Gap**: `16`
- **Default props**: `{"variant": "'document'", "enableSemantics": "true", "enableInteractivity": "true", "enableRTL": "true"}`
- **Matrix**:
  ```text
  1fr minmax(0, 794px) 1fr
  chrome chrome chrome | auto
  header header header | auto
  gutter sheet notes | minmax(0, 1fr)
  footer footer footer | auto
  ```
- **Small breakpoint**: `1fr \n chrome | auto \n header | auto \n sheet | minmax(0, 1fr) \n notes | auto \n footer | auto`
- **Variants**: `document`, `a4`, `letter`, `presentation`, `slides`, `poster`, `notes`. Slots: none.

### `app_shell`
- **Gap**: `12`
- **Default props**: `{"variant": "'app'", "enableSemantics": "true", "enableInteractivity": "true", "enableRTL": "true"}`
- **Matrix**:
  ```text
  auto minmax(240px, auto) minmax(0, 1fr) minmax(240px, auto)
  chrome chrome chrome chrome | auto
  header header header header | auto
  nav body body inspector | minmax(0, 1fr)
  footer footer footer footer | auto
  ```
- **Small breakpoint**: `auto \n header | auto \n body | minmax(0, 1fr) \n footer | auto`
- **Variants**: `app`, `dashboard`, `focus`. Slots: none.

### `split_shell`
- **Gap**: `12`
- **Default props**: `{"variant": "'split'", "enableSemantics": "true", "enableInteractivity": "true", "enableRTL": "true"}`
- **Matrix**:
  ```text
  auto minmax(280px, auto) minmax(0, 1fr) minmax(260px, auto)
  chrome chrome chrome chrome | auto
  header header header header | auto
  sidebar main main inspector | minmax(0, 1fr)
  footer footer footer footer | auto
  ```
- **Small breakpoint**: `auto \n header | auto \n sidebar | auto \n main | minmax(0, 1fr) \n inspector | auto \n footer | auto`
- **Variants**: `split`, `editor`. Slots: none.

### `feed_shell`
- **Gap**: `12`
- **Default props**: `{"variant": "'feed'", "enableSemantics": "true", "enableInteractivity": "true", "enableRTL": "true"}`
- **Matrix**:
  ```text
  auto minmax(260px, auto) minmax(0, 1fr) minmax(280px, auto)
  chrome chrome chrome chrome | auto
  header header header header | auto
  composer feed feed trending | minmax(0, 1fr)
  footer footer footer footer | auto
  ```
- **Small breakpoint**: `auto \n header | auto \n composer | auto \n feed | minmax(0, 1fr) \n footer | auto`
- **Variants**: `feed`, `social`. Slots: none.

### `form_shell`
- **Gap**: `12`
- **Default props**: `{"variant": "'form'", "enableSemantics": "true", "enableInteractivity": "true", "enableRTL": "true"}`
- **Matrix**:
  ```text
  auto minmax(220px, auto) minmax(0, 1fr) minmax(260px, auto)
  chrome chrome chrome chrome | auto
  header header header header | auto
  sidebar form summary inspector | minmax(0, 1fr)
  footer footer footer footer | auto
  ```
- **Small breakpoint**: `auto \n header | auto \n form | minmax(0, 1fr) \n summary | auto \n footer | auto`
- **Variants**: `form`, `wizard`. Slots: none.

### `modal_shell`
- **Gap**: `8`
- **Default props**: `{"variant": "'modal'", "enableSemantics": "true", "enableInteractivity": "true", "enableRTL": "true"}`
- **Matrix**:
  ```text
  auto minmax(0, 1fr) auto
  chrome chrome chrome | auto
  backdrop modal backdrop | minmax(0, 1fr)
  footer footer footer | auto
  ```
- **Small breakpoint**: `auto \n modal | minmax(0, 1fr) \n footer | auto`
- **Variants**: `modal`, `sheet`. Slots: none.

### `timeline_shell`
- **Gap**: `12`
- **Default props**: `{"variant": "'timeline'", "enableSemantics": "true", "enableInteractivity": "true", "enableRTL": "true"}`
- **Matrix**:
  ```text
  auto minmax(240px, auto) minmax(0, 1fr) minmax(280px, auto)
  chrome chrome chrome chrome | auto
  header header header header | auto
  timeline body inspector activity | minmax(0, 1fr)
  footer footer footer footer | auto
  ```
- **Small breakpoint**: `auto \n header | auto \n timeline | auto \n body | minmax(0, 1fr) \n footer | auto`
- **Variants**: `timeline`, `roadmap`. Slots: none.

---

## 9. Module, Data Source, Slice & Policies

### 9.1 `QLModuleRecord` & Access Policies
```json
{
  "module": "string",
  "id": "string",
  "name": "string",
  "visibility": "public | local | owner | secure",
  "allow": ["string"],
  "ownerId": "string"
}
```

### 9.2 State Slices (`QSliceConfig`)
Slices can be shorthand primitives (e.g. `"count": 0`) or detailed object configs.
```json
{
  "type": "string",
  "static": false,
  "value": {},
  "default": {},
  "dataSource": "string"
}
```

### 9.3 Data Sources (`QDataSourceConfig`)
```json
{
  "id": "string",
  "type": "rest | http | firebase | sqlite | mock",
  "endpoint": "string",
  "method": "string",
  "headers": {},
  "params": {},
  "body": {},
  "ttl": 0,
  "auth": false
}
```

### 9.4 `slice` Binding Object
```json
{
  "mode": "local | remote | hybrid | stream | realtime",
  "from": "string",
  "source": "string",
  "dataSource": "string",
  "bind": "string",
  "sourcePath": "string",
  "path": "string",
  "merge": "replace | mergeMap | merge | hybrid | append | prepend | appendById",
  "transform": "string",
  "subscribe": true,
  "realtime": true,
  "default": {},
  "initial": {},
  "value": {},
  "metadata": {}
}
```

### 9.5 `QLSliceFieldPolicy` / `fieldPolicy`
```json
{
  "path": "string",
  "storageMode": "hot | cold | persistent",
  "storage": "string",
  "mode": "string",
  "reactive": true,
  "immutable": false,
  "frozen": false,
  "readOnly": false,
  "readonly": false,
  "lazy": false,
  "defer": false,
  "streaming": false,
  "stream": false,
  "cacheResults": true,
  "cache": true,
  "pinInMemory": false,
  "pin": false,
  "sensitive": false,
  "secret": false,
  "resourceId": "string",
  "id": "string",
  "ref": "string",
  "resolver": "string",
  "metadata": {}
}
```

### 9.6 `QLSliceResourceRef` / `resourceRef`
```json
{
  "id": "string",
  "scheme": "ref",
  "uri": "string",
  "cacheable": true,
  "streaming": false,
  "lazy": true,
  "mimeType": "string",
  "metadata": {}
}
```

### 9.7 `QLSliceProtection` / `protection`
```json
{
  "level": "public | local | owner | authenticated | secure",
  "ownerId": "string",
  "allowUsers": ["string"],
  "allowRoles": ["string"],
  "denyUsers": ["string"],
  "denyRoles": ["string"],
  "requireAuth": false,
  "requireFreshSession": false,
  "redactInSnapshots": false,
  "metadata": {}
}
```

---

## 10. Design System Manifest (`QuantumDesignSystemBundle`)

Top-level schemas recognized by the global catalogs:
- **`design_system`**: Bundles tokens, typographies, and aliases.
- **`macro`**: AST snippet templates for `$call`.
- **`component`**: Full UI encapsulated widgets.
- **`template`**: Page layout scaffolds.
- **`workflow`**: Step-by-step logic chains.
- **`state_machine`**: Finite state machine definitions.
- **`route`**: Explicit routing configurations mapping paths to screens.
- **`pack`**: Aggregated bundles of the above schemas for bulk distribution.

### 10.1 Design System Bundle Example Config
```json
{
  "id": "string",
  "fingerprint": "int",
  "manifest": {},
  "aliases": {},
  "slotTypes": {},
  "slotNodes": {},
  "templates": {},
  "layouts": {},
  "decorations": {},
  "coreSchemas": {},
  "aliasSchemas": {},
  "components": {},
  "actions": {},
  "behaviors": {},
  "workflows": {},
  "stateMachines": {},
  "routes": {},
  "packs": {},
  "accessibility": {},
  "typography": {},
  "motion": {},
  "performance": {},
  "platform": {},
  "dataPolicy": {},
  "tokens": {},
  "metadata": {}
}
```

---

## 11. Omni Core Catalog & Allowed Feature Property Dictionary

The Omni Core provides 17 base categories that encompass all standard UI building blocks.

### 11.1 Base Categories and Subtypes
- **`action`**: `double_tap`, `focus`, `gesture`, `hover`, `link`, `long_press`, `pointer`, `press`, `raw_pointer`, `tap`, `viewport`.
- **`accessibility`**: `a11y`, `contrast`, `focus`, `keyboard`, `motion`, `semantics`.
- **`box`**: `aspect`, `builder`, `col`, `expanded`, `flexible`, `grid`, `layer`, `masonry`, `matrix`, `measure`, `morph`, `responsive`, `row`, `safe`, `scroll`, `shell`, `split`, `stack`, `sticky`, `surface`, `viewport`, `virtual_grid`, `wrap`.
- **`canvas`**: `draw`, `plot`, `shader`, `shape`.
- **`chart`**: `line`, `bar`, `area`, `pie`, `donut`, `radar`, `scatter`, `bubble`, `candlestick`, `funnel`, `waterfall`, `gauge`, `heat_map`, `treemap`, `sankey`.
- **`collab`**: `chat`, `comment`, `cursor`, `presence`, `room`, `whiteboard`.
- **`control`**: `button`, `checkbox`, `chip`, `date_picker`, `color_picker`, `file_picker`, `form`, `input`, `radio`, `range_slider`, `segment`, `select`, `slider`, `switch_toggle`, `time_picker`.
- **`data`**: `aggregate`, `cursor`, `diff`, `grid`, `infinite`, `kanban`, `masonry`, `paginated`, `realtime`, `repeat`, `slice`, `sliver`, `stream`, `table`, `timeline`, `virtual_scroll`.
- **`decoration`**: `border`, `shadow`, `gradient`, `backdrop_filter`, `blur`, `glass`, `glow`, `mask`, `pattern`, `particle`, `shimmer`.
- **`field`**: `text`, `number`, `email`, `password`, `phone`, `search`, `textarea`, `date`, `datetime`, `time`, `select`, `multiselect`, `file`, `image`, `checkbox`, `radio`, `switch`, `custom`.
- **`hook`**: `computed`, `effect`, `lifecycle`, `memo`, `observable`, `signal`, `state`, `store`.
- **`media`**: `audio`, `avatar`, `camera`, `document`, `gallery`, `icon`, `image`, `lottie`, `pdf`, `rive`, `sprite`, `svg`, `video`, `3d_model`.
- **`portal`**: `action_sheet`, `alert`, `dialog`, `drawer`, `dropdown`, `flyout`, `modal`, `popover`, `sheet`, `toast`, `tooltip`, `window`.
- **`stream`**: `event`, `pipe`, `reactive`, `sink`, `state`.
- **`system`**: `analytics`, `feature_flag`, `i18n`, `logger`, `metric`, `network`, `permission`, `storage`, `theme`.
- **`text`**: `heading`, `body`, `caption`, `code`, `display`, `label`, `link`, `markdown`, `paragraph`, `span`, `title`.
- **`visual`**: `animation`, `badge`, `card`, `divider`, `list_tile`, `progress`, `skeleton`, `tag`, `indicator`.

### 11.2 Full Dictionary of Valid Property Keys (Per Category)
*(Note: These are exact keys resolved during prop extraction)*
- **`action`**: `href`, `onClick`, `onTap`, `onHover`, `onLongPress`, `onFocus`, `bindState`, `value`, `icon`, `text`, `loading`, `disabled`.
- **`box`**: `align`, `padding`, `margin`, `cols`, `rows`, `gap`, `direction`, `justify`, `fill`, `scale`, `opacityBind`, `transformBind`, `clipKind`, `variant`, `style`.
- **`control` / `field`**: `label`, `placeholder`, `readOnly`, `disabled`, `bind`, `id`, `prefix`, `suffix`, `initialState`, `items`, `selected`, `onSelect`, `onToggle`.
- **`data`**: `as`, `indexAs`, `bind`, `cols`, `direction`, `pipeline`, `searchBind`.
- **`decoration`**: `mergeStyle`, `style`.
- **`media`**: `src`, `path`, `url`, `fit`, `placeholder`, `poster`, `audioUrl`, `subtitleUrl`, `autoplay`, `loop`.
- **`portal`**: `align`, `trigger`, `triggerBind`, `content`, `bgEffect`, `surfaceKind`, `presentation`, `allowUnderlyingInteraction`, `barrierDismissible`, `allowResize`, `allowDrag`, `zoomIn`, `zoomScale`.
- **`text`**: `text`, `value`, `style`, `overflow`.
- **`chart`**: `chartType`, `color`, `data`, `showAxes`, `showGrid`, `animated`, `lineWidth`, `stacked`, `smooth`, `palette`.
- **`animation`**: `animationType`, `durationMs`, `delayMs`, `curve`, `from`, `to`, `fromX`, `fromY`, `toX`, `toY`, `bind`.

---

## 12. Built-in Runtime Action Handlers (`quantum_vm.dart`)

Actions triggered via UI events (like `onTap`) that resolve natively in the VM:
- **`state.set`**: `{"key": "path", "value": "x"}` — Overwrites data at the key path in `QLDataStore`.
- **`state.toggle`**: `{"key": "path"}` — Flips a boolean flag at the key path.
- **`state.remove`**: `{"key": "path"}` — Deletes the key path entry entirely.
- **`form.set`**: `{"path": "field", "value": "x"}` — Safely updates a registered form field node.
- **`form.reset`**: `{"path": "field"}` — Restores a form field node back to its original initial value.

---

## 13. QEE Binary Codec Specification (`.qee`)

The exact binary serialization layout used to write QEE nodes to disk cache.

```
+-----------------------------------------------------------------------------------+
| MAGIC (3B: "QEE") | VER (1B) | KIND (1B) | NODE_ID (8B uint64 LE)                 |
+-----------------------------------------------------------------------------------+
| VER_NUM (4B uint32 LE) | SEALED_AT (8B int64 LE) | FLAGS (4B uint32 LE)           |
+-----------------------------------------------------------------------------------+
| STR_TABLE_COUNT (2B) | STRING TABLE DATA (each entry: 2B length + UTF-8 bytes)    |
+-----------------------------------------------------------------------------------+
| FIELD_COUNT (2B)     | FIELDS: [FIELD_ID (1B) | TYPE_TAG (1B) | VALUE_DATA] ...   |
+-----------------------------------------------------------------------------------+
```

### 13.1 Type Tag Byte Codes (`tTags`)
- `0x00`: Null
- `0x01`: Bool True
- `0x02`: Bool False
- `0x03`: Uint8
- `0x04`: Uint16
- `0x05`: Uint32
- `0x06`: Uint64
- `0x07`: Int64
- `0x08`: Float64
- `0x09`: String Ref (index into string table)
- `0x0A`: Bytes
- `0x0B`: List
- `0x0C`: NodeRef (uint64)
- `0x0D`: NodeRefList
- `0x0E`: Map
- `0x0F`: Varint

### 13.2 Field Tag Identifiers (`fTags`)
- `0x01`: `fNodeId`
- `0x02`: `fKind`
- `0x03`: `fVersion`
- `0x04`: `fSealedAt`
- `0x05`: `fFlags`
- `0x06`: `fRoutePath`
- `0x07`: `fAppId`
- `0x08`: `fAssetPath`
- `0x09`: `fParamNames`
- `0x0A`: `fLayoutRef`
- `0x0B`: `fMetaRef`
- `0x0C`: `fMiddlewareRef`
- `0x0D`: `fErrorRef`
- `0x0E`: `fLoadingRef`
- `0x0F`: `fNotFoundRef`
- `0x1A`: `fSteps`
- `0x1B`: `fBody`
- `0x1C`: `fProps`

---

## 14. Code Reality and Strictness Gaps

These are the deliberate design behaviors and parsing realities visible in the parser:

1. **Permissive Fallbacks**: The parsers (`QLYamlConfig.list`, `QLYamlConfig.map`, etc.) are heavily fallback-oriented. Scalar strings provided to a list config will be auto-wrapped in a single-element list. Unknown field types coerce to `string`. Unknown semantic YAML page types default to `page`.
2. **Untyped Payloads**: `ui`, `template`, `view`, and `layout` AST payloads remain open `dynamic` mappings in the configuration layers until runtime node construction.
3. **Route Keys**: Route configuration overlaps in mapping because `route`, `routePath`, `urlPattern`, `pattern`, and `regex` are all extracted permissively and merged depending on the parser level.
4. **_not_found Router Behavior**: `_not_found.yaml` is NOT treated as a route-adjacent special file at the file-router layer (unlike `_layout` or `_middleware`). It is handled natively at the QEE node compilation level to perform per-page 404 bubbling.
