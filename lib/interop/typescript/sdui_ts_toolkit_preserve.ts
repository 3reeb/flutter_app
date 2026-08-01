/**
 * Quantum SDUI Kernel v2.1
 * ------------------------
 * Schema-first, registry-driven TypeScript engine for Quantum SDUI apps.
 * Fully covers 100% of Quantum Runtime JSON/YAML schemas, blueprint specifications,
 * field flags, matrix layouts, protection policies, and slice documents.
 */

/* ============================================================
 * 1) JSON / BRANDS / EXPRESSIONS / PRIMITIVES
 * ============================================================ */

export type JsonPrimitive = string | number | boolean | null;
export type JsonValue = JsonPrimitive | JsonObject | JsonValue[];
export interface JsonObject { [key: string]: JsonValue; }

export type Opaque<T, Brand extends string> = T & { readonly __brand: Brand };
export type Binding<T> = string & { readonly _bindingType?: T };
export type Expr<T> = T | Binding<T>;
export type StyleValue = string & {};
export type StatePath = string & {};
export type DesignToken = string & { readonly __designToken: true };
export type SlotName = string & {};
export type ActionName = string & {};

export type DeepReadonly<T> =
  T extends (...args: any[]) => any ? T :
  T extends readonly any[] ? Readonly<{ [K in keyof T]: DeepReadonly<T[K]> }> :
  T extends object ? { readonly [K in keyof T]: DeepReadonly<T[K]> } :
  T;

export type Simplify<T> = { [K in keyof T]: T[K] } & {};

/* ============================================================
 * 2) RUNTIME FIELD TYPES, FLAGS, AND SCHEMA BLUEPRINTS
 * ============================================================ */

export const QL_PRIMITIVE_FIELD_TYPES = {
  string: 1,
  number: 2,
  boolean: 3,
  date: 4,
  json: 5,
  object: 6,
  relation: 7,
  relationship: 8,
  block: 9,
  enumeration: 10,
  array: 11,
  tree: 12,
  secure: 13,
  lookup: 14,
  textarea: 15,
  media: 16,
  bigInt: 17,
  smallInt: 18,
  decimal: 19,
  char: 20,
  flags: 21,
} as const;

export type QLPrimitiveFieldTypeCode = typeof QL_PRIMITIVE_FIELD_TYPES[keyof typeof QL_PRIMITIVE_FIELD_TYPES];

export const QL_FLAG_BITS = {
  none: 0,
  isVirtual: 1 << 0,
  isComputed: 1 << 1,
  isRequired: 1 << 2,
  hasMany: 1 << 3,
  isUnique: 1 << 4,
  isIndexed: 1 << 5,
  isHidden: 1 << 6,
  isReadOnly: 1 << 7,
} as const;

export type QLFieldFlagBit = typeof QL_FLAG_BITS[keyof typeof QL_FLAG_BITS];

export type QLFieldTypeLabel =
  | 'string' | 'text' | 'textarea' | 'number' | 'float' | 'int' | 'int32' | 'double'
  | 'bigint' | 'biginteger' | 'int64' | 'long' | 'smallint' | 'short' | 'int16'
  | 'decimal' | 'numeric' | 'money' | 'currency' | 'char' | 'character'
  | 'flags' | 'bitflags' | 'bitmask' | 'mask' | 'media' | 'asset' | 'file'
  | 'bool' | 'boolean' | 'date' | 'json' | 'object' | 'group' | 'map'
  | 'relation' | 'relationship' | 'block' | 'enum' | 'enumeration'
  | 'array' | 'list' | 'tree' | 'secure' | 'password' | 'lookup';

export interface QLBlockPayload {
  blockType: string;
  data: JsonObject;
}

export interface QLMediaPolicy {
  [key: string]: JsonValue | undefined;
}

export interface QLQualityPolicy {
  [key: string]: JsonValue | undefined;
}

export interface QLStreamingPolicy {
  [key: string]: JsonValue | undefined;
}

export interface QLCachePolicy {
  [key: string]: JsonValue | undefined;
}

export interface QLSchemaFieldSpec {
  name: string;
  path: string;
  type: QLPrimitiveFieldTypeCode | QLFieldTypeLabel;
  flags: number;
  relationTarget?: string | null;
  options?: string[];
  min?: number | null;
  max?: number | null;
  meta?: Record<string, JsonValue>;
  children?: QLSchemaFieldSpec[];
  itemSpec?: QLSchemaFieldSpec | null;
  allowedBlocks?: string[];
  mediaType?: string | null;
  allowedMimeTypes?: string[];
  minSizeBytes?: number | null;
  maxSizeBytes?: number | null;
  thumbnailIcon?: string | null;
  thumbnailPath?: string | null;
  mediaPolicy?: QLMediaPolicy;
  qualityPolicy?: QLQualityPolicy;
  streamingPolicy?: QLStreamingPolicy;
  cachePolicy?: QLCachePolicy;
  compute?: string | ((record: Record<string, any>) => any) | null;
  pattern?: string | null;
  matchField?: string | null;
  transform?: string | null;
  dependencies?: string[];
  errorMessages?: Record<string, string>;
  index?: number;
}

export interface QLSchemaBlueprint {
  name: string;
  rootFields: QLSchemaFieldSpec[];
  fields: QLSchemaFieldSpec[];
  byPath: Record<string, QLSchemaFieldSpec>;
  fieldCount: number;
}

/* ============================================================
 * 3) Q-SCHEMA SYSTEM (ZOD-LIKE TYPE INFERENCE)
 * ============================================================ */

export interface QSchema<T, Meta extends Record<string, unknown> = Record<string, unknown>> {
  readonly _type: T;
  readonly _tag: string;
  readonly _meta?: Meta;
}

export type Infer<S extends QSchema<any, any>> = S['_type'];

type InferUnion<T extends readonly QSchema<any, any>[]> =
  T extends readonly [infer H, ...infer Rest]
    ? H extends QSchema<any, any>
      ? Rest extends readonly QSchema<any, any>[]
        ? Infer<H> | InferUnion<Rest>
        : Infer<H>
      : never
    : never;

function qSchema<T, M extends Record<string, unknown> = Record<string, unknown>>(
  tag: string,
  meta?: M,
): QSchema<T, M> {
  return { _type: undefined as any, _tag: tag, _meta: meta } as QSchema<T, M>;
}

export const q = {
  string: (): QSchema<string> => qSchema('string'),
  number: (): QSchema<number> => qSchema('number'),
  boolean: (): QSchema<boolean> => qSchema('boolean'),
  null: (): QSchema<null> => qSchema('null'),
  any: (): QSchema<JsonValue> => qSchema('any'),
  json: (): QSchema<JsonObject> => qSchema('json'),

  literal: <T extends string | number | boolean>(value: T): QSchema<T, { value: T }> =>
    qSchema('literal', { value }),

  enum: <T extends readonly [string, ...string[]]>(...values: T): QSchema<T[number], { values: T }> =>
    qSchema('enum', { values }),

  expr: <T>(inner: QSchema<T, any>): QSchema<Expr<T>, { inner: QSchema<T, any> }> =>
    qSchema('expr', { inner }),

  binding: <T>(inner: QSchema<T, any>): QSchema<Binding<T>, { inner: QSchema<T, any> }> =>
    qSchema('binding', { inner }),

  optional: <T>(inner: QSchema<T, any>): QSchema<T | undefined, { inner: QSchema<T, any> }> =>
    qSchema('optional', { inner }),

  nullable: <T>(inner: QSchema<T, any>): QSchema<T | null, { inner: QSchema<T, any> }> =>
    qSchema('nullable', { inner }),

  object: <T extends Record<string, QSchema<any, any>>>(
    shape: T,
  ): QSchema<{ [K in keyof T]: Infer<T[K]> }, { shape: T }> =>
    qSchema('object', { shape }),

  array: <T>(item: QSchema<T, any>): QSchema<T[], { item: QSchema<T, any> }> =>
    qSchema('array', { item }),

  record: <V>(value: QSchema<V, any>): QSchema<Record<string, V>, { value: QSchema<V, any> }> =>
    qSchema('record', { value }),

  partial: <T extends Record<string, any>>(inner: QSchema<T, any>): QSchema<Partial<T>, { inner: QSchema<T, any> }> =>
    qSchema('partial', { inner }),

  union: <T extends readonly [QSchema<any, any>, ...QSchema<any, any>[]]>(...schemas: T): QSchema<InferUnion<T>, { schemas: T }> =>
    qSchema('union', { schemas }),

  merge: <A, B>(a: QSchema<A, any>, b: QSchema<B, any>): QSchema<A & B, { a: QSchema<A, any>; b: QSchema<B, any> }> =>
    qSchema('merge', { a, b }),

  extend: <T extends Record<string, any>, Extra extends Record<string, QSchema<any, any>>>(
    base: QSchema<T, any>,
    extra: Extra,
  ): QSchema<T & { [K in keyof Extra]: Infer<Extra[K]> }, { base: QSchema<T, any>; extra: Extra }> =>
    qSchema('extend', { base, extra }),

  node: (): QSchema<NodeInput> => qSchema('node'),
  action: (): QSchema<ActionSpec> => qSchema('action'),
  style: (): QSchema<StyleValue> => qSchema('style'),
  slot: (): QSchema<NodeInput> => qSchema('slot'),
  token: (): QSchema<DesignToken> => qSchema('token'),
  path: (): QSchema<StatePath> => qSchema('path'),
  jsonValue: (): QSchema<JsonValue> => qSchema('jsonValue'),
};

/* ============================================================
 * 4) APP CONFIG, ROUTER, VM & TELEMETRY SCHEMAS (APP.yaml)
 * ============================================================ */

export interface QLRouterConfig {
  initialRoute?: string;
  pagesDir?: string;
  notFound?: string;
  globalGuards?: Array<Record<string, JsonValue>>;
}

export interface QLVmConfig {
  workerThreads?: number;
  simdArenaCapacity?: number;
}

export interface QLTelemetryConfig {
  enabled?: boolean;
  frameMonitor?: boolean;
}

export interface QLYamlThemeConfig {
  colors?: Record<string, JsonValue>;
  typography?: Record<string, JsonValue>;
  spacing?: Record<string, JsonValue>;
  breakpoints?: Record<string, JsonValue>;
  shadows?: Record<string, JsonValue>;
  radii?: Record<string, JsonValue>;
  mode?: 'light' | 'dark' | 'system';
  raw?: Record<string, JsonValue>;
}

export interface QLAppYamlConfig {
  appName?: string;
  app?: {
    name?: string;
    title?: string;
    locale?: string;
    version?: string;
  };
  name?: string;
  title?: string;
  locale?: string;
  version?: string;
  theme?: QLYamlThemeConfig | Record<string, JsonValue>;
  router?: QLRouterConfig;
  vm?: QLVmConfig;
  telemetry?: QLTelemetryConfig;
  domains?: Array<Record<string, JsonValue>>;
  state?: Record<string, JsonValue>;
  macros?: Record<string, JsonValue>;
  schemas?: Record<string, JsonValue>;
  pipes?: Record<string, JsonValue>;
  actions?: Record<string, JsonValue>;
  sdui?: Record<string, JsonValue>;
  raw?: Record<string, JsonValue>;
}

export interface QLPageYamlConfig {
  type?: 'screen' | 'page' | 'component' | 'widget' | 'layout' | 'modal' | 'drawer' | 'overlay' | 'fragment' | 'template' | 'unknown';
  meta?: {
    title?: string;
    description?: string;
    keywords?: string;
    ogImage?: string;
    custom?: Record<string, JsonValue>;
  };
  route?: {
    urlPattern?: string;
    captureGroups?: string[];
    transition?: string;
    transitionMs?: number;
  };
  urlPattern?: string;
  serverProps?: Record<string, JsonValue>;
  staticProps?: Record<string, JsonValue>;
  initialProps?: Record<string, JsonValue>;
  staticPaths?: string[];
  state?: Record<string, JsonValue>;
  schemas?: Record<string, JsonValue>;
  pipelines?: Record<string, JsonValue>;
  guards?: Array<Record<string, JsonValue>>;
  macros?: Record<string, JsonValue>;
  defaultProps?: Record<string, JsonValue>;
  ui?: NodeInput;
  view?: NodeInput;
  template?: NodeInput;
  layoutSlot?: string;
  transition?: string;
  transitionDurationMs?: number;
  raw?: Record<string, JsonValue>;
}

export interface QLRouteInfo {
  path: string;
  params?: Record<string, string>;
  queryParams?: Record<string, string>;
  props?: Record<string, JsonValue>;
  extra?: Record<string, JsonValue>;
  state?: Record<string, JsonValue>;
}

export interface QLRoute {
  path: string;
  builder?: string | ((context: any, info: QLRouteInfo) => any);
  layoutBuilder?: string | ((context: any, info: QLRouteInfo, child: any) => any);
  children?: QLRoute[];
  middlewares?: Array<Record<string, JsonValue>>;
  transition?: 'fade' | 'scale' | 'slideRight' | 'slideLeft' | 'slideUp' | 'slideDown' | 'flip3D' | 'none';
  transitionDuration?: number;
  getServerSideProps?: string | ((info: QLRouteInfo) => Record<string, JsonValue>);
  getStaticProps?: string | ((info: QLRouteInfo) => Record<string, JsonValue>);
  getInitialProps?: string | ((info: QLRouteInfo) => Record<string, JsonValue>);
  getStaticPaths?: string | (() => string[]);
  seo?: string | ((info: QLRouteInfo, props: Record<string, JsonValue>) => QuantumPageSeo);
  getSchema?: string | ((info: QLRouteInfo) => Record<string, JsonValue>);
  loadingBuilder?: string | ((context: any) => any);
}

/* ============================================================
 * 5) DESIGN SYSTEM BUNDLE MANIFEST
 * ============================================================ */

