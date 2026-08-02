// quantum.config.ts
// Strong-typed, zero-issues Quantum SDUI configuration.
// Every node "type" is validated against KnownSduiNodeType — a discriminated
// union built from the QUANTUM_CATALOG, so typos are caught at author-time
// rather than at Dart runtime (which produces a black screen on unknown types).

import {
  q,
  sdui,
  qpage,
  createTheme,
  defineStore,
  defineSlice,
  defineDataSource,
  definePipeline,
  defineTemplate,
  defineComponent,
  defineMacro,
  defineNodeType,
  extendCatalog,
  defineContracts,
  defineKernel,
  type SduiNode,
  type NodeInput,
  type ThemeInput,
  type QuantumPageTree,
  type QuantumPageBundle,
  type QuantumPageLayout,
  type QuantumPageFragment,
  type QuantumPageManifest,
  type QuantumPageSeo,
  type QuantumPageGuard,
  type QuantumPagePrefetch,
  type BoxProps,
  type TextProps,
  type ActionProps,
  type FieldProps,
  type MediaProps,
  type DataProps,
  type PortalProps,
  type HookProps,
  type ControlProps,
  type SystemProps,
  type CanvasProps,
  type DecorationProps,
  type ChartProps,
  type StreamNodeProps,
  type CollabProps,
  type ComponentProps,
  type VisualProps,
} from './sdui_ts_toolkit_preserve';

/* ============================================================
 * 0) STRONG TYPE: KnownSduiNodeType
 *
 * This union enumerates EVERY valid top-level node type the Dart
 * Quantum VM can render. Using this type on all sdui.node() calls
 * catches unknown types at TypeScript compile-time rather than
 * silently producing a black screen in Flutter at runtime.
 *
 * Pattern:
 *   Root-only types   → just the root name  ('box', 'text', ...)
 *   Root:subtype      → 'root:subtype'  ('box:scroll', 'action:button', ...)
 *   Special VM nodes  → 'component:define', 'component:use', 'template:<name>', 'macro'
 *   Custom node types → string literal from defineNodeType()
 * ============================================================ */

// Catalog root types (render directly as top-level widgets)
type CatalogRootType =
  | 'box'
  | 'action'
  | 'field'
  | 'text'
  | 'media'
  | 'data'
  | 'portal'
  | 'hook'
  | 'control'
  | 'system'
  | 'canvas'
  | 'decoration'
  | 'chart'
  | 'stream'
  | 'collab'
  | 'component'
  | 'visual'
  | 'page';

// box subtypes
type BoxSubtypeNodeType =
  | 'box:aspect' | 'box:builder' | 'box:col' | 'box:expanded' | 'box:flexible'
  | 'box:grid' | 'box:layer' | 'box:masonry' | 'box:matrix' | 'box:measure'
  | 'box:morph' | 'box:responsive' | 'box:row' | 'box:safe' | 'box:scroll'
  | 'box:shell' | 'box:split' | 'box:stack' | 'box:sticky' | 'box:surface'
  | 'box:viewport' | 'box:virtual_grid' | 'box:wrap';

// action subtypes
type ActionSubtypeNodeType =
  | 'action:button' | 'action:chip' | 'action:double_tap' | 'action:focus'
  | 'action:gesture' | 'action:hover' | 'action:icon_button' | 'action:link'
  | 'action:long_press' | 'action:pointer' | 'action:press' | 'action:raw_pointer'
  | 'action:tap' | 'action:viewport';

// field subtypes
type FieldSubtypeNodeType =
  | 'field:cell' | 'field:checkbox' | 'field:email' | 'field:multiline'
  | 'field:number' | 'field:password' | 'field:radio' | 'field:rich_text'
  | 'field:search' | 'field:slider' | 'field:tel' | 'field:text'
  | 'field:textarea' | 'field:toggle' | 'field:url';

// text subtypes
type TextSubtypeNodeType =
  | 'text:h1' | 'text:h2' | 'text:h3' | 'text:label' | 'text:code' | 'text:rich';

// media subtypes
type MediaSubtypeNodeType =
  | 'media:audio' | 'media:audio_visualizer' | 'media:avatar' | 'media:camera'
  | 'media:canvas_video' | 'media:icon' | 'media:path' | 'media:stream'
  | 'media:svg_path' | 'media:video' | 'media:webrtc';

// data subtypes
type DataSubtypeNodeType =
  | 'data:aggregate' | 'data:cursor' | 'data:diff' | 'data:grid' | 'data:infinite'
  | 'data:kanban' | 'data:masonry' | 'data:paginated' | 'data:realtime'
  | 'data:repeat' | 'data:slice' | 'data:sliver' | 'data:sliver_plane'
  | 'data:stream' | 'data:table' | 'data:timeline' | 'data:virtual_scroll';

// portal subtypes
type PortalSubtypeNodeType =
  | 'portal:action_sheet' | 'portal:alert' | 'portal:anchored_floating'
  | 'portal:centered' | 'portal:confirm' | 'portal:context_menu'
  | 'portal:context_panel' | 'portal:dialog' | 'portal:docked' | 'portal:drawer'
  | 'portal:dropdown' | 'portal:edge_attached' | 'portal:expandable_inline'
  | 'portal:flyout' | 'portal:form_modal' | 'portal:full_page_sheet'
  | 'portal:full_screen' | 'portal:full_screen_surface' | 'portal:immersive_editor'
  | 'portal:inline_details' | 'portal:inline_editor' | 'portal:inspector'
  | 'portal:lightbox' | 'portal:left_panel' | 'portal:menu' | 'portal:mobile_sheet'
  | 'portal:modal' | 'portal:navigation_rail' | 'portal:nonModal' | 'portal:non_modal'
  | 'portal:overlay' | 'portal:overlay_entry' | 'portal:persistent_drawer'
  | 'portal:persistent_panel' | 'portal:popover' | 'portal:popup_modal'
  | 'portal:right_panel' | 'portal:sheet' | 'portal:sidebar' | 'portal:side_sheet'
  | 'portal:toast' | 'portal:temporary_overlay' | 'portal:tooltip'
  | 'portal:utility_panel' | 'portal:window';

// hook subtypes
type HookSubtypeNodeType =
  | 'hook:atom' | 'hook:bridge' | 'hook:change' | 'hook:delegate' | 'hook:effect'
  | 'hook:error_boundary' | 'hook:guard' | 'hook:interval' | 'hook:lifecycle'
  | 'hook:memo' | 'hook:mount' | 'hook:observable' | 'hook:ref' | 'hook:scope'
  | 'hook:slice' | 'hook:store';

