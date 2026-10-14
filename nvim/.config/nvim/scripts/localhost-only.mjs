// Preloaded into `scalar` (NODE_OPTIONS=--import=...). Scalar has no host option and
// listens on every interface; this binds a server that names no host to 127.0.0.1,
// so a spec being previewed is not reachable from the network.
import net from "node:net";

const listen = net.Server.prototype.listen;
net.Server.prototype.listen = function (...args) {
  const [first, second] = args;
  if (typeof first === "number" && (second === undefined || typeof second === "function")) {
    args.splice(1, second === undefined ? 1 : 0, "127.0.0.1");
  } else if (first && typeof first === "object" && first.host === undefined && first.path === undefined) {
    args[0] = { ...first, host: "127.0.0.1" };
  }
  return listen.apply(this, args);
};
