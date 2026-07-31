// quantum.config.ts
// Adjust the import path if your SDK barrel uses a different name.

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
  type ThemeInput,
  type QuantumPageTree,
  type QuantumPageBundle,
  type QuantumPageLayout,
  type QuantumPageFragment,
  type QuantumPageManifest,
  type QuantumPageSeo,
  type QuantumPageGuard,
  type QuantumPagePrefetch,
} from './sdui_ts_toolkit_preserve';

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
    session: { source: 'auth.me', cache: true },
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
            ...(props.eyebrow ? [sdui.text(props.eyebrow)] : []),
            sdui.title(props.title),
            ...(props.body ? [sdui.text(props.body)] : []),
          ],
          {
            props: {
              direction: 'col',
              gap: 12,
              padding: 0,
            },
          },
        ),
        slots.actions ?? sdui.box([]),
      ],
      {
        props: {
          direction: 'col',
          gap: 24,
          padding: 24,
          radius: 24,
          bg: '$colors.surface',
          shadow: '$shadows.md',
        },
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
        sdui.text(props.label),
        sdui.title(props.value),
        ...(props.hint ? [sdui.text(props.hint)] : []),
      ],
      {
        props: {
          direction: 'col',
          gap: 6,
          padding: 18,
          radius: 18,
          bg: '$colors.surface',
          shadow: '$shadows.sm',
        },
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
        sdui.box(
          [
            sdui.title(props.title),
            ...(props.description ? [sdui.text(props.description)] : []),
          ],
          {
            props: {
              direction: 'col',
              gap: 8,
            },
          },
        ),
        slots.body ?? sdui.box([]),
        slots.footer ?? sdui.box([]),
      ],
      {
        props: {
          direction: 'col',
          gap: props.compact ? 12 : 20,
          padding: props.compact ? 16 : 24,
        },
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

// Look: No <typeof pageHeaderProps> generic needed anymore! 
const pageHeaderComponent = defineComponent(
  'page_header',
  {
    props: pageHeaderProps,
    ui: (props) =>
      sdui.box(
        [
          sdui.box(
            [
              sdui.title(props.title),
              // Defer conditional rendering to Dart at runtime
              sdui.text(props.subtitle).if(props.subtitle),
            ],
            {
              props: {
                direction: 'col',
                gap: 8,
              },
            },
          ),
          // Emit a slot node. Dart VM will inject the caller's slot here!
          sdui.node('slot', { props: { name: 'action' } })
        ],
        {
          props: {
            direction: 'row',
            crossAlignment: 'center',
            mainAlignment: 'space-between',
            gap: 16,
            padding: 0,
          },
        },
      ),
  }
);

const navRailProps = {
  current: q.string(),
  collapsed: q.optional(q.boolean()),
} as const;

// Look: No generic needed! Auto-inferred flawlessly.
const navRailComponent = defineComponent(
  'nav_rail',
  {
    props: navRailProps,
    ui: (props) =>
      sdui.box(
        [
          sdui.text('Navigation'),
          sdui.text(props.current),
        ],
        {
          props: {
            direction: 'col',
            gap: 8,
            padding: 16,
            radius: 20,
            bg: '$colors.surface',
          },
        },
      ),
  }
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
      },
    }),
  }
);

const contentFrameMacro = defineMacro(
  'content_frame',
  {
    ui: sdui.box([], {
      props: {
        direction: 'col',
        gap: 20,
        padding: 24,
      },
    }),
  }
);


/* ============================================================
 * 10) CUSTOM NODE TYPES
 * ============================================================ */

const pageShellProps = {
  title: q.string(),
  compact: q.optional(q.boolean()),
  showSidebar: q.optional(q.boolean()),
  showFooter: q.optional(q.boolean()),
} as const;

const pageShellNode = defineNodeType({
  type: 'page_shell',
  props: pageShellProps,
  slots: ['header', 'sidebar', 'content', 'footer'] as const,
  children: false,
});

const pageSectionProps = {
  title: q.string(),
  padded: q.optional(q.boolean()),
} as const;

const pageSectionNode = defineNodeType({
  type: 'page_section',
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
          },
        },
      ),
      content: sdui.box([], {
        props: {
          direction: 'col',
          gap: 24,
          padding: 24,
        },
      }),
      footer: sdui.box([sdui.text('© Quantum')], {
        props: {
          padding: 24,
        },
      }),
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
      content: sdui.box([], {
        props: {
          direction: 'col',
          gap: 24,
          padding: 24,
        },
      }),
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
      content: sdui.box([], {
        props: {
          direction: 'col',
          gap: 20,
          padding: 24,
        },
      }),
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
      content: sdui.box([], {
        props: {
          direction: 'col',
          gap: 20,
          padding: 24,
        },
      }),
      footer: sdui.box([sdui.text('Built with Quantum')], {
        props: {
          padding: 16,
        },
      }),
    },
  ),
});

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
          sdui.button({ text: 'Get Started', intent: 'primary', variant: 'solid' }),
          sdui.button({ text: 'Read Docs', intent: 'ghost', variant: 'outline' }),
        ],
        {
          props: {
            direction: 'row',
            gap: 12,
          },
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
      },
    },
  ),
});

const dashboardHomeFragment: QuantumPageFragment = qpage.fragment({
  name: 'dashboard_home',
  lazy: false,
  hydrate: 'immediate',
  template: sdui.box(
    [
      pageHeaderComponent
        .use(
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
              },
            },
          ),
        },
      ),
    ],
    {
      props: {
        direction: 'col',
        gap: 24,
      },
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
          body: sdui.box([], {
            props: {
              direction: 'col',
              gap: 16,
            },
          }),
        },
      ),
    ],
    {
      props: {
        direction: 'col',
        gap: 24,
      },
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
      },
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
      },
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

/* ---- Nested pages ---- */

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
  contracts,
  theme,
  authStore,
  uiStore,
  navigationStore,
  pageRuntimeStore,
  authSlice,
  pageSlice,
  dashboardSlice,
  meDataSource,
  dashboardStatsDataSource,
  feedDataSource,
  articleDataSource,
  settingsDataSource,
  hydratePagePipeline,
  signInPipeline,
  signOutPipeline,
  heroTemplate,
  statCardTemplate,
  sectionTemplate,
  pageHeaderComponent,
  navRailComponent,
  pagePaddingMacro,
  contentFrameMacro,
  pageShellNode,
  pageSectionNode,
  extensions,
  appPages,
  appLayouts,
  appFragments,
  pageBundle,
  appManifest,
};

export default quantumConfig;
