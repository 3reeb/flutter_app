
/**
 * Quantum SDUI TypeScript authoring toolkit.
 *
 * Core rule:
 *   This toolkit preserves authoring operators as JSON.
 *   It does NOT resolve $if / $repeat / $switch / $apply / etc.
 *   Your Dart VM resolves those operators at runtime.
 *
 * The emitted JSON stays close to the native Quantum shape:
 *   type, props, style, children, slots, debugPath
 * plus the original authoring keys.
 */

/* -------------------------------------------------------------------------------------------------
 * JSON primitives and node shapes
 * ------------------------------------------------------------------------------------------------- */

export type JsonPrimitive = string | number | boolean | null;
export type JsonValue = JsonPrimitive | JsonObject | JsonValue[];
export interface JsonObject { [key: string]: JsonValue; }

export interface SduiNode {
  type: string;
  props?: { [key: string]: JsonValue };
  style?: string;
  children?: NodeInput[];
  slots?: { [key: string]: any };
  debugPath?: string;

  name?: string;
  slot?: string;
  env?: { [key: string]: JsonValue };

  $define?: { [key: string]: JsonValue };
  $let?: { [key: string]: JsonValue };
  $call?: string;
  $classes?: { [key: string]: JsonValue };
  $scope?: JsonValue;
  $switch?: JsonValue;
  cases?: { [key: string]: NodeInput };
  default?: NodeInput;
  $if?: JsonValue;
  $repeat?: JsonValue;
  as?: string;
  indexAs?: string;
  $apply?: { props?: { [key: string]: JsonValue }; style?: string; mode?: "merge" | "override" };
  $layout?: string[];
  $try?: NodeInput;
  $catch?: NodeInput;
  $finally?: NodeInput;
  $async?: JsonValue;
  $loading?: NodeInput;
  $data?: NodeInput;
  $error?: NodeInput;
  $portal?: string;
  $reactive_map?: JsonValue | { bind: JsonValue; key?: JsonValue; as?: JsonValue };
  $compose?: JsonValue[];
  $watch?: JsonValue;
  $parallel?: NodeInput[];
  $throttle?: number;
  $debounce?: number;
  $machine?: JsonObject;
  $stream?: JsonValue | { bind: JsonValue; as?: JsonValue };
  $spread?: JsonValue;
  $view?: JsonValue;
  $slot?: string;
  $slots?: { [key: string]: NodeInput };

  [key: string]: any;
}

export type NodeInput = SduiNode | SduiElement | JsonPrimitive | NodeInput[];

export interface ValidationIssue {
  path: string;
  message: string;
}

export interface ValidationResult {
  ok: boolean;
  issues: ValidationIssue[];
}

export interface EmitOptions {
  pretty?: boolean;
  indent?: number;
  includeDebugPath?: boolean;
  canonicalizeSlots?: boolean;
  preserveNameAndSlot?: boolean;
}

/* -------------------------------------------------------------------------------------------------
 * Builder
 * ------------------------------------------------------------------------------------------------- */

export class SduiElement {
  private node: SduiNode;

  constructor(type: string, init?: Partial<SduiNode>) {
    this.node = createNode(type);
    if (init) mergeNode(this.node, init);
  }

  prop(key: string, value: JsonValue): this {
    if (!this.node.props) this.node.props = {};
    this.node.props[key] = value;
    return this;
  }

  props(values: { [key: string]: JsonValue }): this {
    if (!this.node.props) this.node.props = {};
    copyInto(this.node.props, values);
    return this;
  }

  style(value: string): this {
    this.node.style = mergeStyle(this.node.style, value);
    return this;
  }

  child(...items: NodeInput[]): this {
    if (!this.node.children) this.node.children = [];
    for (let i = 0; i < items.length; i++) this.node.children.push(items[i]);
    return this;
  }

  children(items: NodeInput[]): this {
    this.node.children = items.slice();
    return this;
  }

  slot(name: string, content: NodeInput): this {
    if (!this.node.slots) this.node.slots = {};
    this.node.slots[name] = content;
    return this;
  }

  slots(values: { [key: string]: NodeInput }): this {
    if (!this.node.slots) this.node.slots = {};
    copyInto(this.node.slots, values);
    return this;
  }

  define(values: { [key: string]: JsonValue }): this {
    this.node.$define = copyObject(this.node.$define, values);
    return this;
  }

