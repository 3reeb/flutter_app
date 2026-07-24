interface Bundle {
    omniCores: Record<string, any>;
}
function defineBundle<const B extends Bundle>(b: B): B { return b; }
const myJson = { omniCores: { "box": { fullTypes: ["box", "box:row"] } } } as const;
const myBundle = defineBundle(myJson);
type CoreKeys = keyof typeof myBundle.omniCores;
type FullTypes = typeof myBundle.omniCores[CoreKeys]["fullTypes"][number];
let y: FullTypes = "foo"; // Should fail