export interface QuantumDesignSystemBundle {
  id?: string;
  fingerprint?: number;
  manifest?: Record<string, JsonValue>;
  aliases?: Record<string, JsonValue>;
  slotTypes?: Record<string, JsonValue>;
  slotNodes?: Record<string, JsonValue>;
  templates?: Record<string, JsonValue>;
  layouts?: Record<string, JsonValue>;
  decorations?: Record<string, JsonValue>;
  coreSchemas?: Record<string, JsonValue>;
  aliasSchemas?: Record<string, JsonValue>;
  components?: Record<string, JsonValue>;
  actions?: Record<string, JsonValue>;
  behaviors?: Record<string, JsonValue>;
  workflows?: Record<string, JsonValue>;
  stateMachines?: Record<string, JsonValue>;
  routes?: Record<string, JsonValue>;
  packs?: Record<string, JsonValue>;
  accessibility?: Record<string, JsonValue>;
  typography?: Record<string, JsonValue>;
  motion?: Record<string, JsonValue>;
  performance?: Record<string, JsonValue>;
  platform?: Record<string, JsonValue>;
  dataPolicy?: Record<string, JsonValue>;
  tokens?: Record<string, JsonValue>;
  metadata?: Record<string, JsonValue>;
}

/* ============================================================
 * 6) CATALOG / ROOTS / SUBTYPES
 * ============================================================ */

export const QUANTUM_CATALOG = {
  box: [
    'aspect','builder','col','expanded','flexible','grid','layer',
    'masonry','matrix','measure','morph','responsive','row','safe',
    'scroll','shell','split','stack','sticky','surface','viewport',
    'virtual_grid','wrap',
  ] as const,

  action: [
    'button','chip','double_tap','focus','gesture','hover',
    'icon_button','link','long_press','pointer','press',
    'raw_pointer','tap','viewport',
  ] as const,

  field: [
    'cell','checkbox','email','multiline','number','password',
    'radio','rich_text','search','slider','tel','text',
    'textarea','toggle','url',
  ] as const,

  text: ['h1','h2','h3','label','code','rich'] as const,

  media: [
    'audio','audio_visualizer','avatar','camera','canvas_video',
    'icon','path','stream','svg_path','video','webrtc',
  ] as const,

  data: [
    'aggregate','cursor','diff','grid','infinite','kanban',
    'masonry','paginated','realtime','repeat','slice','sliver',
    'sliver_plane','stream','table','timeline','virtual_scroll',
  ] as const,

  portal: [
    'action_sheet','alert','anchored_floating','centered','confirm',
    'context_menu','context_panel','dialog','docked','drawer',
    'dropdown','edge_attached','expandable_inline','flyout',
    'form_modal','full_page_sheet','full_screen','full_screen_surface',
    'immersive_editor','inline_details','inline_editor','inspector',
    'lightbox','left_panel','menu','mobile_sheet','modal',
    'navigation_rail','nonModal','non_modal','overlay','overlay_entry',
    'persistent_drawer','persistent_panel','popover','popup_modal',
    'right_panel','sheet','sidebar','side_sheet','toast',
    'temporary_overlay','tooltip','utility_panel','window',
  ] as const,

  hook: [
    'atom','bridge','change','delegate','effect','error_boundary',
    'guard','interval','lifecycle','memo','mount','observable',
    'ref','scope','slice','store',
  ] as const,

  control: [
    'accordion','architecture','flow','form_scope','machine',
    'optimistic','reducer','saga','stepper','tabs','tca',
  ] as const,

  system: [
    'async','clipboard','data_pipe','debounce','download','geo',
    'haptic','kinetic_pipe','macro','notification','omega_macro',
    'repeater','sensor','share','store_provider','sync_scroll',
    'throttle','ticker','timer','upload','worker',
  ] as const,

  canvas: ['draw','plot','shader','shape'] as const,

  decoration: [
    'badge','blur','border','gradient','rich','ripple',
    'shadow','skeleton','span','text',
  ] as const,

  chart: [
    'line','bar','area','pie','donut','radar','scatter','bubble',
    'candlestick','funnel','waterfall','histogram','gauge',
    'sparkline','treemap','sankey',
  ] as const,

  component: ['define','use','instance','render','scoped','link'] as const,

  visual: [
    'action','animation','box','canvas','chart','compose',
    'connect','control','data','decoration','delegate','field',
    'layer','layout','media','overlay','portal','scene','shell',
    'stack','surface','system','template','text',
  ] as const,

  stream: ['ws','sse','tick','ring','multiplex'] as const,
  collab: ['presence','cursor','awareness','lock','patch'] as const,

  template: [] as const,
  layout: [] as const,
  connect: [] as const,
  animation: [] as const,
} as const;

export type CatalogRoot = keyof typeof QUANTUM_CATALOG;
export type CatalogSubtype<R extends CatalogRoot> = typeof QUANTUM_CATALOG[R][number];

export type BoxSubtype = CatalogSubtype<'box'>;
export type ActionSubtype = CatalogSubtype<'action'>;
export type FieldSubtype = CatalogSubtype<'field'>;
export type TextSubtype = CatalogSubtype<'text'>;
export type MediaSubtype = CatalogSubtype<'media'>;
export type DataSubtype = CatalogSubtype<'data'>;
export type PortalSubtype = CatalogSubtype<'portal'>;
export type HookSubtype = CatalogSubtype<'hook'>;
export type ControlSubtype = CatalogSubtype<'control'>;
export type SystemSubtype = CatalogSubtype<'system'>;
export type CanvasSubtype = CatalogSubtype<'canvas'>;
export type DecorationSubtype = CatalogSubtype<'decoration'>;
export type ChartSubtype = CatalogSubtype<'chart'>;
export type ComponentSubtype = CatalogSubtype<'component'>;
export type VisualSubtype = CatalogSubtype<'visual'>;
export type StreamSubtype = CatalogSubtype<'stream'>;
export type CollabSubtype = CatalogSubtype<'collab'>;

export type QuantumNodeType = string & {};

/* ============================================================
 * 7) ACTION / EVENT SPECS
 * ============================================================ */

export interface ActionSpec {
  action?: ActionName;
  params?: JsonObject;
  payload?: JsonObject;
  args?: JsonObject;
  target?: string;
  domain?: string;
  resource?: string;
  slug?: string;
  then?: ActionSpec | ActionSpec[];
  catch?: ActionSpec;
  optimistic?: JsonObject;
  debounce?: number;
  throttle?: number;
  [key: string]: JsonValue | ActionSpec | ActionSpec[] | undefined;
}

export interface NavActionSpec {
  action: 'navigate' | 'push' | 'pop' | 'replace' | 'popToRoot';
  route?: string;
  params?: JsonObject;
  animated?: boolean;
}

export interface MutationActionSpec {
  action: ActionName;
  namespace?: string;
  mutation?: string;
  payload?: JsonObject;
  optimistic?: JsonObject;
}

export type AnyAction = ActionSpec | NavActionSpec | MutationActionSpec | string;

export interface EventHandlers {
  onTap?: AnyAction;
  onPress?: AnyAction;
  onLongPress?: AnyAction;
  onDoubleTap?: AnyAction;
  onChange?: AnyAction;
  onSubmit?: AnyAction;
  onFocus?: AnyAction;
  onBlur?: AnyAction;
  onHover?: AnyAction;
  onHoverExit?: AnyAction;
  onScroll?: AnyAction;
  onSwipe?: AnyAction;
  onDragStart?: AnyAction;
  onDragEnd?: AnyAction;
  onDrop?: AnyAction;
  onMount?: AnyAction;
  onUnmount?: AnyAction;
  onVisible?: AnyAction;
  onInvisible?: AnyAction;
  [key: string]: unknown;
}

/* ============================================================
 * 8) PROPS INTERFACES
 * ============================================================ */

export interface BaseProps extends EventHandlers {
  id?: string;
  key?: string;
  testId?: string;
  accessible?: boolean;
  semanticLabel?: Expr<string>;
  tooltip?: Expr<string> | boolean | JsonObject;
  enabled?: Expr<boolean>;
  visible?: Expr<boolean>;
  opacity?: Expr<number>;
  elevation?: number;
  zIndex?: number;
  cursor?: 'pointer' | 'default' | 'text' | 'grab' | 'not-allowed' | string;
  behaviors?: JsonValue[];
  [key: string]: unknown;
}

export interface BoxProps extends BaseProps {
  direction?: 'row' | 'col' | 'row-reverse' | 'col-reverse';
  alignment?: Expr<string>;
  crossAlignment?: Expr<string>;
  mainAlignment?: Expr<string>;
  gap?: Expr<number> | DesignToken;
  gapX?: Expr<number> | DesignToken;
  gapY?: Expr<number> | DesignToken;
  padding?: Expr<number> | DesignToken;
  paddingX?: Expr<number> | DesignToken;
  paddingY?: Expr<number> | DesignToken;
  paddingTop?: Expr<number> | DesignToken;
  paddingBottom?: Expr<number> | DesignToken;
  paddingLeft?: Expr<number> | DesignToken;
  paddingRight?: Expr<number> | DesignToken;
  margin?: Expr<number> | DesignToken;
  marginX?: Expr<number> | DesignToken;
  marginY?: Expr<number> | DesignToken;
  width?: Expr<number | string> | DesignToken;
  height?: Expr<number | string> | DesignToken;
  minWidth?: Expr<number | string> | DesignToken;
  maxWidth?: Expr<number | string> | DesignToken;
  minHeight?: Expr<number | string> | DesignToken;
  maxHeight?: Expr<number | string> | DesignToken;
  flex?: number;
  flexGrow?: number;
  flexShrink?: number;
  flexBasis?: number | string;
  wrap?: boolean | 'wrap' | 'nowrap' | 'wrap-reverse';
  overflow?: 'visible' | 'hidden' | 'scroll' | 'auto' | 'clip';
  overflowX?: 'visible' | 'hidden' | 'scroll' | 'auto' | 'clip';
  overflowY?: 'visible' | 'hidden' | 'scroll' | 'auto' | 'clip';
  clip?: boolean;
  radius?: Expr<number | string> | DesignToken;
  radiusTopLeft?: Expr<number | string> | DesignToken;
  radiusTopRight?: Expr<number | string> | DesignToken;
  radiusBottomLeft?: Expr<number | string> | DesignToken;
  radiusBottomRight?: Expr<number | string> | DesignToken;
  bg?: Expr<string> | DesignToken;
  background?: Expr<string> | DesignToken;
  border?: Expr<string> | DesignToken;
  borderWidth?: Expr<number> | DesignToken;
  borderColor?: Expr<string> | DesignToken;
  borderStyle?: 'solid' | 'dashed' | 'dotted' | 'none';
  shadow?: Expr<string> | DesignToken;
  blur?: Expr<number>;
  scrollable?: boolean;
  scrollDirection?: 'vertical' | 'horizontal' | 'both';
  reverse?: boolean;
  shrinkWrap?: boolean;
  physics?: 'bounce' | 'clamp' | 'never' | 'always' | string;
  columns?: Expr<number>;
  rows?: Expr<number>;
  columnSpan?: Expr<number>;
  rowSpan?: Expr<number>;
  columnGap?: Expr<number> | DesignToken;
  rowGap?: Expr<number> | DesignToken;
  autoColumns?: string;
  autoRows?: string;
  aspectRatio?: Expr<number>;
  breakpoints?: Record<string, Partial<BoxProps>>;
  top?: Expr<number | string> | DesignToken;
  bottom?: Expr<number | string> | DesignToken;
  left?: Expr<number | string> | DesignToken;
  right?: Expr<number | string> | DesignToken;
  position?: 'relative' | 'absolute' | 'fixed' | 'sticky' | 'static';
  safeArea?: boolean | 'top' | 'bottom' | 'left' | 'right' | 'all';
  __subType?: BoxSubtype | string;
}

export interface TextProps extends BaseProps {
  text: Expr<string>;
  variant?: 'display' | 'heading' | 'subheading' | 'body' | 'caption' | 'label' | 'code' | TextSubtype | string;
  color?: Expr<string> | DesignToken;
  fontSize?: Expr<number> | DesignToken;
  fontWeight?: Expr<number | string> | DesignToken;
  fontFamily?: Expr<string> | DesignToken;
  lineHeight?: Expr<number> | DesignToken;
  letterSpacing?: Expr<number> | DesignToken;
  textAlign?: 'left' | 'center' | 'right' | 'justify' | 'start' | 'end';
  textDecoration?: 'none' | 'underline' | 'line-through' | 'overline';
  textTransform?: 'none' | 'uppercase' | 'lowercase' | 'capitalize';
  maxLines?: number;
  overflow?: 'clip' | 'ellipsis' | 'fade' | 'visible';
  softWrap?: boolean;
  selectable?: boolean;
  italic?: boolean;
  bold?: boolean;
  __subType?: TextSubtype | string;
}

export interface ActionProps extends BaseProps {
  text?: Expr<string>;
  label?: Expr<string>;
  icon?: Expr<string>;
  iconPosition?: 'left' | 'right' | 'top' | 'bottom';
  iconSize?: Expr<number> | DesignToken;
  intent?: 'primary' | 'secondary' | 'danger' | 'success' | 'warning' | 'ghost' | 'link' | string;
  variant?: 'solid' | 'outline' | 'ghost' | 'link' | 'soft' | string;
  fill?: 'solid' | 'outline' | 'ghost' | 'soft';
  shape?: 'square' | 'rounded' | 'pill' | 'circle';
  size?: 'xs' | 'sm' | 'md' | 'lg' | 'xl' | string | DesignToken;
  loading?: Expr<boolean>;
  disabled?: Expr<boolean>;
  href?: Expr<string>;
  target?: '_blank' | '_self' | '_parent' | '_top' | string;
  type?: 'button' | 'submit' | 'reset';
  color?: Expr<string> | DesignToken;
  bg?: Expr<string> | DesignToken;
  padding?: Expr<number | string> | DesignToken;
  radius?: Expr<number | string> | DesignToken;
  __subType?: ActionSubtype | string;
}

export interface FieldProps extends BaseProps {
  label?: Expr<string>;
  placeholder?: Expr<string>;
  hint?: Expr<string>;
  helperText?: Expr<string>;
  errorText?: Expr<string>;
  value?: Expr<JsonPrimitive>;
  defaultValue?: JsonPrimitive;
  name?: string;
  required?: boolean;
  disabled?: Expr<boolean>;
  readOnly?: Expr<boolean>;
  autoFocus?: boolean;
  autoComplete?: string;
  clearable?: boolean;
  prefix?: Expr<string>;
  suffix?: Expr<string>;
  prefixIcon?: Expr<string>;
  suffixIcon?: Expr<string>;
  variant?: 'outline' | 'filled' | 'underline' | 'ghost' | string;
  size?: 'sm' | 'md' | 'lg' | string | DesignToken;
  color?: Expr<string> | DesignToken;
  radius?: Expr<number | string> | DesignToken;
  __subType?: FieldSubtype | string;
}