  let(values: { [key: string]: JsonValue }): this {
    this.node.$let = copyObject(this.node.$let, values);
    return this;
  }

  call(name: string): this {
    this.node.$call = name;
    return this;
  }

  classes(values: { [key: string]: JsonValue }): this {
    this.node.$classes = copyObject(this.node.$classes, values);
    return this;
  }

  scope(value: JsonValue): this {
    this.node.$scope = value;
    return this;
  }

  when(value: JsonValue, cases: { [key: string]: NodeInput }, fallback?: NodeInput): this {
    this.node.$switch = value;
    this.node.cases = clone(cases);
    this.node.default = fallback;
    return this;
  }

  if(condition: JsonValue): this {
    this.node.$if = condition;
    return this;
  }

  repeat(bind: JsonValue, asName: string, indexAsName: string): this {
    this.node.$repeat = bind;
    this.node.as = asName;
    this.node.indexAs = indexAsName;
    return this;
  }

  apply(opts: { props?: { [key: string]: JsonValue }; style?: string; mode?: "merge" | "override" }): this {
    this.node.$apply = {
      props: opts.props ? clone(opts.props) : undefined,
      style: opts.style,
      mode: opts.mode,
    };
    return this;
  }

  layout(rows: string[]): this {
    this.node.$layout = rows.slice();
    return this;
  }

  tryCatch(spec: { try: NodeInput; catch?: NodeInput; finally?: NodeInput }): this {
    this.node.$try = spec.try;
    this.node.$catch = spec.catch;
    this.node.$finally = spec.finally;
    return this;
  }

  async(spec: JsonValue): this {
    this.node.$async = spec;
    return this;
  }

  loading(node: NodeInput): this {
    this.node.$loading = node;
    return this;
  }

  data(node: NodeInput): this {
    this.node.$data = node;
    return this;
  }

  error(node: NodeInput): this {
    this.node.$error = node;
    return this;
  }

  portal(name: string): this {
    this.node.$portal = name;
    return this;
  }

  reactiveMap(spec: JsonValue | { bind: JsonValue; key?: JsonValue; as?: JsonValue }): this {
    this.node.$reactive_map = spec;
    return this;
  }

  compose(values: JsonValue[]): this {
    this.node.$compose = values.slice();
    return this;
  }

  watch(expr: JsonValue): this {
    this.node.$watch = expr;
    return this;
  }

  parallel(nodes: NodeInput[]): this {
    this.node.$parallel = nodes.slice();
    return this;
  }

  throttle(ms: number): this {
    this.node.$throttle = ms;
    this.node.$debounce = undefined;
    return this;
  }

  debounce(ms: number): this {
    this.node.$debounce = ms;
    this.node.$throttle = undefined;
    return this;
  }

  machine(spec: JsonObject): this {
    this.node.$machine = clone(spec);
    return this;
  }

  stream(spec: JsonValue | { bind: JsonValue; as?: JsonValue }): this {
    this.node.$stream = spec;
    return this;
  }

  spread(value: JsonValue): this {
    this.node.$spread = value;
    return this;
  }

  view(value: JsonValue): this {
    this.node.$view = value;
    return this;
  }

  withDebugPath(path: string): this {
    this.node.debugPath = path;
    return this;
  }

  toAuthoringNode(): SduiNode {
    return clone(this.node);
  }

  toNativeObject(options?: EmitOptions): SduiNode {
    return emitNode(this.node, options || {});
  }

  toNativeJson(options?: EmitOptions): string {
    const emitted = this.toNativeObject(options);
    return JSON.stringify(emitted, null, options && options.pretty ? (options.indent || 2) : 0);
  }
}

/* -------------------------------------------------------------------------------------------------
 * Factory API
 * ------------------------------------------------------------------------------------------------- */