// control subtypes
type ControlSubtypeNodeType =
  | 'control:accordion' | 'control:architecture' | 'control:flow'
  | 'control:form_scope' | 'control:machine' | 'control:optimistic'
  | 'control:reducer' | 'control:saga' | 'control:stepper' | 'control:tabs'
  | 'control:tca';

// system subtypes
type SystemSubtypeNodeType =
  | 'system:async' | 'system:clipboard' | 'system:data_pipe' | 'system:debounce'
  | 'system:download' | 'system:geo' | 'system:haptic' | 'system:kinetic_pipe'
  | 'system:macro' | 'system:notification' | 'system:omega_macro' | 'system:repeater'
  | 'system:sensor' | 'system:share' | 'system:store_provider' | 'system:sync_scroll'
  | 'system:throttle' | 'system:ticker' | 'system:timer' | 'system:upload'
  | 'system:worker';

// canvas subtypes
type CanvasSubtypeNodeType =
  | 'canvas:draw' | 'canvas:plot' | 'canvas:shader' | 'canvas:shape';

// decoration subtypes
type DecorationSubtypeNodeType =
  | 'decoration:badge' | 'decoration:blur' | 'decoration:border'
  | 'decoration:gradient' | 'decoration:rich' | 'decoration:ripple'
  | 'decoration:shadow' | 'decoration:skeleton' | 'decoration:span'
  | 'decoration:text';

// chart subtypes
type ChartSubtypeNodeType =
  | 'chart:line' | 'chart:bar' | 'chart:area' | 'chart:pie' | 'chart:donut'
  | 'chart:radar' | 'chart:scatter' | 'chart:bubble' | 'chart:candlestick'
  | 'chart:funnel' | 'chart:waterfall' | 'chart:histogram' | 'chart:gauge'
  | 'chart:sparkline' | 'chart:treemap' | 'chart:sankey';

// stream / collab subtypes
type StreamSubtypeNodeType = 'stream:ws' | 'stream:sse' | 'stream:tick' | 'stream:ring' | 'stream:multiplex';
type CollabSubtypeNodeType = 'collab:presence' | 'collab:cursor' | 'collab:awareness' | 'collab:lock' | 'collab:patch';

// component / template / macro special types
type ComponentSpecialNodeType =
  | 'component:define'
  | 'component:use'
  | 'component:instance'
  | 'component:render'
  | 'component:scoped'
  | 'component:link';

// surface catalog extension types (from extendCatalog below)
type SurfaceSubtypeNodeType =
  | 'surface:page' | 'surface:shell' | 'surface:section' | 'surface:panel'
  | 'surface:hero' | 'surface:metric' | 'surface:feed' | 'surface:board';

// Custom node types defined via defineNodeType() in this file
type CustomNodeType = 'page_shell' | 'page_section';

// Empty / sentinel
type SentinelNodeType = 'empty';

/**
 * KnownSduiNodeType — the exhaustive set of type strings the Dart Quantum
 * runtime knows how to render. Use this in sdui.node<P>(type) or on any
 * hand-crafted SduiNode literal to get compile-time safety.
 *
 * WHY THIS MATTERS:
 *   If you write sdui.node('slot', ...) — 'slot' is NOT in this union.
 *   TypeScript will flag it immediately. Without this guard, the Dart DDC
 *   runtime silently renders nothing, causing a black/empty screen.
 */
export type KnownSduiNodeType =
  | CatalogRootType
  | BoxSubtypeNodeType
  | ActionSubtypeNodeType
  | FieldSubtypeNodeType
  | TextSubtypeNodeType
  | MediaSubtypeNodeType
  | DataSubtypeNodeType
  | PortalSubtypeNodeType
  | HookSubtypeNodeType
  | ControlSubtypeNodeType
  | SystemSubtypeNodeType
  | CanvasSubtypeNodeType
  | DecorationSubtypeNodeType
  | ChartSubtypeNodeType
  | StreamSubtypeNodeType
  | CollabSubtypeNodeType
  | ComponentSpecialNodeType
  | SurfaceSubtypeNodeType
  | CustomNodeType
  | SentinelNodeType;

/**
 * Typed helper: create a node with a guaranteed valid type string.
 * Replaces bare sdui.node() calls when you need compile-time checking.
 */
function typedNode<P extends Record<string, any> = BoxProps>(
  type: KnownSduiNodeType,
  init?: Partial<SduiNode>,
) {
  return sdui.node<P>(type, init);
}

/* ============================================================
 * 1) CONTRACTS
 * ============================================================ */

const contracts = defineContracts({
  session: q.object({
    userId: q.string(),
    accessToken: q.optional(q.string()),
    refreshToken: q.optional(q.string()),
    roles: q.array(q.string()),
    flags: q.record(q.boolean()),
  }),

  pageMeta: q.object({
    title: q.string(),
    description: q.optional(q.string()),
    canonical: q.optional(q.string()),
    ogImage: q.optional(q.string()),
    keywords: q.optional(q.array(q.string())),
  }),

  routeState: q.object({
    path: q.string(),
    params: q.record(q.string()),
    query: q.record(q.string()),
    locale: q.optional(q.string()),
  }),

  uiFlags: q.object({
    isMobile: q.boolean(),
    reducedMotion: q.boolean(),
    highContrast: q.boolean(),
    darkMode: q.boolean(),
  }),

  dashboardStats: q.object({
    usersOnline: q.number(),
    requestsPerMinute: q.number(),
    errorRate: q.number(),
  }),
});

/* ============================================================
 * 2) THEME
 * ============================================================ */