export interface MediaProps extends BaseProps {
  src?: Expr<string>;
  alt?: Expr<string>;
  fit?: 'contain' | 'cover' | 'fill' | 'none' | 'scale-down';
  width?: Expr<number | string> | DesignToken;
  height?: Expr<number | string> | DesignToken;
  radius?: Expr<number | string> | DesignToken;
  placeholder?: NodeInput;
  fallback?: Expr<string>;
  lazy?: boolean;
  blurHash?: string;
  loop?: boolean;
  autoPlay?: boolean;
  muted?: boolean;
  controls?: boolean;
  preload?: 'none' | 'metadata' | 'auto';
  volume?: Expr<number>;
  icon?: Expr<string>;
  iconFamily?: 'material' | 'cupertino' | 'feather' | string;
  iconSize?: Expr<number> | DesignToken;
  iconColor?: Expr<string> | DesignToken;
  initials?: Expr<string>;
  size?: Expr<number | string> | DesignToken;
  __subType?: MediaSubtype | string;
}

export interface DataProps extends BaseProps {
  __subType?: DataSubtype | string;
  bind?: Expr<any[]> | StatePath;
  as?: string;
  indexAs?: string;
  keyField?: string;
  pageSize?: number;
  initialPage?: number;
  bufferSize?: number;
  schema?: string;
  source?: string;
  namespace?: string;
  searchBind?: StatePath;
  filterBind?: StatePath;
  sortBind?: StatePath;
  emptySlot?: NodeInput;
  loadingSlot?: NodeInput;
  errorSlot?: NodeInput;
  columnBind?: Expr<any[]>;
  columnKey?: string;
  columns?: JsonObject[];
  selectable?: boolean;
  aggregates?: JsonObject[];
  direction?: 'forward' | 'reverse';
  threshold?: number;
}

export interface PortalProps extends BaseProps {
  __subType?: PortalSubtype | string;
  portalType?: PortalSubtype | string;
  title?: Expr<string>;
  subtitle?: Expr<string>;
  visible?: Expr<boolean>;
  dismissible?: boolean;
  barrierColor?: Expr<string> | DesignToken;
  barrierDismissible?: boolean;
  elevation?: number;
  width?: Expr<number | string> | DesignToken;
  height?: Expr<number | string> | DesignToken;
  maxWidth?: Expr<number | string> | DesignToken;
  maxHeight?: Expr<number | string> | DesignToken;
  anchor?: 'top' | 'bottom' | 'left' | 'right' | 'center' | string;
  offset?: { x?: number; y?: number };
  animation?: 'fade' | 'slide' | 'scale' | 'bounce' | string;
  duration?: number;
  onDismiss?: AnyAction;
  onConfirm?: AnyAction;
  confirmText?: Expr<string>;
  cancelText?: Expr<string>;
  position?: 'top' | 'bottom' | 'center' | 'topLeft' | 'topRight' | 'bottomLeft' | 'bottomRight';
  autoDismiss?: number;
  drawerSide?: 'left' | 'right' | 'top' | 'bottom';
}

export interface HookProps extends BaseProps {
  __subType?: HookSubtype | string;
  namespace?: string;
  key?: string;
  initial?: JsonValue;
  deps?: string[];
  effect?: ActionSpec;
  interval?: number;
  once?: boolean;
  lazy?: boolean;
  persist?: boolean;
  atomKey?: string;
  atomValue?: JsonValue;
  condition?: Expr<boolean>;
  fallback?: NodeInput;
  redirect?: string;
  bridge?: string;
  channel?: string;
}

export interface ControlProps extends BaseProps {
  __subType?: ControlSubtype | string;
  tabs?: Array<{ label: string; value: string; icon?: string }>;
  activeTab?: Expr<string>;
  tabVariant?: 'line' | 'pills' | 'boxed' | string;
  steps?: Array<{ label: string; description?: string }>;
  activeStep?: Expr<number>;
  orientation?: 'horizontal' | 'vertical';
  expanded?: Expr<boolean | string[]>;
  multiple?: boolean;
  formId?: string;
  id?: string;
  initial?: string;
  states?: JsonObject;
  context?: JsonObject;
  current?: Expr<string>;
  optimisticKey?: string;
  reducer?: JsonObject;
}

export interface SystemProps extends BaseProps {
  __subType?: SystemSubtype | string;
  action?: ActionName;
  params?: JsonObject;
  loading?: NodeInput;
  data?: NodeInput;
  error?: NodeInput;
  autoStart?: boolean;
  interval?: number;
  duration?: number;
  repeat?: boolean;
  delay?: number;
  script?: string;
  entrypoint?: string;
  ms?: number;
  accept?: string;
  maxSize?: number;
  multiple?: boolean;
  url?: string;
  accuracy?: 'low' | 'medium' | 'high' | 'best';
  hapticType?: 'light' | 'medium' | 'heavy' | 'selection' | 'success' | 'warning' | 'error';
  notificationId?: string;
  notificationTitle?: Expr<string>;
  notificationBody?: Expr<string>;
  clipboardText?: Expr<string>;
  shareText?: Expr<string>;
  shareTitle?: Expr<string>;
  shareUrl?: Expr<string>;
  namespace?: string;
  pipeId?: string;
  pipeSource?: string;
}

export interface CanvasProps extends BaseProps {
  __subType?: CanvasSubtype | string;
  width?: Expr<number | string> | DesignToken;
  height?: Expr<number | string> | DesignToken;
  shader?: string;
  shaderUniforms?: JsonObject;
  antiAlias?: boolean;
  color?: Expr<string> | DesignToken;
  fill?: Expr<string> | DesignToken;
  stroke?: Expr<string> | DesignToken;
  strokeWidth?: Expr<number>;
  shape?: 'rect' | 'circle' | 'ellipse' | 'line' | 'path' | 'polygon' | string;
  points?: Array<{ x: number; y: number }>;
  d?: string;
  data?: Expr<any[]>;
  x?: string;
  y?: string;
}

export interface DecorationProps extends BaseProps {
  __subType?: DecorationSubtype | string;
  count?: Expr<number>;
  dot?: boolean;
  badgeColor?: Expr<string> | DesignToken;
  gradient?: JsonObject;
  gradientType?: 'linear' | 'radial' | 'sweep';
  colors?: Expr<string[]>;
  stops?: number[];
  angle?: number;
  shadow?: JsonObject | string;
  offsetX?: number;
  offsetY?: number;
  blur?: number;
  spread?: number;
  color?: Expr<string> | DesignToken;
  blurRadius?: number;
  sigmaX?: number;
  sigmaY?: number;
  borderWidth?: Expr<number>;
  borderColor?: Expr<string> | DesignToken;
  borderStyle?: 'solid' | 'dashed' | 'dotted';
  radius?: Expr<number | string> | DesignToken;
  loading?: Expr<boolean>;
  skeletonColor?: Expr<string> | DesignToken;
  rippleColor?: Expr<string> | DesignToken;
  text?: Expr<string>;
  spans?: JsonObject[];
}

export interface ChartProps extends BaseProps {
  __subType?: ChartSubtype | string;
  chartType?: ChartSubtype | string;
  data?: Expr<any[]>;
  series?: JsonObject[];
  xField?: string;
  yField?: string;
  colorField?: string;
  categoryField?: string;
  colors?: string[];
  legend?: boolean | JsonObject;
  tooltip?: boolean | JsonObject;
  grid?: boolean | JsonObject;
  axis?: JsonObject;
  xAxis?: JsonObject;
  yAxis?: JsonObject;
  smooth?: boolean;
  stacked?: boolean;
  filled?: boolean;
  animated?: boolean;
  responsive?: boolean;
  width?: Expr<number | string> | DesignToken;
  height?: Expr<number | string> | DesignToken;
  padding?: Expr<number | string> | DesignToken;
  min?: number;
  max?: number;
  value?: Expr<number>;
  innerRadius?: number;
  outerRadius?: number;
  startAngle?: number;
  endAngle?: number;
  valueField?: string;
  nameField?: string;
  parentField?: string;
}

export interface StreamNodeProps extends BaseProps {
  __subType?: StreamSubtype | string;
  url?: Expr<string>;
  channel?: Expr<string>;
  topic?: Expr<string>;
  as?: string;
  autoConnect?: boolean;
  reconnect?: boolean;
  reconnectDelay?: number;
  headers?: JsonObject;
  bufferSize?: number;
  capacity?: number;
}

export interface CollabProps extends BaseProps {
  __subType?: CollabSubtype | string;
  roomId?: Expr<string>;
  userId?: Expr<string>;
  docId?: Expr<string>;
  field?: string;
  color?: Expr<string> | DesignToken;
}

/* ============================================================
 * 9) COMPONENT & MACRO TYPES
 * ============================================================ */

export interface ComponentComputedSpec {
  deps?: string[];
  op?: 'constant' | 'copy' | 'concat' | 'sum' | 'product' | 'min' | 'max' | 'and' | 'or' | 'not' | 'eq' | 'neq' | 'gt' | 'gte' | 'lt' | 'lte' | 'first' | 'last' | 'list' | 'pick' | 'coalesce';
  args?: any[];
  fallback?: any;
  immediate?: boolean;
}

export interface ComponentEffectSpec {
  deps?: string[];
  actions?: AnyAction | AnyAction[];
  debounceMs?: number;
  immediate?: boolean;
}

export interface ComponentHookBundle {
  mount?: AnyAction | AnyAction[];
  unmount?: AnyAction | AnyAction[];
  effect?: ComponentEffectSpec | ComponentEffectSpec[];
  bridge?: AnyAction | AnyAction[];
  guard?: AnyAction | AnyAction[];
  memo?: AnyAction | AnyAction[];
  scope?: Record<string, any>;
  controller?: AnyAction | AnyAction[];
}

export interface ComponentProps extends BaseProps {
  __subType?: 'define' | 'use' | 'instance' | 'render' | 'scoped' | 'link' | string;
  name?: string;
  component?: string;
  description?: string;
  props?: Record<string, any>;
  state?: Record<string, any>;
  computed?: Record<string, ComponentComputedSpec>;
  hooks?: ComponentHookBundle;
  links?: Record<string, any>;
  variants?: Record<string, any>;
  animations?: Record<string, any>;
  runtime?: Record<string, any>;
  policy?: Record<string, any>;
  capabilities?: string[];
  slots?: Record<string, NodeInput>;
  ui?: NodeInput;
  variant?: string;
}

export interface MacroProps extends BaseProps {
  __subType?: string;
  name?: string;
  pattern?: JsonValue;
  when?: JsonValue;
  replace?: JsonValue;
  args?: string[];
  slots?: string[] | Record<string, NodeInput>;
  description?: string;
  defaultProps?: Record<string, any>;
  defaultSlots?: Record<string, NodeInput>;
  $view?: NodeInput;
  view?: NodeInput;
  template?: NodeInput;
}

export interface VisualProps extends BaseProps {
  __subType?: VisualSubtype | string;
  animationType?: string;
  boxType?: BoxSubtype | string;
  chartType?: ChartSubtype | string;
  canvasType?: CanvasSubtype | string;
  fieldType?: FieldSubtype | string;
  mediaType?: MediaSubtype | string;
  portalType?: PortalSubtype | string;
  systemType?: SystemSubtype | string;
  connectType?: string;
  delegateProps?: JsonObject;
  isComplex?: boolean;
  willChange?: string;
  body?: NodeInput;
  header?: NodeInput;
  footer?: NodeInput;
  content?: NodeInput;
  overlay?: NodeInput;
  target?: NodeInput;
  chrome?: NodeInput;
  child?: NodeInput;
  layout?: string[];
}

export type KnownPropsMap = {
  box: BoxProps;
  action: ActionProps;
  field: FieldProps;
  text: TextProps;
  media: MediaProps;
  data: DataProps;
  portal: PortalProps;
  hook: HookProps;
  control: ControlProps;
  system: SystemProps;
  canvas: CanvasProps;
  decoration: DecorationProps;
  chart: ChartProps;
  stream: StreamNodeProps;
  collab: CollabProps;
  component: ComponentProps;
  visual: VisualProps;
};

export type PropsFor<R extends string> = R extends keyof KnownPropsMap ? KnownPropsMap[R] : BaseProps;

/* ============================================================
 * 10) VM OPERATORS
 * ============================================================ */

export interface IfOperator { $if?: Expr<boolean> | string; }
export interface RepeatOperator { $repeat?: Expr<any[]> | string; as?: string; indexAs?: string; }
export interface SwitchOperator { $switch?: Expr<any> | string; cases?: Record<string, NodeInput>; default?: NodeInput; }
export interface DefineOperator { $define?: Record<string, JsonValue>; }
export interface LetOperator { $let?: Record<string, JsonValue>; }
export interface ClassesOperator { $classes?: Record<string, Expr<boolean>>; }
export interface ScopeOperator { $scope?: Expr<string>; }
export interface CallOperator { $call?: string; }
export interface ApplyOperator { $apply?: { props?: JsonObject; style?: StyleValue; mode?: 'merge' | 'override' }; }
export interface LayoutOperator { $layout?: string[]; }
export interface TryCatchOperator { $try?: NodeInput; $catch?: NodeInput; $finally?: NodeInput; }
export interface AsyncOperator { $async?: AsyncSpec | JsonValue; $loading?: NodeInput; $data?: NodeInput; $error?: NodeInput; }
export interface StreamOperator { $stream?: StreamBindSpec | Expr<any>; }
export interface MachineOperator { $machine?: MachineSpec | JsonObject; }
export interface TimingOperator { $throttle?: number; $debounce?: number; }
export interface PortalOperator { $portal?: string; }
export interface ReactiveMapOperator { $reactive_map?: ReactiveMapSpec | Expr<any>; }
export interface ComposeOperator { $compose?: JsonValue[]; }
export interface WatchOperator { $watch?: Expr<any> | StatePath; }
export interface ParallelOperator { $parallel?: NodeInput[]; }
export interface SpreadOperator { $spread?: Expr<JsonObject> | StatePath; }
export interface ViewOperator { $view?: Expr<any> | StatePath; }
export interface SlotOperator { $slot?: string; $slots?: Record<string, NodeInput>; }
export interface StateOperator { $state?: StatePath; }
export interface EnvOperator { $env?: string; }
export interface RouteOperator { $route?: string; }
export interface LocalOperator { $local?: string; }