export var sdui = {
  node: function (type: string, init?: Partial<SduiNode>) {
    return new SduiElement(type, init);
  },

  page: function (children: NodeInput[], init?: Partial<SduiNode>) {
    return new SduiElement("page", buildInit(init, { children: children.slice() }));
  },

  box: function (children: NodeInput[], init?: Partial<SduiNode>) {
    return new SduiElement("box", buildInit(init, { children: children.slice() }));
  },

  row: function (children: NodeInput[], init?: Partial<SduiNode>) {
    return new SduiElement("box:row", buildInit(init, { children: children.slice() }));
  },

  col: function (children: NodeInput[], init?: Partial<SduiNode>) {
    return new SduiElement("box:col", buildInit(init, { children: children.slice() }));
  },

  stack: function (children: NodeInput[], init?: Partial<SduiNode>) {
    return new SduiElement("box:stack", buildInit(init, { children: children.slice() }));
  },

  grid: function (children: NodeInput[], init?: Partial<SduiNode>) {
    return new SduiElement("box:grid", buildInit(init, { children: children.slice() }));
  },

  text: function (text: string, init?: Partial<SduiNode>) {
    return new SduiElement("text", buildInit(init, { props: mergeProps(init && init.props, { text: text }) }));
  },

  image: function (src: string, init?: Partial<SduiNode>) {
    return new SduiElement("image", buildInit(init, { props: mergeProps(init && init.props, { src: src }) }));
  },

  avatar: function (src: string, init?: Partial<SduiNode>) {
    return new SduiElement("avatar", buildInit(init, { props: mergeProps(init && init.props, { src: src }) }));
  },

  button: function (text: string, init?: Partial<SduiNode>) {
    return new SduiElement("action:button", buildInit(init, { props: mergeProps(init && init.props, { text: text }) }));
  },

  link: function (text: string, href: string, init?: Partial<SduiNode>) {
    return new SduiElement("action:link", buildInit(init, { props: mergeProps(init && init.props, { text: text, href: href }) }));
  },

  input: function (init?: Partial<SduiNode>) {
    return new SduiElement("field:input", init);
  },

  select: function (init?: Partial<SduiNode>) {
    return new SduiElement("field:select", init);
  },

  card: function (children: NodeInput[], init?: Partial<SduiNode>) {
    return new SduiElement("card", buildInit(init, { children: children.slice() }));
  },

  center: function (children: NodeInput[], init?: Partial<SduiNode>) {
    return new SduiElement("center", buildInit(init, { children: children.slice() }));
  },

  layout: function (rows: string[], slots: { [key: string]: NodeInput }, init?: Partial<SduiNode>) {
    return new SduiElement("box:grid", buildInit(init, { $layout: rows.slice(), slots: clone(slots) }));
  },

  if: function (condition: JsonValue, node: NodeInput) {
    return new SduiElement("box", { $if: condition, children: [node] });
  },

  repeat: function (bind: JsonValue, child: NodeInput, asName: string, indexAsName: string) {
    return new SduiElement("system", {
      props: { __subType: "repeater" },
      $repeat: bind,
      as: asName,
      indexAs: indexAsName,
      children: [child],
    });
  },

  switch: function (value: JsonValue, cases: { [key: string]: NodeInput }, fallback?: NodeInput) {
    return new SduiElement("switch", { $switch: value, cases: clone(cases), default: fallback });
  },

  async: function (spec: JsonValue, init?: Partial<SduiNode>) {
    return new SduiElement("system", buildInit(init, { $async: spec }));
  },

  tryCatch: function (spec: { try: NodeInput; catch?: NodeInput; finally?: NodeInput }) {
    return new SduiElement("hook", {
      props: { __subType: "error_boundary" },
      $try: spec.try,
      $catch: spec.catch,
      $finally: spec.finally,
    });
  },

  apply: function (children: NodeInput[], opts?: { props?: { [key: string]: JsonValue }; style?: string; mode?: "merge" | "override" }) {
    return new SduiElement("$apply", { $apply: opts, children: children.slice() });
  },

  portal: function (name: string, content: NodeInput) {
    return new SduiElement("portal", { $portal: name, children: [content] });
  },

  stream: function (spec: JsonValue | { bind: JsonValue; as?: JsonValue }, children?: NodeInput[]) {
    return new SduiElement("data", { $stream: spec, children: children ? children.slice() : [] });
  },

  watch: function (expr: JsonValue, child: NodeInput) {
    return new SduiElement("box", { $watch: expr, children: [child] });
  },

  parallel: function (children: NodeInput[]) {
    return new SduiElement("box:col", { $parallel: children.slice() });
  },

  machine: function (spec: JsonObject, children?: NodeInput[]) {
    return new SduiElement("control", { $machine: clone(spec), children: children ? children.slice() : [] });
  },

  reactiveMap: function (spec: JsonValue | { bind: JsonValue; key?: JsonValue; as?: JsonValue }, children?: NodeInput[]) {
    return new SduiElement("data", { $reactive_map: spec, children: children ? children.slice() : [] });
  },

  define: function (definitions: { [key: string]: JsonValue }, init?: Partial<SduiNode>) {
    return new SduiElement("template", buildInit(init, { $define: clone(definitions) }));
  },

  let: function (values: { [key: string]: JsonValue }, init?: Partial<SduiNode>) {
    return new SduiElement("template", buildInit(init, { $let: clone(values) }));
  },

  classes: function (values: { [key: string]: JsonValue }, init?: Partial<SduiNode>) {
    return new SduiElement("box", buildInit(init, { $classes: clone(values) }));
  },

  scope: function (value: JsonValue, init?: Partial<SduiNode>) {
    return new SduiElement("box", buildInit(init, { $scope: value }));
  },

  spread: function (value: JsonValue, init?: Partial<SduiNode>) {
    return new SduiElement("box", buildInit(init, { $spread: value }));
  },
};