const theme = createTheme({
  colors: {
    brand: {
      50: '#eef7ff',
      100: '#d9ecff',
      200: '#b9ddff',
      300: '#89c6ff',
      400: '#58a8ff',
      500: '#2c86ff',
      600: '#1667e6',
      700: '#124fb4',
      800: '#103f8f',
      900: '#0e3575',
    },
    neutral: {
      50: '#f9fafb',
      100: '#f3f4f6',
      200: '#e5e7eb',
      300: '#d1d5db',
      400: '#9ca3af',
      500: '#6b7280',
      600: '#4b5563',
      700: '#374151',
      800: '#1f2937',
      900: '#111827',
    },
    success: '#16a34a',
    warning: '#f59e0b',
    danger: '#ef4444',
    info: '#0ea5e9',
    surface: '#ffffff',
    background: '#f8fafc',
    text: '#0f172a',
  },
  spacing: {
    0: 0,
    1: 4,
    2: 8,
    3: 12,
    4: 16,
    5: 20,
    6: 24,
    8: 32,
    10: 40,
    12: 48,
    16: 64,
    20: 80,
    24: 96,
  },
  typography: {
    display: { fontSize: 56, fontWeight: 800, lineHeight: 1.05 },
    h1: { fontSize: 40, fontWeight: 800, lineHeight: 1.1 },
    h2: { fontSize: 32, fontWeight: 700, lineHeight: 1.15 },
    h3: { fontSize: 24, fontWeight: 700, lineHeight: 1.2 },
    body: { fontSize: 16, fontWeight: 400, lineHeight: 1.6 },
    caption: { fontSize: 12, fontWeight: 500, lineHeight: 1.4 },
    mono: { fontSize: 13, fontWeight: 500, lineHeight: 1.4, fontFamily: 'monospace' },
  },
  radii: {
    xs: 6,
    sm: 10,
    md: 14,
    lg: 18,
    xl: 24,
    full: 999,
  },
  shadows: {
    sm: { offsetX: 0, offsetY: 1, blurRadius: 2, color: 'rgba(15, 23, 42, 0.08)' },
    md: { offsetX: 0, offsetY: 8, blurRadius: 24, color: 'rgba(15, 23, 42, 0.12)' },
    lg: { offsetX: 0, offsetY: 16, blurRadius: 40, color: 'rgba(15, 23, 42, 0.14)' },
  },
  animations: {
    fast: { duration: 120, curve: 'easeOut' },
    normal: { duration: 220, curve: 'easeInOut' },
    slow: { duration: 360, curve: 'easeOutCubic' },
  },
  breakpoints: {
    sm: 640,
    md: 768,
    lg: 1024,
    xl: 1280,
    xxl: 1536,
  },
  zIndex: {
    base: 0,
    content: 1,
    sticky: 20,
    overlay: 100,
    dropdown: 200,
    modal: 300,
    toast: 400,
  },
} satisfies ThemeInput);

/* ============================================================
 * 3) STORES
 * ============================================================ */

const authStore = defineStore('auth', () => ({
  status: 'anonymous' as 'anonymous' | 'loading' | 'authenticated' | 'error',
  userId: null as string | null,
  accessToken: null as string | null,
  refreshToken: null as string | null,
  roles: [] as string[],
  flags: {} as Record<string, boolean>,
  lastSyncedAt: null as number | null,
}));

const uiStore = defineStore('ui', () => ({
  sidebarOpen: true,
  searchOpen: false,
  commandPaletteOpen: false,
  reducedMotion: false,
  compactMode: false,
  density: 'comfortable' as 'compact' | 'comfortable' | 'spacious',
}));

const navigationStore = defineStore('navigation', () => ({
  path: '/',
  params: {} as Record<string, string>,
  query: {} as Record<string, string>,
  activeRouteId: null as string | null,
  history: [] as string[],
  breadcrumbs: [] as Array<{ label: string; path: string }>,
}));

const pageRuntimeStore = defineStore('pageRuntime', () => ({
  currentPageId: null as string | null,
  currentLayoutId: null as string | null,
  loading: false,
  error: null as string | null,
  cacheKey: null as string | null,
  prefetchQueue: [] as string[],
}));

/* ============================================================
 * 4) SLICES
 * ============================================================ */

const authSlice = defineSlice({
  namespace: 'auth',
  schema: 'session',
  state: {
    status: 'anonymous',
    userId: null,
    accessToken: null,
    refreshToken: null,
    roles: [] as string[],
    flags: {} as Record<string, boolean>,
  },
  computed: {
    isAuthenticated: 'state.status === "authenticated" && !!state.userId',
    isAnonymous: 'state.status === "anonymous"',
  },
  mutations: {
    signIn: 'auth.signIn',
    signOut: 'auth.signOut',
    refreshSession: 'auth.refresh',
  },
  queries: {
    me: { source: 'auth.me' },
  },
  resources: {
    session: { uri: 'auth.me', cacheable: true },
  },
  runtime: {
    persist: true,
    hydrateOnStart: true,
  },
  pipelines: {
    onSignIn: 'auth_sign_in_pipeline',
    onSignOut: 'auth_sign_out_pipeline',
  },
});

const pageSlice = defineSlice({
  namespace: 'page',
  schema: 'routeState',
  state: {
    path: '/',
    params: {} as Record<string, string>,
    query: {} as Record<string, string>,
    locale: 'en',
  },
  computed: {
    currentPath: 'state.path',
  },
  mutations: {
    setRoute: 'page.setRoute',
    setLocale: 'page.setLocale',
  },
  runtime: {
    persist: false,
  },
});

const dashboardSlice = defineSlice({
  namespace: 'dashboard',
  schema: 'dashboardStats',
  state: {
    usersOnline: 0,
    requestsPerMinute: 0,
    errorRate: 0,
  },
  computed: {
    healthy: 'state.errorRate < 1',
  },
  mutations: {
    setStats: 'dashboard.setStats',
  },
});

/* ============================================================
 * 5) DATA SOURCES
 * ============================================================ */

const meDataSource = defineDataSource({
  name: 'auth.me',
  schema: 'session',
  type: 'rest',
  domain: 'api_collection',
  action: 'readOne',
  resource: '/me',
  direction: 'inbound',
  select: ['userId', 'roles', 'flags'],
  query: {
    include: ['roles', 'flags'],
  },
});

const dashboardStatsDataSource = defineDataSource({
  name: 'dashboard.stats',
  schema: 'dashboardStats',
  type: 'rest',
  domain: 'api_collection',
  action: 'readOne',
  resource: '/dashboard/stats',
  direction: 'inbound',
});

const feedDataSource = defineDataSource({
  name: 'feed.list',
  type: 'rest',
  domain: 'api_collection',
  action: 'readMany',
  resource: '/feed',
  direction: 'inbound',
  select: ['id', 'title', 'summary', 'author', 'createdAt'],
  query: {
    pageSize: 20,
    includeComments: false,
  },
});

const articleDataSource = defineDataSource({
  name: 'articles.bySlug',
  type: 'rest',
  domain: 'api_collection',
  action: 'readOne',
  resource: '/articles/:slug',
  direction: 'inbound',
  params: {
    slug: '{{route.params.slug}}',
  },
});