export type AllVmOperators =
  IfOperator & RepeatOperator & SwitchOperator &
  DefineOperator & LetOperator & ClassesOperator & ScopeOperator & CallOperator &
  ApplyOperator & LayoutOperator & TryCatchOperator & AsyncOperator &
  StreamOperator & MachineOperator & TimingOperator & PortalOperator &
  ReactiveMapOperator & ComposeOperator & WatchOperator & ParallelOperator &
  SpreadOperator & ViewOperator & SlotOperator &
  StateOperator & EnvOperator & RouteOperator & LocalOperator;

export interface AsyncSpec {
  action: ActionName;
  params?: JsonObject;
  loading?: NodeInput;
  data?: NodeInput;
  error?: NodeInput;
  autoStart?: boolean;
  debounce?: number;
  throttle?: number;
}

export interface StreamBindSpec {
  bind: Expr<any> | StatePath;
  as?: string;
}

export interface ReactiveMapSpec {
  bind: Expr<any> | StatePath;
  key?: string | Expr<string>;
  as?: string | Expr<string>;
}

export interface MachineSpec {
  id: string;
  initial: string;
  states: Record<string, MachineState>;
  context?: JsonObject;
}

export interface MachineState {
  on?: Record<string, string | JsonObject>;
  entry?: AnyAction | AnyAction[];
  exit?: AnyAction | AnyAction[];
  type?: 'atomic' | 'compound' | 'parallel' | 'final' | 'history';
  initial?: string;
  states?: Record<string, MachineState>;
}

export interface SduiNode extends AllVmOperators {
  type: QuantumNodeType;
  props?: JsonObject;
  style?: StyleValue;
  children?: NodeInput[];
  slots?: Record<string, NodeInput>;
  name?: string;
  slot?: string;
  env?: Record<string, JsonValue>;
  debugPath?: string;
  cases?: Record<string, NodeInput>;
  default?: NodeInput;
  as?: string;
  indexAs?: string;
  [key: string]: unknown;
}

export type NodeInput = SduiNode | SduiElement<any> | JsonPrimitive | NodeInput[];

/* ============================================================
 * 11) INTERNAL HELPERS
 * ============================================================ */

export interface ValidationIssue { path: string; message: string; }
export interface ValidationResult { ok: boolean; issues: ValidationIssue[]; }

export interface EmitOptions {
  pretty?: boolean;
  indent?: number;
  includeDebugPath?: boolean;
  canonicalizeSlots?: boolean;
  preserveNameAndSlot?: boolean;
}

function _isArray(value: any): value is any[] {
  return Object.prototype.toString.call(value) === '[object Array]';
}

function _hasOwn(obj: any, key: string): boolean {
  return Object.prototype.hasOwnProperty.call(obj, key);
}

function _isPlainObject(value: any): value is Record<string, any> {
  return (
    typeof value === 'object' &&
    value !== null &&
    !_isArray(value) &&
    !(value instanceof SduiElement)
  );
}

function _objectSize(obj: Record<string, any>): number {
  let n = 0;
  for (const k in obj) if (_hasOwn(obj, k)) n++;
  return n;
}

function _clone<T>(value: T): T {
  if (value === undefined || value === null) return value;
  if (typeof value !== 'object') return value;
  if (_isArray(value)) {
    const arr: any[] = [];
    for (let i = 0; i < (value as any).length; i++) arr.push(_clone((value as any)[i]));
    return arr as any;
  }
  const out: any = {};
  for (const k in value as any) {
    if (_hasOwn(value as any, k)) out[k] = _clone((value as any)[k]);
  }
  return out;
}

function _copyInto(target: Record<string, any>, source: Record<string, any>): void {
  for (const k in source) {
    if (!_hasOwn(source, k)) continue;
    target[k] = _clone(source[k]);
  }
}

function _copyObject<T extends Record<string, any> | undefined>(
  base: T,
  extra: Record<string, any>,
): T {
  const out: any = {};
  if (base) _copyInto(out, base);
  _copyInto(out, extra);
  return out;
}

function _createNode(type: string): SduiNode {
  return { type, props: {}, children: [] };
}

function _mergeStyle(base: string | undefined, next: string): string {
  const a = base ? String(base).trim() : '';
  const b = next ? String(next).trim() : '';
  if (!a) return b;
  if (!b) return a;
  return `${a} ${b}`.trim();
}

function _mergeNode(target: any, source: any): void {
  if (!source) return;
  if (source.type !== undefined) target.type = source.type;
  if (source.props !== undefined) target.props = _clone(source.props);
  if (source.style !== undefined) target.style = source.style;
  if (source.children !== undefined) target.children = _clone(source.children);
  if (source.slots !== undefined) target.slots = _clone(source.slots);
  if (source.name !== undefined) target.name = source.name;
  if (source.slot !== undefined) target.slot = source.slot;
  if (source.env !== undefined) target.env = _clone(source.env);
  if (source.debugPath !== undefined) target.debugPath = source.debugPath;

  const skip: Record<string, true> = { type: true, props: true, style: true, children: true, slots: true, name: true, slot: true, env: true, debugPath: true };

  for (const k in source) {
    if (!_hasOwn(source, k) || skip[k] || k in target) continue;
    const v = source[k];
    if (v !== undefined) target[k] = _clone(v);
  }
}

function _buildInit(
  init: Partial<SduiNode> | undefined,
  patch: Partial<SduiNode>,
): Partial<SduiNode> {
  const out: any = {};
  if (init) _mergeNode(out, init);
  _mergeNode(out, patch);
  return out;
}

function _normalizeAny(input: any): SduiNode {
  if (input instanceof SduiElement) return input.toAuthoringNode();

  if (_isArray(input)) {
    if (input.length === 0) return { type: 'empty' };
    const head = input[0];
    const type = String(head == null ? 'empty' : head);
    const node: SduiNode = { type, props: {}, children: [] };

    for (let i = 1; i < input.length; i++) {
      const item: any = input[i];

      if (i === 1 && _isPlainObject(item)) {
        for (const k in item) {
          if (!_hasOwn(item, k)) continue;
          const v = item[k];
          if (k === '$slots' && _isPlainObject(v)) {
            node.slots = {};
            for (const sn in v) if (_hasOwn(v, sn)) (node.slots as any)[sn] = v[sn];
          } else if (k === 'props' && _isPlainObject(v)) {
            node.props = _clone(v);
          } else if (k === 'children' && _isArray(v)) {
            node.children = (v as NodeInput[]).slice();
          } else if (k === 'style') {
            node.style = v == null ? undefined : String(v);
          } else if (
            k === 'name' || k === 'slot' || k === 'as' || k === 'indexAs' ||
            k === 'cases' || k === 'default' || k === 'debugPath' || k === 'env' ||
            k.charAt(0) === '$'
          ) {
            (node as any)[k] = v;
          } else {
            node.props![k] = v;
          }
        }
        continue;
      }

      if (typeof item === 'string') {
        if (
          i === 1 &&
          (!node.props || _objectSize(node.props) === 0) &&
          (!node.children || node.children.length === 0)
        ) {
          if ((type.indexOf('text') === 0) || (type.indexOf('action') === 0)) {
            if (!node.props) node.props = {};
            node.props.text = item;
          } else {
            node.style = _mergeStyle(node.style, item);
          }
        } else {
          if (!node.children) node.children = [];
          node.children.push({ type: 'text', props: { text: item } });
        }
        continue;
      }

      if (_isArray(item)) {
        if (!node.children) node.children = [];
        for (let j = 0; j < item.length; j++) node.children.push(item[j]);
        continue;
      }

      if (_isPlainObject(item) && typeof item.type === 'string' && input.length === 2) {
        if (!node.children) node.children = [];
        node.children.push(item as NodeInput);
        continue;
      }

      if (!node.children) node.children = [];
      node.children.push(item);
    }
    return node;
  }

  if (_isPlainObject(input)) return _clone(input as SduiNode);
  if (typeof input === 'string') return { type: 'text', props: { text: input } };
  if (typeof input === 'number' || typeof input === 'boolean') return { type: 'text', props: { text: String(input) } };
  return { type: 'empty' };
}

function _emitNode(node: any, options: EmitOptions, path?: string): SduiNode {
  const input = _clone(node);
  const out: SduiNode = { type: String(input.type || 'box') };

  if (input.props && _objectSize(input.props) > 0) out.props = _clone(input.props);
  if (input.style != null && String(input.style).trim() !== '') out.style = String(input.style).trim();

  if (input.children && input.children.length > 0) {
    out.children = [];
    for (let i = 0; i < input.children.length; i++) {
      out.children.push(_emitNode(_normalizeAny(input.children[i]), options, `${path || 'root'}.children[${i}]`));
    }
  }

  if (input.slots && _objectSize(input.slots) > 0) {
    out.slots = {};
    for (const sn in input.slots) if (_hasOwn(input.slots, sn)) {
      (out.slots as any)[sn] = _emitNode(_normalizeAny(input.slots[sn]), options, `${path || 'root'}.slots.${sn}`);
    }
  }

  if (options.includeDebugPath && input.debugPath !== undefined) out.debugPath = input.debugPath;
  if (options.preserveNameAndSlot) {
    if (input.name !== undefined) out.name = input.name;
    if (input.slot !== undefined) out.slot = input.slot;
  }

  const extras = ['cases', 'default', 'as', 'indexAs', 'env'];
  for (const k of extras) {
    if ((input as any)[k] !== undefined && (out as any)[k] === undefined) (out as any)[k] = _clone((input as any)[k]);
  }

  for (const k in input) {
    if (!_hasOwn(input, k)) continue;
    if (
      k === 'type' || k === 'props' || k === 'style' || k === 'children' ||
      k === 'slots' || k === 'debugPath' || k === 'name' || k === 'slot'
    ) continue;
    if ((out as any)[k] !== undefined) continue;
    const v = (input as any)[k];
    if (v !== undefined) (out as any)[k] = _clone(v);
  }

  return out;
}

function _canonicalizeSlots(node: any): void {
  if (!node.children || node.children.length === 0) return;
  const slots: any = node.slots ? _clone(node.slots) : {};
  const nextChildren: any[] = [];

  for (const child0 of node.children) {
    const child = _normalizeAny(child0);
    if (child.slot && !slots[child.slot]) {
      slots[child.slot] = child;
      continue;
    }
    if (child.props && typeof child.props.slot === 'string' && !slots[child.props.slot]) {
      const slotName = String(child.props.slot);
      const copied = _clone(child);
      if (copied.props) delete copied.props.slot;
      slots[slotName] = copied;
      continue;
    }
    nextChildren.push(child);
  }

  node.children = nextChildren;
  if (_objectSize(slots) > 0) node.slots = slots;
}

function _validateAny(node: any, path: string, issues: ValidationIssue[]): void {
  const n = _normalizeAny(node);

  if (!n.type || typeof n.type !== 'string') issues.push({ path, message: 'Missing or invalid type.' });
  if (n.props !== undefined && !_isPlainObject(n.props)) issues.push({ path, message: 'props must be an object.' });
  if (n.style !== undefined && typeof n.style !== 'string') issues.push({ path, message: 'style must be a string.' });

  if (n.$layout !== undefined) {
    if (!_isArray(n.$layout)) {
      issues.push({ path, message: '$layout must be an array of strings.' });
    } else {
      for (const item of n.$layout) {
        if (typeof item !== 'string') {
          issues.push({ path, message: '$layout must contain only strings.' });
          break;
        }
      }
    }
  }

  if (n.children !== undefined) {
    if (!_isArray(n.children)) {
      issues.push({ path, message: 'children must be an array.' });
    } else {
      n.children.forEach((child, i) => _validateAny(child, `${path}.children[${i}]`, issues));
    }
  }

  if (n.slots !== undefined) {
    if (!_isPlainObject(n.slots)) {
      issues.push({ path, message: 'slots must be an object.' });
    } else {
      for (const sn in n.slots) if (_hasOwn(n.slots, sn)) {
        _validateAny((n.slots as any)[sn], `${path}.slots.${sn}`, issues);
      }
    }
  }

  const nodeSlotKeys = ['$loading', '$data', '$error', '$try', '$catch', '$finally'];
  for (const key of nodeSlotKeys) {
    const value = (n as any)[key];
    if (value !== undefined && value !== null && !_isNodeLike(value)) {
      issues.push({ path, message: `${key} must be a node or null.` });
    }
  }
}

function _isNodeLike(value: any): boolean {
  return (
    value instanceof SduiElement ||
    _isPlainObject(value) ||
    _isArray(value) ||
    typeof value === 'string' ||
    typeof value === 'number' ||
    typeof value === 'boolean' ||
    value === null
  );
}

/* ============================================================
 * 12) SDUI ELEMENT BUILDER
 * ============================================================ */

export class SduiElement<P extends Record<string, any> = BaseProps> {
  private _node: SduiNode;

  constructor(type: string, init?: Partial<SduiNode>) {
    this._node = _createNode(type);
    if (init) _mergeNode(this._node, init);
  }

  prop<K extends string>(key: K, value: JsonValue): this {
    if (!this._node.props) this._node.props = {};
    this._node.props[key] = value;
    return this;
  }

  props(values: Partial<P> & Record<string, JsonValue>): this {
    if (!this._node.props) this._node.props = {};
    _copyInto(this._node.props, values as Record<string, JsonValue>);
    return this;
  }

  style(value: StyleValue): this {
    this._node.style = _mergeStyle(this._node.style, value);
    return this;
  }

  child(...items: NodeInput[]): this {
    if (!this._node.children) this._node.children = [];
    for (const item of items) this._node.children.push(item);
    return this;
  }

  children(items: NodeInput[]): this {
    this._node.children = items.slice();
    return this;
  }

  slot(name: SlotName, content: NodeInput): this {
    if (!this._node.slots) this._node.slots = {};
    this._node.slots[name] = content;
    return this;
  }