/* -------------------------------------------------------------------------------------------------
 * Public emitters and validation
 * ------------------------------------------------------------------------------------------------- */

export function toNativeObject(node: NodeInput, options?: EmitOptions): SduiNode {
  return emitNode(normalizeAny(node), options || {}, options && options.includeDebugPath === false ? undefined : "root");
}

export function toNativeJson(node: NodeInput, options?: EmitOptions): string {
  return JSON.stringify(toNativeObject(node, options), null, options && options.pretty ? (options.indent || 2) : 0);
}

export function validateNode(node: NodeInput): ValidationResult {
  var issues: ValidationIssue[] = [];
  validateAny(node, "root", issues);
  return { ok: issues.length === 0, issues: issues };
}

export function knownVmOperators(): string[] {
  return KNOWN_VM_OPERATORS.slice();
}

/* -------------------------------------------------------------------------------------------------
 * Internal normalization
 * ------------------------------------------------------------------------------------------------- */

function normalizeAny(input: any): SduiNode {
  if (input instanceof SduiElement) return input.toAuthoringNode();

  if (isArray(input)) {
    if (input.length === 0) return { type: "empty" };

    var head = input[0];
    var type = String(head == null ? "empty" : head);
    var node: SduiNode = { type: type, props: {}, children: [] };

    for (var i = 1; i < input.length; i++) {
      var item: any = input[i];

      if (i === 1 && isPlainObject(item)) {
        for (var k in item) {
          if (!hasOwn(item, k)) continue;
          var v = item[k];

          if (k === "$slots" && isPlainObject(v)) {
            node.slots = {};
            for (var slotName in v) {
              if (!hasOwn(v, slotName)) continue;
              node.slots[slotName] = v[slotName];
            }
          } else if (k === "props" && isPlainObject(v)) {
            node.props = clone(v);
          } else if (k === "children" && isArray(v)) {
            node.children = (v as NodeInput[]).slice();
          } else if (k === "style") {
            node.style = v == null ? undefined : String(v);
          } else if (k === "name" || k === "slot" || startsWith(k, "$") || k === "cases" || k === "default" || k === "as" || k === "indexAs" || k === "debugPath" || k === "env") {
            (node as any)[k] = v;
          } else {
            node.props![k] = v;
          }
        }
        continue;
      }

      if (typeof item === "string") {
        if (i === 1 && (!node.props || objectSize(node.props) === 0) && (!node.children || node.children.length === 0)) {
          if (startsWith(type, "text") || startsWith(type, "action")) {
            if (!node.props) node.props = {};
            node.props.text = item;
          } else {
            node.style = mergeStyle(node.style, item);
          }
        } else {
          if (!node.children) node.children = [];
          node.children.push({ type: "text", props: { text: item } });
        }
        continue;
      }

      if (isArray(item)) {
        if (!node.children) node.children = [];
        for (var j = 0; j < item.length; j++) node.children.push(item[j]);
        continue;
      }

      if (isPlainObject(item) && typeof item.type === "string" && input.length === 2) {
        if (!node.children) node.children = [];
        node.children.push(item as NodeInput);
        continue;
      }

      if (!node.children) node.children = [];
      node.children.push(item);
    }

    return node;
  }

  if (isPlainObject(input)) return clone(input as SduiNode);

  if (typeof input === "string") return { type: "text", props: { text: input } };
  if (typeof input === "number" || typeof input === "boolean") return { type: "text", props: { text: String(input) } };

  return { type: "empty" };
}