const settingsDataSource = defineDataSource({
  name: 'settings.get',
  type: 'rest',
  domain: 'api_collection',
  action: 'readOne',
  resource: '/settings',
  direction: 'inbound',
});

/* ============================================================
 * 6) PIPELINES
 * ============================================================ */

const hydratePagePipeline = definePipeline({
  name: 'page_hydrate',
  namespace: 'app.pages',
  steps: [
    { op: 'resolveRoute' },
    { op: 'hydratePageState' },
    { op: 'loadLayout' },
    { op: 'prefetchVisibleFragments' },
    { op: 'renderFrame' },
  ],
});

const signInPipeline = definePipeline({
  name: 'auth_sign_in_pipeline',
  namespace: 'auth',
  steps: [
    { op: 'submitAuth' },
    { op: 'storeSession' },
    { op: 'warmUserCaches' },
    { op: 'navigate', to: '/dashboard' },
  ],
});

const signOutPipeline = definePipeline({
  name: 'auth_sign_out_pipeline',
  namespace: 'auth',
  steps: [
    { op: 'clearSession' },
    { op: 'clearPrivateCaches' },
    { op: 'navigate', to: '/login' },
  ],
});

/* ============================================================
 * 7) TEMPLATES
 * ============================================================ */

const heroTemplateProps = {
  eyebrow: q.optional(q.string()),
  title: q.string(),
  body: q.optional(q.string()),
  primaryLabel: q.optional(q.string()),
  secondaryLabel: q.optional(q.string()),
} as const;

const heroTemplate = defineTemplate<typeof heroTemplateProps, 'actions'>({
  name: 'hero',
  props: heroTemplateProps,
  slots: ['actions'] as const,
  defaultProps: {
    eyebrow: 'Quantum',
  },
  ui: (props, slots) =>
    sdui.box(
      [
        sdui.box(
          [
            // eyebrow (optional)
            ...(props.eyebrow
              ? [sdui.text(props.eyebrow as string, { props: { variant: 'caption' } })]
              : []),
            // title — uses text with 'heading' variant (valid TextProps)
            sdui.text(props.title as string, { props: { variant: 'heading' } }),
            // body (optional)
            ...(props.body
              ? [sdui.text(props.body as string)]
              : []),
          ],
          {
            props: {
              direction: 'col',
              gap: 12,
              padding: 0,
            } satisfies Partial<BoxProps>,
          },
        ),
        // slot outlet: a named empty box — safe for Dart to render as placeholder
        (slots?.actions ?? sdui.box([], { props: { name: 'actions' } as Record<string, unknown> })) as NodeInput,
      ],
      {
        props: {
          direction: 'col',
          gap: 24,
          padding: 24,
          radius: 24,
          bg: '$colors.surface',
          shadow: '$shadows.md',
        } satisfies Partial<BoxProps>,
      },
    ),
});

const statCardTemplateProps = {
  label: q.string(),
  value: q.string(),
  hint: q.optional(q.string()),
  tone: q.optional(q.enum('brand', 'success', 'warning', 'danger', 'neutral')),
} as const;

const statCardTemplate = defineTemplate({
  name: 'stat_card',
  props: statCardTemplateProps,
  defaultProps: {
    tone: 'neutral',
  },
  ui: (props) =>
    sdui.box(
      [
        sdui.text(props.label as string, { props: { variant: 'caption' } }),
        sdui.text(props.value as string, { props: { variant: 'heading' } }),
        ...(props.hint
          ? [sdui.text(props.hint as string, { props: { variant: 'caption' } })]
          : []),
      ],
      {
        props: {
          direction: 'col',
          gap: 6,
          padding: 18,
          radius: 18,
          bg: '$colors.surface',
          shadow: '$shadows.sm',
        } satisfies Partial<BoxProps>,
      },
    ),
});

const sectionTemplateProps = {
  title: q.string(),
  description: q.optional(q.string()),
  compact: q.optional(q.boolean()),
} as const;

const sectionTemplate = defineTemplate<typeof sectionTemplateProps, 'body' | 'footer'>({
  name: 'section',
  props: sectionTemplateProps,
  slots: ['body', 'footer'] as const,
  ui: (props, slots) =>
    sdui.box(
      [
        // header row: title + optional description
        sdui.box(
          [
            sdui.text(props.title as string, { props: { variant: 'heading' } }),
            ...(props.description
              ? [sdui.text(props.description as string)]
              : []),
          ],
          {
            props: {
              direction: 'col',
              gap: 8,
            } satisfies Partial<BoxProps>,
          },
        ),
        // body slot outlet — empty box if not provided
        (slots?.body ?? sdui.box([], { props: { name: 'body' } as Record<string, unknown> })) as NodeInput,
        // footer slot outlet — empty box if not provided
        (slots?.footer ?? sdui.box([], { props: { name: 'footer' } as Record<string, unknown> })) as NodeInput,
      ],
      {
        props: {
          direction: 'col',
          gap: (props.compact ? 12 : 20) as number,
          padding: (props.compact ? 16 : 24) as number,
        } satisfies Partial<BoxProps>,
      },
    ),
});

/* ============================================================
 * 8) COMPONENTS
 * ============================================================ */

const pageHeaderProps = {
  title: q.string(),
  subtitle: q.optional(q.string()),
  actionLabel: q.optional(q.string()),
} as const;

/**
 * page_header component.
 *
 * FIX (black-screen root cause):
 *   The previous version used sdui.node('slot', { props: { name: 'action' } }).
 *   'slot' is NOT a valid Dart-renderable node type — the VM has no widget for
 *   it and produces an empty / black render.
 *
 *   Correct pattern: emit a 'box' with a named __slotOutlet prop so that any
 *   parent component/layout that injects into the 'action' slot can find and
 *   replace this placeholder. An empty box with a slot marker is safe for Dart
 *   to render as zero-size and will not cause a black screen.
 */
const pageHeaderComponent = defineComponent(
  'page_header',
  {
    props: pageHeaderProps,
    ui: (props) =>
      sdui.box(
        [
          // Left: title + optional subtitle stack
          sdui.box(
            [
              sdui.text(props.title as string, { props: { variant: 'heading' } }),
              // Conditional subtitle — emit the node with $if so the Dart VM
              // evaluates the condition at runtime and skips it when falsy
              sdui.text(props.subtitle as string).if(props.subtitle as string),
            ],
            {
              props: {
                direction: 'col',
                gap: 8,
              } satisfies Partial<BoxProps>,
            },
          ),
          // Right: slot outlet for "action" content.
          // ✅ Uses 'box' (valid Dart type) with __slotOutlet marker,
          //    NOT 'slot' (invalid → black screen).
          typedNode<BoxProps>('box', {
            props: {
              name: 'action',
              __slotOutlet: true,
            } as Record<string, unknown>,
          }),
        ],
        {
          props: {
            direction: 'row',
            crossAlignment: 'center',
            mainAlignment: 'space-between',
            gap: 16,
            padding: 0,
          } satisfies Partial<BoxProps>,
        },
      ),
  },
);