  slots(values: Record<SlotName, NodeInput>): this {
    if (!this._node.slots) this._node.slots = {};
    _copyInto(this._node.slots, values as any);
    return this;
  }

  env(values: Record<string, JsonValue>): this {
    this._node.env = _copyObject(this._node.env, values);
    return this;
  }

  define(values: Record<string, JsonValue>): this {
    this._node.$define = _copyObject(this._node.$define as any, values);
    return this;
  }

  let(values: Record<string, JsonValue>): this {
    this._node.$let = _copyObject(this._node.$let as any, values);
    return this;
  }

  call(name: string): this {
    this._node.$call = name;
    return this;
  }

  classes(values: Record<string, Expr<boolean>>): this {
    this._node.$classes = _copyObject(this._node.$classes as any, values as any);
    return this;
  }

  scope(value: Expr<string> | string): this {
    this._node.$scope = value as any;
    return this;
  }

  when(value: Expr<any> | string, cases: Record<string, NodeInput>, fallback?: NodeInput): this {
    this._node.$switch = value as any;
    this._node.cases = _clone(cases) as any;
    this._node.default = fallback;
    return this;
  }

  if(condition: Expr<boolean> | string): this {
    this._node.$if = condition as any;
    return this;
  }

  repeat(bind: Expr<any[]> | StatePath | Binding<any>, asName: string, indexAsName: string): this {
    this._node.$repeat = bind as any;
    this._node.as = asName;
    this._node.indexAs = indexAsName;
    return this;
  }

  apply(opts: { props?: JsonObject; style?: StyleValue; mode?: 'merge' | 'override' }): this {
    this._node.$apply = {
      props: opts.props ? _clone(opts.props) : undefined,
      style: opts.style,
      mode: opts.mode,
    } as any;
    return this;
  }

  layout(rows: string[]): this {
    this._node.$layout = rows.slice();
    return this;
  }

  tryCatch(spec: { try: NodeInput; catch?: NodeInput; finally?: NodeInput }): this {
    this._node.$try = spec.try;
    this._node.$catch = spec.catch;
    this._node.$finally = spec.finally;
    return this;
  }

  async(spec: AsyncSpec | JsonValue): this {
    this._node.$async = spec as any;
    return this;
  }

  loading(node: NodeInput): this {
    this._node.$loading = node;
    return this;
  }

  data(node: NodeInput): this {
    this._node.$data = node;
    return this;
  }

  error(node: NodeInput): this {
    this._node.$error = node;
    return this;
  }

  portal(name: string): this {
    this._node.$portal = name;
    return this;
  }

  reactiveMap(spec: ReactiveMapSpec | JsonValue): this {
    this._node.$reactive_map = spec as any;
    return this;
  }

  compose(values: JsonValue[]): this {
    this._node.$compose = values.slice();
    return this;
  }

  watch(expr: Expr<any> | StatePath): this {
    this._node.$watch = expr as any;
    return this;
  }

  parallel(nodes: NodeInput[]): this {
    this._node.$parallel = nodes.slice() as any;
    return this;
  }

  throttle(ms: number): this {
    this._node.$throttle = ms;
    this._node.$debounce = undefined;
    return this;
  }

  debounce(ms: number): this {
    this._node.$debounce = ms;
    this._node.$throttle = undefined;
    return this;
  }

  machine(spec: MachineSpec | JsonObject): this {
    this._node.$machine = _clone(spec) as any;
    return this;
  }

  stream(spec: StreamBindSpec | JsonValue): this {
    this._node.$stream = spec as any;
    return this;
  }

  spread(value: Expr<JsonObject> | StatePath): this {
    this._node.$spread = value as any;
    return this;
  }

  view(value: Expr<any> | StatePath): this {
    this._node.$view = value as any;
    return this;
  }

  withDebugPath(path: string): this {
    this._node.debugPath = path;
    return this;
  }

  withName(name: string): this {
    this._node.name = name;
    return this;
  }

  set(key: string, value: JsonValue): this {
    (this._node as any)[key] = value;
    return this;
  }

  extend(partial: Partial<SduiNode>): this {
    _mergeNode(this._node, partial as any);
    return this;
  }

  toAuthoringNode(): SduiNode {
    return _clone(this._node);
  }

  toJSON(): SduiNode {
    return this.toNativeObject();
  }

  toNativeObject(options?: EmitOptions): SduiNode {
    return _emitNode(this._node, options || {});
  }

  toNativeJson(options?: EmitOptions): string {
    return JSON.stringify(
      this.toNativeObject(options),
      null,
      options && options.pretty ? (options.indent || 2) : 0,
    );
  }
}

/* ============================================================
 * 13) MODULES, DATA SOURCES, SLICES & POLICIES
 * ============================================================ */

export interface QLModuleAccess {
  visibility?: 'public' | 'local' | 'owner' | 'secure';
  allow?: string[];
  owner?: string;
  ownerId?: string;
}

export interface QLModuleDefinition {
  module?: string;
  id?: string;
  name?: string;
  title?: string;
  description?: string;
  version?: string;
  uses?: string[];
  imports?: string[];
  dependencies?: string[];
  access?: QLModuleAccess;
  modules?: Record<string, JsonValue>;
  schemas?: Record<string, JsonValue>;
  dataSources?: Record<string, JsonValue>;
  slices?: Record<string, JsonValue>;
  actions?: Record<string, JsonValue>;
  components?: Record<string, JsonValue>;
  templates?: Record<string, JsonValue>;
  layouts?: Record<string, JsonValue>;
  routes?: Record<string, JsonValue>;
  packs?: Record<string, JsonValue>;
  metadata?: Record<string, JsonValue>;
  tags?: string[];
  keywords?: string[];
}

export type DataSourceMergeStrategy = 'replace' | 'merge' | 'mergeMap' | 'hybrid' | 'append' | 'prepend' | 'appendById';
export interface OutboundSpec {
  domain?: string;
  action?: string;
  resource?: string;
  args?: JsonObject;
  [key: string]: JsonValue | undefined;
}

export interface DataSourceDefinition {
  name?: string;
  id?: string;
  source?: string;
  dataSource?: string;

  type?: 'rest' | 'graphql' | 'grpc' | 'websocket' | 'sse' | string;
  direction?: 'inbound' | 'outbound' | 'bidirectional' | string;
  domain?: 'api_collection' | 'media' | 'realtime' | string;
  action?: 'readMany' | 'readOne' | 'write' | 'delete' | 'subscribe' | string;
  resource?: string;
  schema?: string;
  schemaName?: string;

  select?: string[];
  fields?: string[];
  projection?: string[];
  smartSelect?: boolean;

  seed?: JsonValue;
  initial?: JsonValue;

  subscribe?: boolean;
  realtime?: boolean;
  stream?: JsonValue;
  autoStart?: boolean;
  lifecycle?: 'onMount' | 'onDemand' | string;

  localFirst?: boolean;
  offlineQueue?: boolean;

  query?: JsonObject;
  body?: JsonObject;
  params?: JsonObject;
  payload?: JsonObject;
  args?: JsonObject;

  pushDomain?: string;
  pushAction?: string;
  pushArgs?: JsonObject;
  emitAction?: string;

  outbound?: OutboundSpec;

  fetchAction?: string;
  mediaAction?: string;
  streamAction?: string;

  merge?: DataSourceMergeStrategy;
  transform?: string;

  metadata?: Record<string, JsonValue>;
  [key: string]: JsonValue | OutboundSpec | undefined;
}

export type DataSourceDocument = DataSourceDefinition;

export function defineDataSource(def: DataSourceDefinition): DataSourceDocument {
  return { ...def };
}

export interface FieldPolicySpec {
  path?: string;
  storageMode?: 'hot' | 'cold' | 'persistent';
  storage?: string;
  mode?: string;
  reactive?: boolean;
  immutable?: boolean;
  frozen?: boolean;
  readOnly?: boolean;
  readonly?: boolean;
  lazy?: boolean;
  defer?: boolean;
  streaming?: boolean;
  stream?: boolean;
  cacheResults?: boolean;
  cache?: boolean;
  pinInMemory?: boolean;
  pin?: boolean;
  sensitive?: boolean;
  secret?: boolean;
  resourceId?: string;
  id?: string;
  ref?: string;
  resolver?: string;
  metadata?: Record<string, JsonValue>;
}

export interface ResourceRefSpec {
  id?: string;
  scheme?: string;
  uri?: string;
  cacheable?: boolean;
  streaming?: boolean;
  lazy?: boolean;
  mimeType?: string;
  metadata?: Record<string, JsonValue>;
}

export interface ProtectionPolicySpec {
  level?: 'public' | 'local' | 'owner' | 'authenticated' | 'secure';
  ownerId?: string;
  allowUsers?: string[];
  allowRoles?: string[];
  denyUsers?: string[];
  denyRoles?: string[];
  requireAuth?: boolean;
  requireFreshSession?: boolean;
  redactInSnapshots?: boolean;
  metadata?: Record<string, JsonValue>;
}

export interface SliceBindingSpec {
  mode?: 'local' | 'remote' | 'hybrid' | 'stream' | 'realtime';
  from?: string;
  source?: string;
  dataSource?: string;
  bind?: string;
  sourcePath?: string;
  path?: string;
  merge?: DataSourceMergeStrategy;
  transform?: string;
  subscribe?: boolean;
  realtime?: boolean;
  default?: JsonValue;
  initial?: JsonValue;
  value?: JsonValue;
  metadata?: Record<string, JsonValue>;
}

export interface SliceDocument {
  namespace: string;
  schema?: string;
  dataSource?: string;

  state?: JsonObject;
  computed?: JsonObject;
  mutations?: JsonObject;
  queries?: JsonObject;
  pipelines?: JsonObject;
  strategies?: JsonObject;
  metadata?: Record<string, JsonValue>;

  fieldPolicies?: Record<string, FieldPolicySpec>;
  statePolicy?: Record<string, JsonValue>;
  fields?: Record<string, FieldPolicySpec>;

  resources?: Record<string, ResourceRefSpec>;
  assets?: Record<string, ResourceRefSpec>;
  media?: Record<string, ResourceRefSpec>;
  files?: Record<string, ResourceRefSpec>;

  protection?: ProtectionPolicySpec;

  runtime?: JsonObject;
  slice?: JsonObject;
  behavior?: JsonObject;
  options?: JsonObject;
  raw?: Record<string, JsonValue>;
}

export interface SliceDefinition<S extends Record<string, any>> {
  namespace: string;
  schema?: string;
  dataSource?: string;
  state?: S | Record<string, any>;
  computed?: JsonObject;
  mutations?: JsonObject;
  queries?: JsonObject;
  pipelines?: JsonObject;
  strategies?: JsonObject;
  metadata?: Record<string, JsonValue>;
  fieldPolicies?: Record<string, FieldPolicySpec>;
  statePolicy?: Record<string, JsonValue>;
  fields?: Record<string, FieldPolicySpec>;
  resources?: Record<string, ResourceRefSpec>;
  assets?: Record<string, ResourceRefSpec>;
  media?: Record<string, ResourceRefSpec>;
  files?: Record<string, ResourceRefSpec>;
  protection?: ProtectionPolicySpec;
  runtime?: JsonObject;
}

export interface BindingProxy<T> { readonly __binding?: T; }
export interface PathProxy<T> { readonly __path?: T; }
export interface ExprProxy<T> { readonly __expr?: T; }

export interface TypedSlice<S extends Record<string, any>> {
  namespace: string;
  bind: BindingProxy<S>;
  path: PathProxy<S>;
  ref: ExprProxy<S>;
  toJSON(): SliceDocument;
}

export function defineSlice<S extends Record<string, any>>(def: SliceDefinition<S>): TypedSlice<S> {
  const stateJson: JsonObject = {};
  if (def.state) for (const k in def.state) if (_hasOwn(def.state, k)) {
    const v = (def.state as any)[k];
    stateJson[k] = v && typeof v === 'object' && '_tag' in v ? null : (v as JsonValue);
  }

  return {
    namespace: def.namespace,
    bind: {} as BindingProxy<S>,
    path: {} as PathProxy<S>,
    ref: {} as ExprProxy<S>,
    toJSON(): SliceDocument {
      const out: SliceDocument = { namespace: def.namespace };
      if (def.schema) out.schema = def.schema;
      if (def.dataSource) out.dataSource = def.dataSource;
      if (stateJson) out.state = stateJson;
      if (def.computed) out.computed = def.computed;
      if (def.mutations) out.mutations = def.mutations;
      if (def.queries) out.queries = def.queries;
      if (def.pipelines) out.pipelines = def.pipelines;
      if (def.strategies) out.strategies = def.strategies;
      if (def.metadata) out.metadata = def.metadata;
      if (def.fieldPolicies) out.fieldPolicies = def.fieldPolicies;
      if (def.statePolicy) out.statePolicy = def.statePolicy;
      if (def.fields) out.fields = def.fields;
      if (def.resources) out.resources = def.resources;
      if (def.assets) out.assets = def.assets;
      if (def.media) out.media = def.media;
      if (def.files) out.files = def.files;
      if (def.protection) out.protection = def.protection;
      if (def.runtime) out.runtime = def.runtime;
      return out;
    },
  };
}

export interface StoreDefinition<S extends Record<string, any>> {
  namespace: string;
  state: S;
  computed?: Record<string, (state: S) => JsonValue>;
  mutations?: Record<string, (state: S, payload?: any) => void>;
  queries?: Record<string, JsonObject>;
  resources?: Record<string, ResourceRefSpec>;
  fieldPolicies?: Record<string, FieldPolicySpec>;
  protection?: ProtectionPolicySpec;
  runtime?: JsonObject;
  pipelines?: JsonObject;
}

export interface TypedStoreDescriptor<S extends Record<string, any>> {
  namespace: string;
  bind: BindingProxy<S>;
  path: PathProxy<S>;
  ref: ExprProxy<S>;
  toSlice(): SliceDocument;
  toJSON(): JsonObject;
}