function emitNode(node: any, options: EmitOptions, path?: string): SduiNode {
  var input = clone(node);
  var out: SduiNode = { type: String(input.type || "box") };

  if (input.props && objectSize(input.props) > 0) out.props = clone(input.props);
  if (input.style != null && String(input.style).trim() !== "") out.style = String(input.style).trim();

  if (input.children && input.children.length > 0) {
    out.children = [];
    for (var i = 0; i < input.children.length; i++) {
      out.children.push(emitNode(normalizeAny(input.children[i]), options, (path || "root") + ".children[" + i + "]"));
    }
  }

  if (input.slots && objectSize(input.slots) > 0) {
    out.slots = {};
    for (var slotName in input.slots) {
      if (!hasOwn(input.slots, slotName)) continue;
      out.slots[slotName] = emitNode(normalizeAny(input.slots[slotName]), options, (path || "root") + ".slots." + slotName);
    }
  }

  if (options.canonicalizeSlots) {
    canonicalizeSlots(out);
  }

  if (options.preserveNameAndSlot !== false) {
    if (input.name !== undefined) out.name = input.name;
    if (input.slot !== undefined) out.slot = input.slot;
  }

  if (options.includeDebugPath !== false) out.debugPath = input.debugPath || path || "root";

  for (var i2 = 0; i2 < KNOWN_VM_OPERATORS.length; i2++) {
    var key = KNOWN_VM_OPERATORS[i2];
    if ((input as any)[key] !== undefined) (out as any)[key] = clone((input as any)[key]);
  }

  for (var k in input) {
    if (!hasOwn(input, k)) continue;
    if (k === "type" || k === "props" || k === "style" || k === "children" || k === "slots" || k === "debugPath" || k === "name" || k === "slot") continue;
    if ((out as any)[k] !== undefined) continue;
    var v = (input as any)[k];
    if (v === undefined) continue;
    (out as any)[k] = clone(v);
  }

  return out;
}


/* -------------------------------------------------------------------------------------------------
 * Internal helpers
 * ------------------------------------------------------------------------------------------------- */

function createNode(type: string): SduiNode {
  return { type: type, props: {}, children: [] };
}

function mergeStyle(base: string | undefined, next: string): string {
  var a = base ? String(base).trim() : "";
  var b = next ? String(next).trim() : "";
  if (!a) return b;
  if (!b) return a;
  return (a + " " + b).trim();
}

function mergeProps(base: { [key: string]: JsonValue } | undefined, extra: { [key: string]: JsonValue }): { [key: string]: JsonValue } {
  var out: { [key: string]: JsonValue } = {};
  if (base) copyInto(out, base);
  copyInto(out, extra);
  return out;
}

function buildInit(init: Partial<SduiNode> | undefined, patch: Partial<SduiNode>): Partial<SduiNode> {
  var out: any = {};
  if (init) mergeNode(out, init);
  mergeNode(out, patch);
  return out;
}

function copyObject<T extends { [key: string]: any } | undefined>(base: T, extra: { [key: string]: any }): T {
  var out: any = {};
  if (base) copyInto(out, base);
  copyInto(out, extra);
  return out;
}

function copyInto(target: { [key: string]: any }, source: { [key: string]: any }): void {
  for (var k in source) {
    if (!hasOwn(source, k)) continue;
    target[k] = clone(source[k]);
  }
}