const navRailProps = {
  current: q.string(),
  collapsed: q.optional(q.boolean()),
} as const;

const navRailComponent = defineComponent(
  'nav_rail',
  {
    props: navRailProps,
    ui: (props) =>
      sdui.box(
        [
          sdui.text('Navigation', { props: { variant: 'caption' } }),
          sdui.text(props.current as string),
        ],
        {
          props: {
            direction: 'col',
            gap: 8,
            padding: 16,
            radius: 20,
            bg: '$colors.surface',
          } satisfies Partial<BoxProps>,
        },
      ),
  },
);

/* ============================================================
 * 9) MACROS
 * ============================================================ */

const pagePaddingMacro = defineMacro(
  'page_padding',
  {
    ui: sdui.box([], {
      props: {
        padding: 24,
        radius: 24,
      } satisfies Partial<BoxProps>,
    }),
  },
);

const contentFrameMacro = defineMacro(
  'content_frame',
  {
    ui: sdui.box([], {
      props: {
        direction: 'col',
        gap: 20,
        padding: 24,
      } satisfies Partial<BoxProps>,
    }),
  },
);

/* ============================================================
 * 10) CUSTOM NODE TYPES
 *
 * defineNodeType() registers a new node type for use in the
 * Dart Quantum VM. The string in `type` MUST match what the
 * Dart renderer has registered; here 'page_shell' and
 * 'page_section' are first-class custom widget types.
 * ============================================================ */

const pageShellProps = {
  title: q.string(),
  compact: q.optional(q.boolean()),
  showSidebar: q.optional(q.boolean()),
  showFooter: q.optional(q.boolean()),
} as const;

// 'page_shell' is a valid CustomNodeType — listed in KnownSduiNodeType above
const pageShellNode = defineNodeType({
  type: 'page_shell' satisfies KnownSduiNodeType,
  props: pageShellProps,
  slots: ['header', 'sidebar', 'content', 'footer'] as const,
  children: false,
});

const pageSectionProps = {
  title: q.string(),
  padded: q.optional(q.boolean()),
} as const;

// 'page_section' is a valid CustomNodeType — listed in KnownSduiNodeType above
const pageSectionNode = defineNodeType({
  type: 'page_section' satisfies KnownSduiNodeType,
  props: pageSectionProps,
  slots: ['header', 'body', 'footer'] as const,
  children: false,
});

/* ============================================================
 * 11) CATALOG EXTENSIONS
 * ============================================================ */

const extensions = extendCatalog({
  surface: ['page', 'shell', 'section', 'panel', 'hero', 'metric', 'feed', 'board'] as const,
});

/* ============================================================
 * 12) LAYOUTS / FRAGMENTS / PAGES
 * ============================================================ */

const publicShellLayout: QuantumPageLayout = qpage.layout({
  name: 'public_shell',
  mode: 'shell',
  viewport: 'responsive',
  scaffold: true,
  safeArea: 'all',
  template: pageShellNode.create(
    {
      title: 'Public',
      compact: false,
      showSidebar: false,
      showFooter: true,
    },
    {
      header: sdui.box(
        [
          pageHeaderComponent.use(
            {
              title: 'Quantum',
              subtitle: 'The fastest SDUI runtime',
              actionLabel: undefined,
            },
            {},
          ),
        ],
        {
          props: {
            padding: 24,
          } satisfies Partial<BoxProps>,
        },
      ),
      content: sdui.box(
        [sdui.text('Content area', { props: { variant: 'body' } })],
        {
          props: {
            direction: 'col',
            gap: 24,
            padding: 24,
          } satisfies Partial<BoxProps>,
        },
      ),
      footer: sdui.box(
        [sdui.text('© Quantum')],
        {
          props: {
            padding: 24,
          } satisfies Partial<BoxProps>,
        },
      ),
    },
  ),
  slots: {
    header: { scrollable: false },
    content: { scrollable: true },
    footer: { scrollable: false },
  },
  meta: {
    name: 'public',
    layer: 'shell',
  },
});

const dashboardShellLayout: QuantumPageLayout = qpage.layout({
  name: 'dashboard_shell',
  mode: 'shell',
  viewport: 'responsive',
  scaffold: true,
  safeArea: 'all',
  template: pageShellNode.create(
    {
      title: 'Dashboard',
      compact: false,
      showSidebar: true,
      showFooter: false,
    },
    {
      sidebar: navRailComponent.use(
        {
          current: '/dashboard',
          collapsed: false,
        },
        {},
      ),
      content: sdui.box(
        [sdui.text('Dashboard content', { props: { variant: 'body' } })],
        {
          props: {
            direction: 'col',
            gap: 24,
            padding: 24,
          } satisfies Partial<BoxProps>,
        },
      ),
    },
  ),
  slots: {
    sidebar: { scrollable: true, sticky: true },
    content: { scrollable: true },
  },
  meta: {
    name: 'dashboard',
    layer: 'shell',
  },
});

const authShellLayout: QuantumPageLayout = qpage.layout({
  name: 'auth_shell',
  mode: 'shell',
  viewport: 'responsive',
  scaffold: true,
  safeArea: 'all',
  template: pageShellNode.create(
    {
      title: 'Auth',
      compact: true,
      showSidebar: false,
      showFooter: false,
    },
    {
      content: sdui.box(
        [sdui.text('Auth content', { props: { variant: 'body' } })],
        {
          props: {
            direction: 'col',
            gap: 20,
            padding: 24,
          } satisfies Partial<BoxProps>,
        },
      ),
    },
  ),
});