export function defineStore<S extends Record<string, any>>(
  namespace: string,
  factory: () => S,
): TypedStoreDescriptor<S> {
  const state = factory();
  const stateJson: JsonObject = {};
  for (const k in state) if (_hasOwn(state, k)) stateJson[k] = state[k] as JsonValue;

  return {
    namespace,
    bind: {} as BindingProxy<S>,
    path: {} as PathProxy<S>,
    ref: {} as ExprProxy<S>,
    toSlice(): SliceDocument {
      return { namespace, state: stateJson };
    },
    toJSON(): JsonObject {
      return { namespace, state: stateJson };
    },
  };
}

/* ============================================================
 * 14) THEME PIPELINE
 * ============================================================ */

export type ColorScale =
  Partial<Record<'50'|'100'|'150'|'200'|'250'|'300'|'350'|'400'|'450'|'500'|'550'|'600'|'650'|'700'|'750'|'800'|'850'|'900'|'950', string>>;

export type ColorValue = string | ColorScale;

export interface TypographyInput {
  fontFamily?: string;
  fontSize?: number;
  fontWeight?: number;
  lineHeight?: number;
  letterSpacing?: number;
  textTransform?: string;
  fontStyle?: string;
}

export interface ShadowInput {
  offsetX?: number;
  offsetY?: number;
  blurRadius?: number;
  spread?: number;
  color?: string;
  inset?: boolean;
}

export interface AnimationInput {
  duration?: number;
  curve?: string;
  delay?: number;
  repeat?: number | boolean;
  fillMode?: string;
}
export interface ThemeInput {
  colors?: Record<string, ColorValue>;
  spacing?: Record<string, number | string>;
  typography?: Record<string, TypographyInput>;
  radii?: Record<string, number | string>;
  shadows?: Record<string, ShadowInput | string>;
  animations?: Record<string, AnimationInput>;
  breakpoints?: Record<string, number>;
  zIndex?: Record<string, number>;
  mode?: 'light' | 'dark' | 'system';
  [customGroup: string]: any;
}

export type ThemeTokenProxy<T> = {
  [K in keyof T]:
    T[K] extends Record<string, any>
      ? ThemeTokenProxy<T[K]>
      : DesignToken;
};

export type TypedTheme<T extends ThemeInput> = Readonly<T> & {
  tokens: ThemeTokenProxy<T>;
  toSlice(namespace?: string): SliceDocument;
  toJSON(): T;
};

function _buildTokenProxy(input: any, prefix: string): any {
  const out: any = {};
  for (const k in input) {
    if (!_hasOwn(input, k)) continue;
    const nextPath = prefix ? `${prefix}.${k}` : k;
    const v = input[k];
    if (v && typeof v === 'object' && !_isArray(v)) {
      out[k] = _buildTokenProxy(v, nextPath);
    } else {
      out[k] = (`$${nextPath}`) as DesignToken;
    }
  }
  return out;
}

export function createTheme<T extends ThemeInput>(theme: T): TypedTheme<T> {
  const frozen = _clone(theme) as Readonly<T>;
  const proxy = _buildTokenProxy(theme, '') as ThemeTokenProxy<T>;

  const out: any = {};
  _copyInto(out, frozen as any);
  out.tokens = proxy;
  out.toSlice = function(namespace = 'app.theme'): SliceDocument {
    const slice: SliceDocument = { namespace };
    if ((theme as any).colors) slice.state = { colors: (theme as any).colors as any };
    return slice;
  };
  out.toJSON = function(): T {
    return _clone(theme);
  };

  return out as TypedTheme<T>;
}

export interface PipelineDefinition {
  name: string;
  namespace?: string;
  steps?: JsonObject[];
  filters?: JsonObject[];
  sort?: JsonObject;
  search?: JsonObject;
  projection?: string[];
  [key: string]: JsonValue | undefined;
}

export interface TypedPipeline {
  toJSON(): PipelineDefinition;
}

export function definePipeline(def: PipelineDefinition): TypedPipeline {
  return { toJSON: () => ({ ...def }) };
}

/* ============================================================
 * 15) TEMPLATES, MATRIX LAYOUTS & COMPONENT FACTORIES
 * ============================================================ */

export interface MatrixSlotConfig {
  scrollable?: boolean;
  floating?: boolean;
  preserveOverlap?: boolean;
  draggable?: boolean;
  resizable?: boolean;
  reorderable?: boolean;
  align?: 'stretch' | 'start' | 'center' | 'end' | string;
  zIndex?: number;
  padding?: number | string;
  margin?: number | string;
  useHero?: boolean;
  heroTag?: string | null;
  resizeHandle?: 'none' | 'top' | 'bottom' | 'left' | 'right' | 'all' | string;
  hidden?: boolean;
  sticky?: boolean;
  className?: string;
  style?: StyleValue;
  props?: Record<string, JsonValue>;
}

export interface MatrixLayoutDefinition {
  type?: 'layout';
  name?: string;
  id?: string;
  gap?: number;
  defaultProps?: Record<string, JsonValue>;
  props?: Record<string, JsonValue>;
  matrix?: string;
  grid?: string;
  ascii?: string;
  sm?: string;
  md?: string;
  lg?: string;
  xl?: string;
  variants?: Record<string, string | { breakpoint: string }>;
  slots?: Record<string, MatrixSlotConfig>;
  description?: string;
  summary?: string;
  tags?: string[];
  metadata?: Record<string, JsonValue>;
}

export interface TypedTemplate<P extends Record<string, any>, Slots extends string = never> {
  name: string;
  define: SduiNode;
  use(props: P, slots?: Partial<Record<Slots, NodeInput>>): SduiElement<P>;
  call(overrideProps?: Partial<P>): SduiElement<P>;
  toJSON(): JsonObject;
}

function _schemaProxyValue(schema: any, path: string): any {
  if (!schema || typeof schema !== 'object') return `{{${path}}}`;
  if (schema._tag === 'object' && schema._meta && _isPlainObject(schema._meta.shape)) {
    return _schemaProxyObject(schema._meta.shape, path);
  }
  return `{{${path}}}`;
}

function _schemaProxyObject(shape: Record<string, any>, prefix: string): any {
  const out: any = {};
  for (const k in shape) {
    if (!_hasOwn(shape, k)) continue;
    out[k] = _schemaProxyValue(shape[k], `${prefix}.${k}`);
  }
  return out;
}

export function defineTemplate<
  P extends Record<string, QSchema<any, any>>,
  Slots extends string = never,
>(def: {
  name: string;
  props: P;
  ui: NodeInput | ((props: { [K in keyof P]: Infer<P[K]> }, slots: Partial<Record<Slots, NodeInput>>) => NodeInput);
  defaultProps?: Partial<{ [K in keyof P]: Infer<P[K]> }>;
  slots?: readonly Slots[];
  extends?: string;
  description?: string;
  tags?: string[];
  metadata?: JsonObject;
}): TypedTemplate<{ [K in keyof P]: Infer<P[K]> }, Slots> {
  type Props = { [K in keyof P]: Infer<P[K]> };
  const defaultProps: Partial<Props> = (def.defaultProps || {}) as any;
  const templatePropsProxy = _schemaProxyObject(def.props as any, 'props') as Props;
  const renderedUi = typeof def.ui === 'function'
    ? def.ui(templatePropsProxy as any, {} as any)
    : def.ui;

  function buildElement(
    props: Props,
    slots?: Partial<Record<Slots, NodeInput>>,
    variantName?: string,
  ): SduiElement<Props> {
    const mergedProps: JsonObject = {};
    if (defaultProps) _copyInto(mergedProps, defaultProps as any);
    _copyInto(mergedProps, props as any);

    const init: Partial<SduiNode> = {
      props: { ...mergedProps, name: def.name } as JsonObject,
    };

    if (variantName) (init.props as JsonObject).__variant = variantName;

    if (slots && Object.keys(slots).length > 0) {
      init.slots = {};
      for (const sk in slots) if (_hasOwn(slots as any, sk)) {
        (init.slots as any)[sk] = slots[sk as Slots];
      }
    }

    return new SduiElement<Props>(`template:${def.name}`, init);
  }

  const defineNode: SduiNode = {
    type: 'component:define',
    name: def.name,
    props: {
      ...(def.defaultProps || {}),
      name: def.name,
    } as JsonObject,
    slots: (function () {
      if (!def.slots || def.slots.length === 0) return undefined;
      const slotObj: JsonObject = {};
      for (let i = 0; i < def.slots.length; i++) slotObj[String(def.slots[i])] = null as any;
      return slotObj as any;
    })(),
    children: [_normalizeAny(renderedUi)],
  };

  return {
    name: def.name,
    use(props: Props, slots?: Partial<Record<Slots, NodeInput>>) {
      return buildElement(props, slots);
    },
    call(overrideProps?: Partial<Props>) {
      const el = new SduiElement<Props>(`template:${def.name}`, {
        props: { ...(overrideProps || {}), name: def.name } as JsonObject,
      });
      el.set('$call', def.name);
      return el;
    },
    define: defineNode,
    toJSON(): JsonObject {
      return {
        name: def.name,
        slots: (def.slots || []) as unknown as JsonValue,
        ui: _normalizeAny(renderedUi) as unknown as JsonValue,
        extends: def.extends as JsonValue,
        description: def.description as JsonValue,
        tags: (def.tags || []) as JsonValue,
        metadata: (def.metadata || {}) as JsonValue,
      };
    },
  };
}

export type ExactInfer<T> = [T][T extends any ? 0 : never];

export interface TypedComponent<P extends Record<string, any>> {
  name: string;
  use(props?: Partial<P> & { variant?: string }, slots?: Record<string, NodeInput>): SduiElement<ComponentProps>;
  define: SduiNode;
  toJSON(): JsonObject;
}

function _buildBindingProxy(pathPrefix: string): any {
  return new Proxy({}, {
    get(target, prop) {
      if (typeof prop !== 'string') return undefined;
      return `{{${pathPrefix}.${prop}}}`;
    },
  });
}

export interface ComponentConfig<
  P extends Record<string, QSchema<any, any>>,
  S extends Record<string, any>
> {
  description?: string;
  props?: P;
  state?: S;
  computed?: Record<string, ComponentComputedSpec>;
  hooks?: ComponentHookBundle;
  links?: Record<string, any>;
  variants?: Record<string, Partial<ExactInfer<{ [K in keyof P]: Infer<P[K]> }>>>;
  animations?: Record<string, any>;
  runtime?: Record<string, any>;
  policy?: Record<string, any>;
  ui: NodeInput | ((
    props: ExactInfer<{ [K in keyof P]: Binding<Infer<P[K]>> }>,
    state: ExactInfer<{ [K in keyof S]: Binding<S[K]> }>
  ) => NodeInput);
}

export function defineComponent<
  P extends Record<string, QSchema<any, any>> = {},
  S extends Record<string, any> = {}
>(
  name: string,
  def: ComponentConfig<P, S>,
): TypedComponent<{ [K in keyof P]: Infer<P[K]> }> {
  type Props = { [K in keyof P]: Infer<P[K]> };

  const renderedUi = typeof def.ui === 'function'
    ? def.ui(_buildBindingProxy('props'), _buildBindingProxy('state'))
    : def.ui;

  const defineNode: SduiNode = {
    type: 'component:define',
    name: name,
    props: {
      name: name,
      description: def.description,
      state: def.state,
      computed: def.computed,
      hooks: def.hooks,
      links: def.links,
      variants: def.variants,
      animations: def.animations,
      runtime: def.runtime,
      policy: def.policy,
      ui: _normalizeAny(renderedUi),
    } as unknown as JsonObject,
  };

  return {
    name: name,
    use(props?: Partial<Props> & { variant?: string }, slots?: Record<string, NodeInput>): SduiElement<ComponentProps> {
      const el = new SduiElement<ComponentProps>('component:use');
      el.props({ component: name, ...props } as any);
      if (slots && Object.keys(slots).length > 0) el.slots(slots);
      return el;
    },
    define: defineNode,
    toJSON(): JsonObject {
      return defineNode as unknown as JsonObject;
    },
  };
}

export interface TypedMacro<P extends Record<string, any>, Slots extends string = never> {
  name: string;
  use(props?: Partial<P>, slots?: Partial<Record<Slots, NodeInput>>): SduiElement<BaseProps>;
  define: SduiNode;
  toJSON(): JsonObject;
}

export interface MacroConfig<
  P extends Record<string, QSchema<any, any>>,
  Slots extends string
> {
  props?: P;
  pattern?: JsonValue;
  when?: JsonValue;
  replace?: JsonValue;
  args?: string[];
  slots?: string[];
  description?: string;
  defaultProps?: Partial<ExactInfer<{ [K in keyof P]: Infer<P[K]> }>>;
  defaultSlots?: Partial<Record<Slots, NodeInput>>;
  ui: NodeInput | ((
    props: ExactInfer<{ [K in keyof P]: Binding<Infer<P[K]>> }>
  ) => NodeInput);
}

export function defineMacro<
  P extends Record<string, QSchema<any, any>> = {},
  Slots extends string = never
>(
  name: string,
  def: MacroConfig<P, Slots>,
): TypedMacro<{ [K in keyof P]: Infer<P[K]> }, Slots> {
  type Props = { [K in keyof P]: Infer<P[K]> };

  const renderedUi = typeof def.ui === 'function'
    ? def.ui(_buildBindingProxy('props'))
    : def.ui;

  const defineNode: SduiNode = {
    type: 'macro',
    name: name,
    props: {
      pattern: def.pattern,
      when: def.when,
      replace: def.replace,
      args: def.args,
      slots: def.slots,
      description: def.description,
      defaultProps: def.defaultProps,
      defaultSlots: def.defaultSlots,
      $view: _normalizeAny(renderedUi),
    } as unknown as JsonObject,
  };

  return {
    name: name,
    use(props?: Partial<Props>, slots?: Partial<Record<Slots, NodeInput>>): SduiElement<BaseProps> {
      const el = new SduiElement<BaseProps>(name);
      if (props) el.props(props as any);
      if (slots && Object.keys(slots).length > 0) el.slots(slots as any);
      return el;
    },
    define: defineNode,
    toJSON(): JsonObject {
      return defineNode as unknown as JsonObject;
    },
  };
}