function mergeNode(target: any, source: any): void {
  if (!source) return;
  if (source.type !== undefined) target.type = source.type;
  if (source.props !== undefined) target.props = clone(source.props);
  if (source.style !== undefined) target.style = source.style;
  if (source.children !== undefined) target.children = clone(source.children);
  if (source.slots !== undefined) target.slots = clone(source.slots);
  if (source.debugPath !== undefined) target.debugPath = source.debugPath;

  if (source.name !== undefined) target.name = source.name;
  if (source.slot !== undefined) target.slot = source.slot;
  if (source.env !== undefined) target.env = clone(source.env);

  if (source.$define !== undefined) target.$define = clone(source.$define);
  if (source.$let !== undefined) target.$let = clone(source.$let);
  if (source.$call !== undefined) target.$call = source.$call;
  if (source.$classes !== undefined) target.$classes = clone(source.$classes);
  if (source.$scope !== undefined) target.$scope = source.$scope;
  if (source.$switch !== undefined) target.$switch = source.$switch;
  if (source.cases !== undefined) target.cases = clone(source.cases);
  if (source.default !== undefined) target.default = source.default;
  if (source.$if !== undefined) target.$if = source.$if;
  if (source.$repeat !== undefined) target.$repeat = source.$repeat;
  if (source.as !== undefined) target.as = source.as;
  if (source.indexAs !== undefined) target.indexAs = source.indexAs;
  if (source.$apply !== undefined) target.$apply = clone(source.$apply);
  if (source.$layout !== undefined) target.$layout = clone(source.$layout);
  if (source.$try !== undefined) target.$try = source.$try;
  if (source.$catch !== undefined) target.$catch = source.$catch;
  if (source.$finally !== undefined) target.$finally = source.$finally;
  if (source.$async !== undefined) target.$async = source.$async;
  if (source.$loading !== undefined) target.$loading = source.$loading;
  if (source.$data !== undefined) target.$data = source.$data;
  if (source.$error !== undefined) target.$error = source.$error;
  if (source.$portal !== undefined) target.$portal = source.$portal;
  if (source.$reactive_map !== undefined) target.$reactive_map = clone(source.$reactive_map);
  if (source.$compose !== undefined) target.$compose = clone(source.$compose);
  if (source.$watch !== undefined) target.$watch = source.$watch;
  if (source.$parallel !== undefined) target.$parallel = clone(source.$parallel);
  if (source.$throttle !== undefined) target.$throttle = source.$throttle;
  if (source.$debounce !== undefined) target.$debounce = source.$debounce;
  if (source.$machine !== undefined) target.$machine = clone(source.$machine);
  if (source.$stream !== undefined) target.$stream = clone(source.$stream);
  if (source.$spread !== undefined) target.$spread = source.$spread;
  if (source.$view !== undefined) target.$view = source.$view;
  if (source.$slot !== undefined) target.$slot = source.$slot;
  if (source.$slots !== undefined) target.$slots = clone(source.$slots);

  for (var k in source) {
    if (!hasOwn(source, k)) continue;
    if (target[k] === undefined) target[k] = clone(source[k]);
  }
}

function clone<T>(value: T): T {
  if (value === undefined || value === null) return value;
  if (typeof value !== "object") return value;
  if (isArray(value)) {
    var arr: any[] = [];
    for (var i = 0; i < value.length; i++) arr.push(clone(value[i]));
    return arr as any;
  }
  var out: any = {};
  for (var k in value as any) {
    if (!hasOwn(value as any, k)) continue;
    out[k] = clone((value as any)[k]);
  }
  return out;
}

function isPlainObject(value: any): value is { [key: string]: any } {
  return typeof value === "object" && value !== null && !isArray(value) && !(value instanceof SduiElement);
}

function isArray(value: any): value is any[] {
  return Object.prototype.toString.call(value) === "[object Array]";
}

function startsWith(value: string, prefix: string): boolean {
  return String(value).indexOf(prefix) === 0;
}

function hasOwn(obj: any, key: string): boolean {
  return Object.prototype.hasOwnProperty.call(obj, key);
}

function objectSize(obj: { [key: string]: any }): number {
  var n = 0;
  for (var k in obj) if (hasOwn(obj, k)) n++;
  return n;
}

function canonicalizeSlots(node: any): void {
  if (!node.children || node.children.length === 0) return;
  var slots: any = node.slots ? clone(node.slots) : {};
  var nextChildren: any[] = [];
  for (var i = 0; i < node.children.length; i++) {
    var child = normalizeAny(node.children[i]);
    if (child.slot && !slots[child.slot]) {
      slots[child.slot] = child;
      continue;
    }
    if (child.props && typeof child.props.slot === "string" && !slots[child.props.slot]) {
      var slotName = String(child.props.slot);
      var copied = clone(child);
      if (copied.props) delete copied.props.slot;
      slots[slotName] = copied;
      continue;
    }
    nextChildren.push(child);
  }
  node.children = nextChildren;
  if (objectSize(slots) > 0) node.slots = slots;
}