const docsShellLayout: QuantumPageLayout = qpage.layout({
  name: 'docs_shell',
  mode: 'matrix',
  viewport: 'responsive',
  scaffold: true,
  safeArea: 'all',
  template: pageShellNode.create(
    {
      title: 'Docs',
      compact: false,
      showSidebar: true,
      showFooter: true,
    },
    {
      sidebar: navRailComponent.use(
        {
          current: '/docs',
          collapsed: false,
        },
        {},
      ),
      content: sdui.box(
        [sdui.text('Docs content', { props: { variant: 'body' } })],
        {
          props: {
            direction: 'col',
            gap: 20,
            padding: 24,
          } satisfies Partial<BoxProps>,
        },
      ),
      footer: sdui.box(
        [sdui.text('Built with Quantum')],
        {
          props: {
            padding: 16,
          } satisfies Partial<BoxProps>,
        },
      ),
    },
  ),
});

/* ---- Fragments ---- */

const homeHeroFragment: QuantumPageFragment = qpage.fragment({
  name: 'home_hero',
  lazy: false,
  hydrate: 'immediate',
  template: heroTemplate.use(
    {
      eyebrow: 'Introducing',
      title: 'Build anything with one JSON graph',
      body: 'Pages, layouts, fragments, guards, pipelines, and nested routes all compile into a fast Flutter render tree.',
      primaryLabel: 'Start',
      secondaryLabel: 'Docs',
    },
    {
      actions: sdui.box(
        [
          // action nodes — use 'action' root type (valid in KnownSduiNodeType)
          sdui.button({ text: 'Get Started', intent: 'primary', variant: 'solid' }),
          sdui.button({ text: 'Read Docs', intent: 'ghost', variant: 'outline' }),
        ],
        {
          props: {
            direction: 'row',
            gap: 12,
          } satisfies Partial<BoxProps>,
        },
      ),
    },
  ),
  tags: ['hero', 'landing', 'marketing'],
  meta: {
    section: 'home',
  },
});

const homeStatsFragment: QuantumPageFragment = qpage.fragment({
  name: 'home_stats',
  lazy: true,
  hydrate: 'visible',
  template: sdui.box(
    [
      statCardTemplate.use({ label: 'Users Online', value: '12.4K', hint: '+14% today', tone: undefined }),
      statCardTemplate.use({ label: 'RPM', value: '1.2M', hint: 'stable', tone: undefined }),
      statCardTemplate.use({ label: 'Error Rate', value: '0.08%', hint: 'last 5 min', tone: undefined }),
    ],
    {
      props: {
        direction: 'row',
        gap: 16,
      } satisfies Partial<BoxProps>,
    },
  ),
});

const dashboardHomeFragment: QuantumPageFragment = qpage.fragment({
  name: 'dashboard_home',
  lazy: false,
  hydrate: 'immediate',
  template: sdui.box(
    [
      pageHeaderComponent.use(
        {
          title: 'Dashboard',
          subtitle: 'Live metrics, activity, and drill-down pages',
          actionLabel: undefined,
        },
        {},
      ),
      sectionTemplate.use(
        {
          title: 'Overview',
          description: 'Everything that matters at a glance.',
          compact: false,
        },
        {
          body: sdui.box(
            [
              statCardTemplate.use({ label: 'Users Online', value: '18.2K', hint: 'peak 1h', tone: undefined }),
              statCardTemplate.use({ label: 'Requests / Min', value: '240K', hint: 'rolling average', tone: undefined }),
              statCardTemplate.use({ label: 'Error Rate', value: '0.04%', hint: 'healthy', tone: undefined }),
            ],
            {
              props: {
                direction: 'row',
                gap: 16,
              } satisfies Partial<BoxProps>,
            },
          ),
        },
      ),
    ],
    {
      props: {
        direction: 'col',
        gap: 24,
      } satisfies Partial<BoxProps>,
    },
  ),
});

const articleFragment: QuantumPageFragment = qpage.fragment({
  name: 'article_view',
  lazy: true,
  hydrate: 'visible',
  template: sdui.box(
    [
      pageHeaderComponent.use(
        {
          title: 'Article',
          subtitle: 'Nested route content',
          actionLabel: undefined,
        },
        {},
      ),
      sectionTemplate.use(
        {
          title: 'Body',
          description: 'This block renders the fetched article content.',
          compact: false,
        },
        {
          body: sdui.box(
            [sdui.text('Article body placeholder', { props: { variant: 'body' } })],
            {
              props: {
                direction: 'col',
                gap: 16,
              } satisfies Partial<BoxProps>,
            },
          ),
        },
      ),
    ],
    {
      props: {
        direction: 'col',
        gap: 24,
      } satisfies Partial<BoxProps>,
    },
  ),
});

const settingsFragment: QuantumPageFragment = qpage.fragment({
  name: 'settings_view',
  lazy: false,
  hydrate: 'immediate',
  template: sdui.box(
    [
      pageHeaderComponent.use(
        {
          title: 'Settings',
          subtitle: 'Profile, security, and preferences',
          actionLabel: undefined,
        },
        {},
      ),
      sectionTemplate.use(
        {
          title: 'Account',
          description: 'Manage your account details.',
          compact: false,
        },
        {},
      ),
    ],
    {
      props: {
        direction: 'col',
        gap: 24,
      } satisfies Partial<BoxProps>,
    },
  ),
});

const docsIndexFragment: QuantumPageFragment = qpage.fragment({
  name: 'docs_index',
  lazy: false,
  hydrate: 'immediate',
  template: sdui.box(
    [
      pageHeaderComponent.use(
        {
          title: 'Documentation',
          subtitle: 'A nested, route-driven knowledge surface',
          actionLabel: undefined,
        },
        {},
      ),
      sectionTemplate.use(
        {
          title: 'Start here',
          description: 'Explore nested docs pages with layout inheritance.',
          compact: false,
        },
        {},
      ),
    ],
    {
      props: {
        direction: 'col',
        gap: 24,
      } satisfies Partial<BoxProps>,
    },
  ),
});

/* ---- SEO / Guards / Prefetch helpers ---- */

const homeSeo: QuantumPageSeo = qpage.seo({
  title: 'Quantum',
  description: 'A powerful SDUI runtime for Flutter and JSON render graphs.',
  canonical: '/',
  robots: 'index,follow',
  customMeta: {
    section: 'home',
  },
});

const dashboardSeo: QuantumPageSeo = qpage.seo({
  title: 'Dashboard | Quantum',
  description: 'Live metrics and deep nested pages.',
  canonical: '/dashboard',
  robots: 'noindex,follow',
});

const docsSeo: QuantumPageSeo = qpage.seo({
  title: 'Docs | Quantum',
  description: 'Nested docs with route-aware layouts and fragments.',
  canonical: '/docs',
});