export function defineNodeType<P extends Record<string, QSchema<any, any>>>(def: {
  type: string;
  props: P;
  slots?: readonly string[];
  children?: boolean;
}): {
  type: string;
  create(
    props: { [K in keyof P]: Infer<P[K]> },
    slots?: Record<string, NodeInput>,
    init?: Omit<Partial<SduiNode>, 'type' | 'props' | 'slots'>
  ): SduiElement<{ [K in keyof P]: Infer<P[K]> }>;
} {
  type Props = { [K in keyof P]: Infer<P[K]> };
  return {
    type: def.type,
    create(props: Props, slots?: Record<string, NodeInput>, init?: Omit<Partial<SduiNode>, 'type' | 'props' | 'slots'>): SduiElement<Props> {
      return new SduiElement<Props>(def.type, {
        ...init,
        props: props as unknown as JsonObject,
        slots: slots as any,
      });
    },
  };
}

export interface ExtendedSduiFactory<NewRoots extends Record<string, readonly string[]>> {
  node(type: string, init?: Partial<SduiNode>): SduiElement<BaseProps>;
  core<R extends CatalogRoot | keyof NewRoots>(
    root: R,
    subtype: R extends keyof NewRoots ? NewRoots[R][number] : R extends CatalogRoot ? CatalogSubtype<R> : string,
    init?: Partial<SduiNode>,
  ): SduiElement<BaseProps>;
}

export interface ExtendedEngine<NewRoots extends Record<string, readonly string[]>> {
  roots: NewRoots;
  sdui: ExtendedSduiFactory<NewRoots>;
  factories: { [R in keyof NewRoots]: (subtype: NewRoots[R][number], init?: Partial<SduiNode>) => SduiElement<BaseProps> };
}

export function extendCatalog<NewRoots extends Record<string, readonly string[]>>(extensions: NewRoots): ExtendedEngine<NewRoots> {
  const factories: any = {};

  for (const root in extensions) {
    if (!_hasOwn(extensions, root)) continue;
    factories[root] = (subtype: string, init?: Partial<SduiNode>) => new SduiElement<BaseProps>(`${root}:${subtype}`, init);
  }

  const extSdui: ExtendedSduiFactory<NewRoots> = {
    node(type: string, init?: Partial<SduiNode>) {
      return new SduiElement<BaseProps>(type, init);
    },
    core(root: any, subtype: any, init?: Partial<SduiNode>) {
      const type = root === 'box' ? `box:${subtype}` : root;
      const propsBase = root === 'box' ? {} : { props: _copyObject(init && init.props, { __subType: subtype }) };
      return new SduiElement<BaseProps>(type, _buildInit(init, propsBase));
    },
  };

  return { roots: extensions, sdui: extSdui, factories: factories as any };
}

/* ============================================================
 * 16) CORE CONFIG / REGISTRY GRAPH
 * ============================================================ */

export interface QuantumConfigInput<
  Contracts extends Record<string, QSchema<any, any>>,
  Theme extends ThemeInput,
  Stores extends Record<string, TypedStoreDescriptor<any>>,
  Slices extends Record<string, TypedSlice<any>>,
  DataSources extends Record<string, DataSourceDocument>,
  Templates extends Record<string, TypedTemplate<any, any>>,
  Components extends Record<string, TypedComponent<any>>,
  Macros extends Record<string, TypedMacro<any, any>>,
  Pipelines extends Record<string, TypedPipeline>,
  Extensions extends Record<string, readonly string[]>,
  App extends QLAppYamlConfig = QLAppYamlConfig,
> {
  contracts?: Contracts;
  theme?: TypedTheme<Theme>;
  stores?: Stores;
  slices?: Slices;
  dataSources?: DataSources;
  templates?: Templates;
  components?: Components;
  macros?: Macros;
  pipelines?: Pipelines;
  extensions?: ExtendedEngine<Extensions>;
  app?: App;
  bundle?: QuantumDesignSystemBundle;
}

export type TypedConfig<
  Contracts extends Record<string, QSchema<any, any>>,
  Theme extends ThemeInput,
  Stores extends Record<string, TypedStoreDescriptor<any>>,
  Slices extends Record<string, TypedSlice<any>>,
  DataSources extends Record<string, DataSourceDocument>,
  Templates extends Record<string, TypedTemplate<any, any>>,
  Components extends Record<string, TypedComponent<any>>,
  Macros extends Record<string, TypedMacro<any, any>>,
  Pipelines extends Record<string, TypedPipeline>,
  Extensions extends Record<string, readonly string[]>,
  App extends QLAppYamlConfig = QLAppYamlConfig,
> = QuantumConfigInput<Contracts, Theme, Stores, Slices, DataSources, Templates, Components, Macros, Pipelines, Extensions, App> & {
  exportSlices(): SliceDocument[];
  exportDataSources(): DataSourceDocument[];
  exportTemplates(): JsonObject[];
  exportTheme(namespace?: string): SliceDocument | null;
  exportContracts(): JsonObject;
  exportAll(): JsonObject;
};

export function defineConfig<
  Contracts extends Record<string, QSchema<any, any>> = {},
  Theme extends ThemeInput = {},
  Stores extends Record<string, TypedStoreDescriptor<any>> = {},
  Slices extends Record<string, TypedSlice<any>> = {},
  DataSources extends Record<string, DataSourceDocument> = {},
  Templates extends Record<string, TypedTemplate<any, any>> = {},
  Components extends Record<string, TypedComponent<any>> = {},
  Macros extends Record<string, TypedMacro<any, any>> = {},
  Pipelines extends Record<string, TypedPipeline> = {},
  Extensions extends Record<string, readonly string[]> = {},
  App extends QLAppYamlConfig = QLAppYamlConfig,
>(
  input: QuantumConfigInput<Contracts, Theme, Stores, Slices, DataSources, Templates, Components, Macros, Pipelines, Extensions, App>,
): TypedConfig<Contracts, Theme, Stores, Slices, DataSources, Templates, Components, Macros, Pipelines, Extensions, App> {
  const config = {
    ...input,
    exportSlices(): SliceDocument[] {
      const out: SliceDocument[] = [];
      if (input.slices) for (const k in input.slices) if (_hasOwn(input.slices, k)) out.push(input.slices[k].toJSON());
      if (input.stores) for (const k in input.stores) if (_hasOwn(input.stores, k)) out.push(input.stores[k].toSlice());
      return out;
    },

    exportDataSources(): DataSourceDocument[] {
      const out: DataSourceDocument[] = [];
      if (input.dataSources) for (const k in input.dataSources) if (_hasOwn(input.dataSources, k)) out.push(input.dataSources[k]);
      return out;
    },

    exportTemplates(): JsonObject[] {
      const out: JsonObject[] = [];
      if (input.templates) for (const k in input.templates) if (_hasOwn(input.templates, k)) out.push(input.templates[k].toJSON());
      return out;
    },

    exportTheme(namespace = 'app.theme'): SliceDocument | null {
      return input.theme ? input.theme.toSlice(namespace) : null;
    },

    exportContracts(): JsonObject {
      const out: JsonObject = {};
      if (input.contracts) {
        for (const k in input.contracts) if (_hasOwn(input.contracts, k)) {
          const schema = input.contracts[k] as QSchema<any, any>;
          out[k] = { tag: schema._tag, meta: schema._meta ?? {} } as unknown as JsonValue;
        }
      }
      return out;
    },

    exportAll(): JsonObject {
      const out: JsonObject = {};
      if (input.app) out['app'] = input.app as unknown as JsonValue;
      const themeSlice = input.theme ? input.theme.toSlice() : null;
      if (themeSlice) out['theme'] = themeSlice as unknown as JsonValue;
      out['contracts'] = (this as any).exportContracts();
      out['slices'] = (this as any).exportSlices();
      out['dataSources'] = (this as any).exportDataSources();
      out['templates'] = (this as any).exportTemplates();
      if (input.bundle) out['bundle'] = input.bundle as unknown as JsonValue;
      return out;
    },
  } as TypedConfig<Contracts, Theme, Stores, Slices, DataSources, Templates, Components, Macros, Pipelines, Extensions, App>;

  return config;
}

export function defineKernel<
  Contracts extends Record<string, QSchema<any, any>> = {},
  Theme extends ThemeInput = {},
  Stores extends Record<string, TypedStoreDescriptor<any>> = {},
  Slices extends Record<string, TypedSlice<any>> = {},
  DataSources extends Record<string, DataSourceDocument> = {},
  Templates extends Record<string, TypedTemplate<any, any>> = {},
  Components extends Record<string, TypedComponent<any>> = {},
  Macros extends Record<string, TypedMacro<any, any>> = {},
  Pipelines extends Record<string, TypedPipeline> = {},
  Extensions extends Record<string, readonly string[]> = {},
  App extends QLAppYamlConfig = QLAppYamlConfig,
>(input: {
  contracts?: Contracts;
  theme?: TypedTheme<Theme>;
  stores?: Stores;
  slices?: Slices;
  dataSources?: DataSources;
  templates?: Templates;
  components?: Components;
  macros?: Macros;
  pipelines?: Pipelines;
  extensions?: ExtendedEngine<Extensions>;
  app?: App;
  bundle?: QuantumDesignSystemBundle;
}) {
  return {
    ...input,
    contractTypes: input.contracts || ({} as Contracts),
    defineConfig: () => defineConfig(input),
  };
}

export function defineContracts<C extends Record<string, QSchema<any, any>>>(contracts: C): C {
  return contracts;
}

/* ============================================================
 * 17) PAGE / ROUTE / LAYOUT DSL
 * ============================================================ */

export type QuantumPageRefKind = 'page' | 'route' | 'layout' | 'fragment';

export interface QuantumPageRef<TKind extends QuantumPageRefKind = QuantumPageRefKind> {
  kind: TKind;
  name: string;
  asset?: string;
  version?: string;
  hash?: string;
}

export interface QuantumPageSeo {
  title?: Expr<string>;
  description?: Expr<string>;
  keywords?: Expr<string[]>;
  canonical?: Expr<string>;
  robots?: Expr<string>;
  ogImage?: Expr<string>;
  author?: Expr<string>;
  tags?: Expr<string[]>;
  customMeta?: Record<string, any>;
}

export interface QuantumPageGuard {
  name?: string;
  type?: 'auth' | 'role' | 'feature' | 'condition' | 'redirect' | 'custom' | string;
  when?: Expr<boolean> | StatePath | string;
  role?: string | string[];
  feature?: string;
  condition?: Expr<boolean> | string;
  redirectTo?: Expr<string>;
  allow?: boolean;
  data?: Record<string, any>;
  meta?: Record<string, any>;
  otherwise?: Record<string, any>;
}

export interface QuantumPagePrefetch {
  route?: Expr<string>;
  routes?: Array<Expr<string>>;
  assets?: string[];
  data?: string[];
  layout?: boolean;
  fragments?: string[];
  priority?: 'low' | 'normal' | 'high';
  viewport?: 'visible' | 'idle' | 'immediate' | 'hover';
}

export interface QuantumPageLayoutSlot extends MatrixSlotConfig {
  slot?: string;
  fill?: NodeInput;
  loading?: NodeInput;
  error?: NodeInput;
  empty?: NodeInput;
}

export interface QuantumPageLayout extends MatrixLayoutDefinition {
  kind?: 'layout';
  mode?: 'stack' | 'grid' | 'matrix' | 'shell' | 'custom';
  template?: NodeInput;
  slots?: Record<string, QuantumPageLayoutSlot>;
  regions?: Record<string, QuantumPageLayoutSlot>;
  viewport?: 'phone' | 'tablet' | 'desktop' | 'responsive' | string;
  breakpoints?: Record<string, JsonValue>;
  stickyHeader?: boolean;
  stickyFooter?: boolean;
  scaffold?: boolean;
  safeArea?: boolean | 'all' | 'top' | 'bottom' | 'left' | 'right';
  meta?: Record<string, JsonValue>;
  ref?: QuantumPageRef<'layout'>;
  version?: string;
  cacheKey?: string;
}

export interface QuantumPageFragment {
  kind?: 'fragment';
  type?: 'fragment';
  name?: string;
  id?: string;
  template?: NodeInput;
  data?: Record<string, any>;
  props?: Record<string, any>;
  slots?: Record<string, NodeInput>;
  lazy?: boolean;
  hydrate?: 'immediate' | 'visible' | 'idle' | 'interaction';
  cacheKey?: string;
  version?: string;
  tags?: string[];
  meta?: Record<string, any>;
  ref?: QuantumPageRef<'fragment'>;
}

export interface QuantumPageManifest {
  kind?: 'page';
  type?: 'route' | 'screen' | 'page' | 'component' | 'widget' | 'layout' | 'modal' | 'drawer' | 'overlay' | 'fragment' | 'template' | string;
  name?: string;
  id?: string;
  path?: string;
  slug?: string;
  nested?: boolean;
  group?: string;
  segment?: string;
  params?: Record<string, any>;
  query?: Record<string, any>;
  layout?: QuantumPageLayout | QuantumPageRef<'layout'> | string;
  page?: QuantumPageFragment | QuantumPageRef<'fragment'> | SduiNode | SduiElement<any> | any;
  children?: QuantumPageManifest[] | QuantumPageTree;
  slots?: Record<string, SduiNode | SduiElement<any> | any>;
  seo?: QuantumPageSeo;
  guards?: QuantumPageGuard[];
  prefetch?: QuantumPagePrefetch;
  loading?: SduiNode | SduiElement<any> | any;
  error?: SduiNode | SduiElement<any> | any;
  empty?: SduiNode | SduiElement<any> | any;
  state?: Record<string, any>;
  data?: Record<string, any>;
  meta?: Record<string, any>;
  layoutProps?: Record<string, any>;
  transitions?: Record<string, any>;
  cacheKey?: string;
  version?: string;
  routeId?: string;
  ref?: QuantumPageRef<'page'>;
}

export interface QuantumPageTree {
  routes: QuantumPageManifest[];
}

export interface QuantumPageBundle {
  pages?: QuantumPageTree | QuantumPageManifest[];
  layouts?: Record<string, QuantumPageLayout | QuantumPageRef<'layout'>>;
  fragments?: Record<string, QuantumPageFragment | QuantumPageRef<'fragment'>>;
  seo?: Record<string, QuantumPageSeo>;
  guards?: Record<string, QuantumPageGuard>;
  prefetch?: Record<string, QuantumPagePrefetch>;
  meta?: Record<string, any>;
}