function validateAny(node: any, path: string, issues: ValidationIssue[]): void {
  var n = normalizeAny(node);
  if (!n.type || typeof n.type !== "string") {
    issues.push({ path: path, message: "Missing or invalid type." });
  }
  if (n.props !== undefined && !isPlainObject(n.props)) {
    issues.push({ path: path, message: "props must be an object." });
  }
  if (n.style !== undefined && typeof n.style !== "string") {
    issues.push({ path: path, message: "style must be a string." });
  }
  if (n.$layout !== undefined) {
    if (!isArray(n.$layout)) {
      issues.push({ path: path, message: "$layout must be an array of strings." });
    } else {
      for (var i = 0; i < n.$layout.length; i++) {
        if (typeof n.$layout[i] !== "string") {
          issues.push({ path: path, message: "$layout must contain only strings." });
          break;
        }
      }
    }
  }
  if (n.children !== undefined) {
    if (!isArray(n.children)) {
      issues.push({ path: path, message: "children must be an array." });
    } else {
      for (var j = 0; j < n.children.length; j++) {
        validateAny(n.children[j], path + ".children[" + j + "]", issues);
      }
    }
  }
  if (n.slots !== undefined) {
    if (!isPlainObject(n.slots)) {
      issues.push({ path: path, message: "slots must be an object." });
    } else {
      for (var slotName in n.slots) {
        if (!hasOwn(n.slots, slotName)) continue;
        validateAny(n.slots[slotName], path + ".slots." + slotName, issues);
      }
    }
  }
  var maybeNodeKeys = ["$loading", "$data", "$error", "$try", "$catch", "$finally"];
  for (var k = 0; k < maybeNodeKeys.length; k++) {
    var key = maybeNodeKeys[k];
    var value = n[key];
    if (value !== undefined && value !== null && !isNodeLike(value)) {
      issues.push({ path: path, message: key + " must be a node or null." });
    }
  }
}

function isNodeLike(value: any): boolean {
  return value instanceof SduiElement || isPlainObject(value) || isArray(value) || typeof value === "string" || typeof value === "number" || typeof value === "boolean" || value === null;
}

/* -------------------------------------------------------------------------------------------------
 * Operator inventory
 * ------------------------------------------------------------------------------------------------- */

export var KNOWN_VM_OPERATORS = [
  "$define",
  "$let",
  "$call",
  "$classes",
  "$scope",
  "$switch",
  "$if",
  "$repeat",
  "$apply",
  "$layout",
  "$try",
  "$catch",
  "$finally",
  "$async",
  "$loading",
  "$data",
  "$error",
  "$portal",
  "$reactive_map",
  "$compose",
  "$watch",
  "$parallel",
  "$throttle",
  "$debounce",
  "$machine",
  "$stream",
  "$spread",
  "$view",
  "$slot",
  "$slots",
  "$state",
  "$env",
  "$route",
  "$local"
];

/* -------------------------------------------------------------------------------------------------
 * Example builder
 * ------------------------------------------------------------------------------------------------- */

export function buildExampleApp(): SduiNode {
  return sdui.page([
    sdui.col([
      sdui.row([
        sdui.col([
          sdui.text("Quantum SDUI", { style: "text-2xl font-bold" }),
          sdui.text("Preserve authoring operators for Dart resolution", { style: "text-slate-500" })
        ]),
        sdui.button("Deploy", { props: { intent: "indigo", fill: "solid", shape: "pill" } })
      ], { style: "items-center justify-between gap-16 p-24 rounded-3xl bg-slate-950" }),

      sdui.layout(
        ["hero hero stats", "feed feed stats"],
        {
          hero: sdui.card([
            sdui.text("Hero", { style: "font-semibold" }),
            sdui.if("${state.showHero}", sdui.text("This block is still unresolved here.", { style: "text-slate-600" }))
          ], { style: "p-24 rounded-3xl bg-white shadow" }),

          stats: sdui.card([
            sdui.text("Stats"),
            sdui.text("96%", { style: "text-4xl" })
          ], { style: "p-24 rounded-3xl bg-white shadow" }),

          feed: sdui.card([
            sdui.text("Feed", { style: "font-semibold" }),
            sdui.repeat("${state.items}",
              sdui.row([
                sdui.text("${item.title}"),
                sdui.text("${item.status}", { style: "text-slate-500" })
              ]),
              "item",
              "index"
            )
          ], { style: "p-24 rounded-3xl bg-white shadow" })
        },
        { style: "gap-16" }
      ),

      sdui.tryCatch({
        try: sdui.async({
          action: "load.dashboard",
          params: { range: "${route.range}" },
          loading: { type: "text", props: { text: "Loading..." } },
          data: { type: "text", props: { text: "Loaded" } },
          error: { type: "text", props: { text: "Failed" } }
        }),
        catch: sdui.text("Error boundary")
      })
    ], { style: "gap-16 p-24 bg-slate-100" })
  ]).toNativeObject({ includeDebugPath: true });
}