const authGuard: QuantumPageGuard = qpage.guard({
  name: 'require_auth',
  type: 'auth',
  redirectTo: '/login',
});

const adminGuard: QuantumPageGuard = qpage.guard({
  name: 'require_admin',
  type: 'role',
  role: ['admin'],
  redirectTo: '/dashboard',
});

const dashboardPrefetch: QuantumPagePrefetch = qpage.prefetch({
  routes: ['/dashboard/reports', '/dashboard/settings'],
  assets: ['images/dashboard-hero.png'],
  data: ['dashboard.stats'],
  layout: true,
  fragments: ['dashboard_home'],
  priority: 'high',
  viewport: 'idle',
});

const docsPrefetch: QuantumPagePrefetch = qpage.prefetch({
  routes: ['/docs/getting-started', '/docs/api', '/docs/guides'],
  layout: true,
  fragments: ['docs_index'],
  priority: 'normal',
  viewport: 'visible',
});

/* ---- Page tree ---- */

const appPages: QuantumPageTree = qpage.tree([
  qpage.page({
    id: 'home',
    name: 'home',
    path: '/',
    layout: qpage.layoutRef('public_shell'),
    page: qpage.fragmentRef('home_hero'),
    seo: homeSeo,
    prefetch: qpage.prefetch({
      routes: ['/dashboard', '/docs'],
      layout: true,
      priority: 'high',
      viewport: 'idle',
    }),
    meta: {
      area: 'marketing',
      kind: 'landing',
    },
    children: qpage.tree([
      qpage.page({
        id: 'pricing',
        name: 'pricing',
        path: '/pricing',
        layout: qpage.layoutRef('public_shell'),
        page: qpage.fragmentRef('home_hero'),
        seo: qpage.seo({
          title: 'Pricing | Quantum',
          description: 'Flexible pricing for teams that need real performance.',
        }),
        meta: {
          area: 'marketing',
          section: 'pricing',
        },
      }),
      qpage.page({
        id: 'about',
        name: 'about',
        path: '/about',
        layout: qpage.layoutRef('public_shell'),
        page: qpage.fragmentRef('home_stats'),
        seo: qpage.seo({
          title: 'About | Quantum',
          description: 'The engine behind the page graph.',
        }),
        meta: {
          area: 'marketing',
          section: 'about',
        },
      }),
    ]),
  }),

  qpage.page({
    id: 'login',
    name: 'login',
    path: '/login',
    layout: qpage.layoutRef('auth_shell'),
    page: qpage.fragmentRef('home_hero'),
    seo: qpage.seo({
      title: 'Login | Quantum',
      description: 'Authenticate to continue.',
      robots: 'noindex,follow',
    }),
    meta: {
      area: 'auth',
    },
  }),

  qpage.page({
    id: 'dashboard',
    name: 'dashboard',
    path: '/dashboard',
    layout: qpage.layoutRef('dashboard_shell'),
    page: qpage.fragmentRef('dashboard_home'),
    guards: [authGuard, adminGuard],
    seo: dashboardSeo,
    prefetch: dashboardPrefetch,
    meta: {
      area: 'app',
      section: 'dashboard',
    },
    children: qpage.tree([
      qpage.page({
        id: 'dashboard_reports',
        name: 'dashboard_reports',
        path: '/dashboard/reports',
        layout: qpage.layoutRef('dashboard_shell'),
        page: qpage.fragmentRef('dashboard_home'),
        guards: [authGuard],
        seo: qpage.seo({
          title: 'Reports | Dashboard',
          description: 'Analytics and report breakdown pages.',
        }),
        prefetch: qpage.prefetch({
          routes: ['/dashboard/reports/[reportId]'],
          data: ['dashboard.stats'],
          layout: true,
          priority: 'high',
        }),
        meta: {
          area: 'app',
          section: 'reports',
        },
        children: qpage.tree([
          qpage.page({
            id: 'dashboard_report_detail',
            name: 'dashboard_report_detail',
            path: '/dashboard/reports/[reportId]',
            layout: qpage.layoutRef('dashboard_shell'),
            page: qpage.fragmentRef('article_view'),
            guards: [authGuard],
            seo: qpage.seo({
              title: 'Report Detail | Dashboard',
              description: 'Route parameter driven deep page.',
            }),
            meta: {
              area: 'app',
              section: 'report_detail',
            },
          }),
        ]),
      }),

      qpage.page({
        id: 'dashboard_settings',
        name: 'dashboard_settings',
        path: '/dashboard/settings',
        layout: qpage.layoutRef('dashboard_shell'),
        page: qpage.fragmentRef('settings_view'),
        guards: [authGuard],
        seo: qpage.seo({
          title: 'Settings | Dashboard',
          description: 'User preferences and security.',
        }),
        meta: {
          area: 'app',
          section: 'settings',
        },
      }),
    ]),
  }),

  qpage.page({
    id: 'settings',
    name: 'settings',
    path: '/settings',
    layout: qpage.layoutRef('dashboard_shell'),
    page: qpage.fragmentRef('settings_view'),
    guards: [authGuard],
    seo: qpage.seo({
      title: 'Settings | Quantum',
      description: 'Full settings surface.',
    }),
    meta: {
      area: 'app',
    },
    children: qpage.tree([
      qpage.page({
        id: 'settings_profile',
        name: 'settings_profile',
        path: '/settings/profile',
        layout: qpage.layoutRef('dashboard_shell'),
        page: qpage.fragmentRef('settings_view'),
        guards: [authGuard],
        seo: qpage.seo({
          title: 'Profile | Settings',
        }),
      }),
      qpage.page({
        id: 'settings_security',
        name: 'settings_security',
        path: '/settings/security',
        layout: qpage.layoutRef('dashboard_shell'),
        page: qpage.fragmentRef('settings_view'),
        guards: [authGuard],
        seo: qpage.seo({
          title: 'Security | Settings',
        }),
      }),
    ]),
  }),

  qpage.page({
    id: 'docs',
    name: 'docs',
    path: '/docs',
    layout: qpage.layoutRef('docs_shell'),
    page: qpage.fragmentRef('docs_index'),
    seo: docsSeo,
    prefetch: docsPrefetch,
    meta: {
      area: 'docs',
    },
    children: qpage.tree([
      qpage.page({
        id: 'docs_getting_started',
        name: 'docs_getting_started',
        path: '/docs/getting-started',
        layout: qpage.layoutRef('docs_shell'),
        page: qpage.fragmentRef('docs_index'),
        seo: qpage.seo({
          title: 'Getting Started | Docs',
        }),
      }),
      qpage.page({
        id: 'docs_api',
        name: 'docs_api',
        path: '/docs/api',
        layout: qpage.layoutRef('docs_shell'),
        page: qpage.fragmentRef('article_view'),
        seo: qpage.seo({
          title: 'API | Docs',
        }),
      }),
      qpage.page({
        id: 'docs_catch_all',
        name: 'docs_catch_all',
        path: '/docs/[...slug]',
        layout: qpage.layoutRef('docs_shell'),
        page: qpage.fragmentRef('article_view'),
        nested: true,
        seo: qpage.seo({
          title: 'Docs Page',
        }),
      }),
    ]),
  }),
]);