function _pageClone<T>(value: T): T {
  if (value === undefined || value === null) return value;
  if (typeof value !== 'object') return value;
  if (value instanceof SduiElement) {
    return toNativeObject(value) as any;
  }
  if (Array.isArray(value)) {
    const arr: any[] = [];
    for (let i = 0; i < value.length; i++) arr.push(_pageClone(value[i]));
    return arr as any;
  }
  const out: Record<string, any> = {};
  for (const key in value as any) {
    if (Object.prototype.hasOwnProperty.call(value, key)) {
      out[key] = _pageClone((value as any)[key]);
    }
  }
  return out as any;
}

function _pageNormalizeNode(value: any): any {
  if (value instanceof SduiElement) return toNativeObject(value);
  if (Array.isArray(value)) {
    const arr: any[] = [];
    for (let i = 0; i < value.length; i++) arr.push(_pageNormalizeNode(value[i]));
    return arr;
  }
  if (value && typeof value === 'object') return _pageClone(value);
  return String(value);
}

function _pageNormalizePath(path?: string): string | undefined {
  const text = path ? path.trim() : '';
  if (!text) return undefined;
  return text.charAt(0) === '/' ? text : '/' + text;
}

function _pageNormalizeRef<TKind extends QuantumPageRefKind>(
  ref: QuantumPageRef<TKind> | string | undefined,
  kind: TKind,
): QuantumPageRef<TKind> | undefined {
  if (!ref) return undefined;
  if (typeof ref === 'string') return { kind, name: ref } as QuantumPageRef<TKind>;
  return ref;
}

export function normalizePageManifest(input: QuantumPageManifest): Record<string, any> {
  const name = ((input.name ?? input.id ?? '') as any).toString().trim();
  const routeId = ((input.routeId ?? input.id ?? input.name ?? name) as any).toString().trim();

  return {
    kind: 'page',
    type: input.type || 'route',
    name: name || undefined,
    id: ((input.id ?? input.name) as any)?.toString().trim() || undefined,
    path: _pageNormalizePath(input.path),
    slug: input.slug ? input.slug.toString().trim() : undefined,
    nested: !!input.nested,
    group: input.group ? input.group.toString().trim() : undefined,
    segment: input.segment ? input.segment.toString().trim() : undefined,
    params: input.params ? _pageClone(input.params) : undefined,
    query: input.query ? _pageClone(input.query) : undefined,
    layout: input.layout ? _pageClone(input.layout) : undefined,
    page: input.page ? _pageNormalizeNode(input.page) : undefined,
    slots: input.slots ? _pageClone(input.slots) : undefined,
    seo: input.seo ? _pageClone(input.seo) : undefined,
    guards: input.guards ? _pageClone(input.guards) : undefined,
    prefetch: input.prefetch ? _pageClone(input.prefetch) : undefined,
    loading: input.loading ? _pageNormalizeNode(input.loading) : undefined,
    error: input.error ? _pageNormalizeNode(input.error) : undefined,
    empty: input.empty ? _pageNormalizeNode(input.empty) : undefined,
    state: input.state ? _pageClone(input.state) : undefined,
    data: input.data ? _pageClone(input.data) : undefined,
    meta: input.meta ? _pageClone(input.meta) : undefined,
    layoutProps: input.layoutProps ? _pageClone(input.layoutProps) : undefined,
    transitions: input.transitions ? _pageClone(input.transitions) : undefined,
    cacheKey: input.cacheKey ? input.cacheKey.toString().trim() : undefined,
    version: input.version ? input.version.toString().trim() : undefined,
    routeId: routeId || undefined,
    ref: _pageNormalizeRef(input.ref, 'page'),
  };
}

export function normalizePageTree(tree: QuantumPageTree | QuantumPageManifest[]): QuantumPageTree {
  const routes = Array.isArray(tree) ? tree : tree.routes;
  const out: QuantumPageManifest[] = [];
  for (let i = 0; i < routes.length; i++) {
    out.push(normalizePageManifest(routes[i]) as any);
  }
  return { routes: out };
}

export function normalizePageBundle(bundle: QuantumPageBundle): QuantumPageBundle {
  return _pageClone(bundle);
}

export function page(input: QuantumPageManifest): Record<string, any> {
  return normalizePageManifest(input);
}

export function route(input: QuantumPageManifest): Record<string, any> {
  return normalizePageManifest({ ...input, kind: 'page', type: 'route' });
}

export function layout(input: QuantumPageLayout): Record<string, any> {
  const out: Record<string, any> = _pageClone(input);
  out.kind = 'layout';
  out.type = 'layout';
  out.ref = _pageNormalizeRef(input.ref, 'layout');
  return out;
}

export function fragment(input: QuantumPageFragment): Record<string, any> {
  const out: Record<string, any> = _pageClone(input);
  out.kind = 'fragment';
  out.type = 'fragment';
  out.ref = _pageNormalizeRef(input.ref, 'fragment');
  return out;
}

export function nested(routes: QuantumPageManifest[]): QuantumPageTree {
  return normalizePageTree(routes);
}

export function tree(routes: QuantumPageManifest[] | QuantumPageTree): QuantumPageTree {
  return normalizePageTree(routes);
}

export function pageRef(name: string, asset?: string): QuantumPageRef<'page'> {
  return { kind: 'page', name, asset };
}

export function routeRef(name: string, asset?: string): QuantumPageRef<'route'> {
  return { kind: 'route', name, asset };
}

export function layoutRef(name: string, asset?: string): QuantumPageRef<'layout'> {
  return { kind: 'layout', name, asset };
}

export function fragmentRef(name: string, asset?: string): QuantumPageRef<'fragment'> {
  return { kind: 'fragment', name, asset };
}

export function seo(input: QuantumPageSeo): QuantumPageSeo {
  return _pageClone(input);
}

export function guard(input: QuantumPageGuard): QuantumPageGuard {
  return _pageClone(input);
}

export function prefetch(input: QuantumPagePrefetch): QuantumPagePrefetch {
  return _pageClone(input);
}

export function bundle(input: QuantumPageBundle): QuantumPageBundle {
  return normalizePageBundle(input);
}

export function toPageJson(input: QuantumPageManifest): Record<string, any> {
  return normalizePageManifest(input);
}

export const qpage = {
  page,
  route,
  layout,
  fragment,
  nested,
  tree,
  pageRef,
  routeRef,
  layoutRef,
  fragmentRef,
  seo,
  guard,
  prefetch,
  bundle,
  toPageJson,
} as const;

/* ============================================================
 * 18) PUBLIC FACTORY API
 * ============================================================ */

export const sdui = {
  node<P extends Record<string, any> = BaseProps>(type: QuantumNodeType, init?: Partial<SduiNode>): SduiElement<P> {
    return new SduiElement<P>(type, init);
  },

  type<P extends Record<string, any> = BaseProps>(type: QuantumNodeType, init?: Partial<SduiNode>): SduiElement<P> {
    return new SduiElement<P>(type, init);
  },

  core<R extends CatalogRoot>(
    root: R,
    subtype: CatalogSubtype<R> | string,
    init?: Partial<SduiNode>,
  ): SduiElement<PropsFor<R>> {
    const type = root === 'box' ? `box:${String(subtype)}` : root;
    const extra = root === 'box' ? {} : { props: _copyObject(init && init.props, { __subType: subtype }) };
    return new SduiElement<PropsFor<R>>(type, _buildInit(init, extra));
  },

  subtype<R extends CatalogRoot>(
    root: R,
    subtype: CatalogSubtype<R> | string,
    init?: Partial<SduiNode>,
  ): SduiElement<PropsFor<R>> {
    return sdui.core(root, subtype, init);
  },

  page(children: NodeInput[], init?: Partial<SduiNode>): SduiElement<BoxProps> {
    return new SduiElement<BoxProps>('page', _buildInit(init, { children: children.slice() }));
  },

  box(children: NodeInput[], init?: Partial<SduiNode>): SduiElement<BoxProps> {
    return new SduiElement<BoxProps>('box', _buildInit(init, { children: children.slice() }));
  },

  text(value: Expr<string>, init?: Partial<SduiNode>): SduiElement<TextProps> {
    return new SduiElement<TextProps>('text', _buildInit(init, { props: { text: value } as JsonObject }));
  },

  title(value: Expr<string>, init?: Partial<SduiNode>): SduiElement<TextProps> {
    return new SduiElement<TextProps>('text', _buildInit(init, { props: { text: value, variant: 'heading' } as JsonObject }));
  },

  button(props: Partial<ActionProps> & { text?: Expr<string> }, init?: Partial<SduiNode>): SduiElement<ActionProps> {
    return new SduiElement<ActionProps>('action', _buildInit(init, { props: props as unknown as JsonObject }));
  },

  input(props: Partial<FieldProps>, init?: Partial<SduiNode>): SduiElement<FieldProps> {
    return new SduiElement<FieldProps>('field', _buildInit(init, { props: props as unknown as JsonObject }));
  },

  media(props: Partial<MediaProps>, init?: Partial<SduiNode>): SduiElement<MediaProps> {
    return new SduiElement<MediaProps>('media', _buildInit(init, { props: props as unknown as JsonObject }));
  },

  data(props: Partial<DataProps>, init?: Partial<SduiNode>): SduiElement<DataProps> {
    return new SduiElement<DataProps>('data', _buildInit(init, { props: props as unknown as JsonObject }));
  },

  portal(props: Partial<PortalProps>, init?: Partial<SduiNode>): SduiElement<PortalProps> {
    return new SduiElement<PortalProps>('portal', _buildInit(init, { props: props as unknown as JsonObject }));
  },

  canvas(props: Partial<CanvasProps>, init?: Partial<SduiNode>): SduiElement<CanvasProps> {
    return new SduiElement<CanvasProps>('canvas', _buildInit(init, { props: props as unknown as JsonObject }));
  },

  chart(props: Partial<ChartProps>, init?: Partial<SduiNode>): SduiElement<ChartProps> {
    return new SduiElement<ChartProps>('chart', _buildInit(init, { props: props as unknown as JsonObject }));
  },

  decoration(props: Partial<DecorationProps>, init?: Partial<SduiNode>): SduiElement<DecorationProps> {
    return new SduiElement<DecorationProps>('decoration', _buildInit(init, { props: props as unknown as JsonObject }));
  },

  stream(props: Partial<StreamNodeProps>, init?: Partial<SduiNode>): SduiElement<StreamNodeProps> {
    return new SduiElement<StreamNodeProps>('stream', _buildInit(init, { props: props as unknown as JsonObject }));
  },

  collab(props: Partial<CollabProps>, init?: Partial<SduiNode>): SduiElement<CollabProps> {
    return new SduiElement<CollabProps>('collab', _buildInit(init, { props: props as unknown as JsonObject }));
  },

  component(props: Partial<ComponentProps>, init?: Partial<SduiNode>): SduiElement<ComponentProps> {
    return new SduiElement<ComponentProps>('component', _buildInit(init, { props: props as unknown as JsonObject }));
  },

  visual(props: Partial<VisualProps>, init?: Partial<SduiNode>): SduiElement<VisualProps> {
    return new SduiElement<VisualProps>('visual', _buildInit(init, { props: props as unknown as JsonObject }));
  },

  store(namespace: string, state: Record<string, any>) {
    return defineStore(namespace, () => ({ ...state }));
  },

  slice<S extends Record<string, any>>(def: SliceDefinition<S>) {
    return defineSlice(def);
  },

  theme<T extends ThemeInput>(theme: T) {
    return createTheme(theme);
  },

  dataSource(def: DataSourceDefinition) {
    return defineDataSource(def);
  },

  pipeline(def: PipelineDefinition) {
    return definePipeline(def);
  },

  template(def: any) {
    return defineTemplate(def);
  },

  componentDef<
    P extends Record<string, QSchema<any, any>> = {},
    S extends Record<string, any> = {}
  >(name: string, def: Parameters<typeof defineComponent<P, S>>[1]) {
    return defineComponent<P, S>(name, def);
  },

  macroDef<
    P extends Record<string, QSchema<any, any>> = {},
    Slots extends string = never
  >(name: string, def: Parameters<typeof defineMacro<P, Slots>>[1]) {
    return defineMacro<P, Slots>(name, def);
  },

  nodeType(def: any) {
    return defineNodeType(def);
  },
} as const;

/* ============================================================
 * 19) EXTRA HELPERS / EXPORTS
 * ============================================================ */

export function toNativeObject(node: NodeInput, options?: EmitOptions): SduiNode {
  const n = _normalizeAny(node);
  if (options?.canonicalizeSlots) _canonicalizeSlots(n);
  return _emitNode(
    n,
    options || {},
    options && options.includeDebugPath === false ? undefined : 'root',
  );
}

export function toNativeJson(node: NodeInput, options?: EmitOptions): string {
  return JSON.stringify(
    toNativeObject(node, options),
    null,
    options && options.pretty ? (options.indent || 2) : 0,
  );
}

export function validateNode(node: NodeInput): ValidationResult {
  const issues: ValidationIssue[] = [];
  _validateAny(node, 'root', issues);
  return { ok: issues.length === 0, issues };
}

export const KNOWN_VM_OPERATORS = [
  '$define',
  '$let',
  '$call',
  '$classes',
  '$scope',
  '$switch',
  '$if',
  '$repeat',
  '$apply',
  '$layout',
  '$try',
  '$catch',
  '$finally',
  '$async',
  '$loading',
  '$data',
  '$error',
  '$portal',
  '$reactive_map',
  '$compose',
  '$watch',
  '$parallel',
  '$throttle',
  '$debounce',
  '$machine',
  '$stream',
  '$spread',
  '$view',
  '$slot',
  '$slots',
  '$state',
  '$env',
  '$route',
  '$local',
] as const;

export type QuantumVmOperator = typeof KNOWN_VM_OPERATORS[number];

export function knownVmOperators(): string[] {
  return KNOWN_VM_OPERATORS.slice();
}

/* ============================================================
 * 20) DEFAULT EXPORT
 * ============================================================ */

export default {
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
  defineConfig,
  defineKernel,
  defineContracts,
  toNativeObject,
  toNativeJson,
  validateNode,
  knownVmOperators,
  QL_PRIMITIVE_FIELD_TYPES,
  QL_FLAG_BITS,
} as const;