const appLayouts = {
  public_shell: publicShellLayout,
  dashboard_shell: dashboardShellLayout,
  auth_shell: authShellLayout,
  docs_shell: docsShellLayout,
} satisfies Record<string, QuantumPageLayout>;

const appFragments = {
  home_hero: homeHeroFragment,
  home_stats: homeStatsFragment,
  dashboard_home: dashboardHomeFragment,
  article_view: articleFragment,
  settings_view: settingsFragment,
  docs_index: docsIndexFragment,
} satisfies Record<string, QuantumPageFragment>;

const pageBundle: QuantumPageBundle = qpage.bundle({
  pages: appPages,
  layouts: appLayouts,
  fragments: appFragments,
  seo: {
    home: homeSeo,
    dashboard: dashboardSeo,
    docs: docsSeo,
  },
  guards: {
    auth: authGuard,
    admin: adminGuard,
  },
  prefetch: {
    dashboard: dashboardPrefetch,
    docs: docsPrefetch,
  },
  meta: {
    appName: 'Quantum Super App',
    runtime: 'flutter',
    pagesDir: 'pages',
  },
});

/* ============================================================
 * 13) APP MODEL
 * ============================================================ */

interface QuantumAppModel {
  name: string;
  version: string;
  description: string;
  pagesDir: string;
  pages: QuantumPageTree;
  layouts: Record<string, QuantumPageLayout>;
  fragments: Record<string, QuantumPageFragment>;
  bundle: QuantumPageBundle;
  routing: {
    basePath: string;
    defaultTransition: string;
    notFoundPath: string;
    scrollRestoration: boolean;
    trailingSlash: boolean;
  };
  performance: {
    lazyPages: boolean;
    lazyLayouts: boolean;
    lazyFragments: boolean;
    cacheRoutes: boolean;
    cacheBundles: boolean;
    prefetchOnHover: boolean;
    prefetchOnVisible: boolean;
  };
  navigation: {
    nestedPages: boolean;
    routeGroups: boolean;
    routeParams: boolean;
    catchAllRoutes: boolean;
  };
  featureFlags: Record<string, boolean>;
  telemetry: {
    enabled: boolean;
    logRoutes: boolean;
    logGuards: boolean;
    logPrefetch: boolean;
  };
  runtime: {
    engine: 'flutter';
    sdui: 'json';
    version: string;
  };
}

const appManifest: QuantumAppModel = {
  name: 'Quantum Super App',
  version: '1.0.0',
  description:
    'A schema-first SDUI platform with nested pages, layouts, fragments, guards, and prefetch.',
  pagesDir: 'pages',
  pages: appPages,
  layouts: appLayouts,
  fragments: appFragments,
  bundle: pageBundle,
  routing: {
    basePath: '/',
    defaultTransition: 'slideRight',
    notFoundPath: '/404',
    scrollRestoration: true,
    trailingSlash: false,
  },
  performance: {
    lazyPages: true,
    lazyLayouts: true,
    lazyFragments: true,
    cacheRoutes: true,
    cacheBundles: true,
    prefetchOnHover: true,
    prefetchOnVisible: true,
  },
  navigation: {
    nestedPages: true,
    routeGroups: true,
    routeParams: true,
    catchAllRoutes: true,
  },
  featureFlags: {
    dashboard: true,
    docs: true,
    auth: true,
    prefetch: true,
    nestedRouting: true,
    routeGroups: true,
  },
  telemetry: {
    enabled: true,
    logRoutes: true,
    logGuards: true,
    logPrefetch: true,
  },
  runtime: {
    engine: 'flutter',
    sdui: 'json',
    version: 'v2',
  },
};

/* ============================================================
 * 14) KERNEL
 * ============================================================ */

const quantumKernel = defineKernel({
  contracts,
  theme,
  stores: {
    auth: authStore,
    ui: uiStore,
    navigation: navigationStore,
    pageRuntime: pageRuntimeStore,
  },
  slices: {
    auth: authSlice,
    page: pageSlice,
    dashboard: dashboardSlice,
  },
  dataSources: {
    me: meDataSource,
    dashboardStats: dashboardStatsDataSource,
    feed: feedDataSource,
    article: articleDataSource,
    settings: settingsDataSource,
  },
  templates: {
    hero: heroTemplate,
    statCard: statCardTemplate,
    section: sectionTemplate,
  },
  components: {
    pageHeader: pageHeaderComponent,
    navRail: navRailComponent,
  },
  macros: {
    pagePadding: pagePaddingMacro,
    contentFrame: contentFrameMacro,
  },
  pipelines: {
    hydratePage: hydratePagePipeline,
    authSignIn: signInPipeline,
    authSignOut: signOutPipeline,
  },
  extensions,
  app: appManifest,
});

export const quantumConfig = quantumKernel.defineConfig();

export {
  // types
  type KnownSduiNodeType,
  // helpers
  typedNode,
  // contracts / theme
  contracts,
  theme,
  // stores
  authStore,
  uiStore,
  navigationStore,
  pageRuntimeStore,
  // slices
  authSlice,
  pageSlice,
  dashboardSlice,
  // data sources
  meDataSource,
  dashboardStatsDataSource,
  feedDataSource,
  articleDataSource,
  settingsDataSource,
  // pipelines
  hydratePagePipeline,
  signInPipeline,
  signOutPipeline,
  // templates
  heroTemplate,
  statCardTemplate,
  sectionTemplate,
  // components
  pageHeaderComponent,
  navRailComponent,
  // macros
  pagePaddingMacro,
  contentFrameMacro,
  // node types
  pageShellNode,
  pageSectionNode,
  // extensions
  extensions,
  // page tree / layouts / fragments
  appPages,
  appLayouts,
  appFragments,
  pageBundle,
  appManifest,
};

export default quantumConfig;
